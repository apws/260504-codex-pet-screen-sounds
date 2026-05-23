#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

static NSString * const kDefaultSoundName = @"ringout";
static const CGFloat kDefaultWidthPixels = 16.0;
static const CGFloat kDefaultHeightPixels = 16.0;
static const CGFloat kLeftOffsetPixels = 100.0;
static const CGFloat kBottomOffsetPixels = 116.0;

@interface AppConfig : NSObject
@property(nonatomic, copy) NSString *soundPath;
@property(nonatomic) NSInteger widthPixels;
@property(nonatomic) NSInteger heightPixels;
@property(nonatomic) NSTimeInterval pollSeconds;
@end

@implementation AppConfig
@end

static NSString *ExecutableFolder(void) {
    NSString *path = [[NSBundle mainBundle] executablePath];
    if (path.length > 0) {
        return [path stringByDeletingLastPathComponent];
    }
    NSString *argv0 = [[[NSProcessInfo processInfo] arguments] firstObject];
    return [argv0 stringByDeletingLastPathComponent];
}

static NSString *ResolveAgainstExecutableFolder(NSString *path) {
    if (path.length == 0) return path;
    if (path.isAbsolutePath) return path;
    return [ExecutableFolder() stringByAppendingPathComponent:path];
}

static void PrintUsage(void) {
    fprintf(stderr,
            "CodexPetWatch - bottom-left pet pixel watcher\n\n"
            "Usage:\n"
            "  CodexPetWatch [sound.wav] [width height] [options]\n\n"
            "Options:\n"
            "  --size=WxH       Watch rectangle size in physical pixels. Default: 16x16\n"
            "  --poll-ms=N      Capture interval in milliseconds. Default: 1000\n"
            "  --help           Show this help.\n");
}

static BOOL ParsePositiveInteger(NSString *s, NSInteger *outValue) {
    if (s.length == 0) return NO;
    NSScanner *scanner = [NSScanner scannerWithString:s];
    NSInteger value = 0;
    if (![scanner scanInteger:&value] || !scanner.isAtEnd || value <= 0 || value > 32768) return NO;
    *outValue = value;
    return YES;
}

static BOOL ParseSize(NSString *s, NSInteger *outWidth, NSInteger *outHeight) {
    NSRange range = [s rangeOfString:@"x" options:NSCaseInsensitiveSearch];
    if (range.location == NSNotFound) return NO;
    NSString *wText = [s substringToIndex:range.location];
    NSString *hText = [s substringFromIndex:range.location + range.length];
    NSInteger w = 0;
    NSInteger h = 0;
    if (!ParsePositiveInteger(wText, &w) || !ParsePositiveInteger(hText, &h)) return NO;
    *outWidth = w;
    *outHeight = h;
    return YES;
}

static BOOL ParseConfig(AppConfig *cfg) {
    cfg.soundPath = nil;
    cfg.widthPixels = (NSInteger)kDefaultWidthPixels;
    cfg.heightPixels = (NSInteger)kDefaultHeightPixels;
    cfg.pollSeconds = 1.0;

    NSMutableArray<NSString *> *positionals = [NSMutableArray array];
    NSArray<NSString *> *args = [[NSProcessInfo processInfo] arguments];
    for (NSUInteger i = 1; i < args.count; ++i) {
        NSString *arg = args[i];
        if ([arg isEqualToString:@"--help"] || [arg isEqualToString:@"-h"]) {
            PrintUsage();
            return NO;
        } else if ([arg hasPrefix:@"--size="]) {
            NSInteger w = 0;
            NSInteger h = 0;
            if (!ParseSize([arg substringFromIndex:7], &w, &h)) {
                fprintf(stderr, "Invalid --size value. Use --size=16x16.\n");
                return NO;
            }
            cfg.widthPixels = w;
            cfg.heightPixels = h;
        } else if ([arg hasPrefix:@"--poll-ms="]) {
            NSInteger pollMs = 0;
            if (!ParsePositiveInteger([arg substringFromIndex:10], &pollMs)) {
                fprintf(stderr, "Invalid --poll-ms value.\n");
                return NO;
            }
            cfg.pollSeconds = (NSTimeInterval)pollMs / 1000.0;
        } else if ([arg hasPrefix:@"-"]) {
            fprintf(stderr, "Unknown option: %s\n", arg.UTF8String);
            return NO;
        } else {
            [positionals addObject:arg];
        }
    }

    if (positionals.count >= 3) {
        NSInteger w = 0;
        NSInteger h = 0;
        if (!ParsePositiveInteger(positionals[1], &w) || !ParsePositiveInteger(positionals[2], &h)) {
            fprintf(stderr, "Width/height must be positive integers.\n");
            return NO;
        }
        cfg.soundPath = positionals[0];
        cfg.widthPixels = w;
        cfg.heightPixels = h;
    } else if (positionals.count == 2) {
        fprintf(stderr, "Provide both width and height, or use --size=WxH.\n");
        return NO;
    } else if (positionals.count == 1) {
        cfg.soundPath = positionals[0];
    }

    return YES;
}

@interface OverlayView : NSView
@end

@implementation OverlayView
- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);

    [[NSColor greenColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(self.bounds, 0.5, 0.5)];
    path.lineWidth = 1.0;
    [path stroke];
}
@end

@interface PetWatcher : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) AppConfig *config;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSWindow *overlayWindow;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSData *previousPixels;
@property(nonatomic, strong) NSSound *sound;
@property(nonatomic) CGDirectDisplayID displayID;
@property(nonatomic) CGRect captureRectPixels;
@end

@implementation PetWatcher

- (instancetype)initWithConfig:(AppConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        _displayID = CGMainDisplayID();
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [self setupStatusItem];
    [self computeCaptureRect];
    [self createOverlayWindow];
    [self prepareSound];
    [self captureTick:nil];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.config.pollSeconds
                                                  target:self
                                                selector:@selector(captureTick:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.timer invalidate];
    [self.overlayWindow close];
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [self statusImage];

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"CodexPetWatch"];
    NSMenuItem *exitItem = [[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(exitApp:) keyEquivalent:@"q"];
    exitItem.target = self;
    [menu addItem:exitItem];
    self.statusItem.menu = menu;
}

- (NSImage *)statusImage {
    NSSize size = NSMakeSize(18, 18);
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];

    [[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] setFill];
    NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(2, 2, 14, 14) xRadius:3 yRadius:3];
    [bg fill];

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:12],
        NSForegroundColorAttributeName: [NSColor whiteColor]
    };
    [@"C" drawAtPoint:NSMakePoint(5, 2.5) withAttributes:attrs];

    [[NSColor colorWithCalibratedRed:0 green:0.85 blue:0.25 alpha:1] setFill];
    NSRectFill(NSMakeRect(0, 0, 4, 4));

    [image unlockFocus];
    image.template = NO;
    return image;
}

- (void)exitApp:(id)sender {
    [NSApp terminate:nil];
}

- (void)computeCaptureRect {
    self.displayID = CGMainDisplayID();
    CGRect boundsPoints = CGDisplayBounds(self.displayID);
    CGFloat scaleX = (CGFloat)CGDisplayPixelsWide(self.displayID) / MAX(boundsPoints.size.width, 1.0);
    CGFloat scaleY = (CGFloat)CGDisplayPixelsHigh(self.displayID) / MAX(boundsPoints.size.height, 1.0);
    CGFloat widthPixels = MIN((CGFloat)self.config.widthPixels, boundsPoints.size.width * scaleX);
    CGFloat heightPixels = MIN((CGFloat)self.config.heightPixels, boundsPoints.size.height * scaleY);
    CGFloat maxXOffsetPixels = MAX(0.0, boundsPoints.size.width * scaleX - widthPixels);
    CGFloat maxYOffsetPixels = MAX(0.0, boundsPoints.size.height * scaleY - heightPixels);
    CGFloat leftOffsetPixels = MIN(kLeftOffsetPixels, maxXOffsetPixels);
    CGFloat bottomOffsetPixels = MIN(kBottomOffsetPixels, maxYOffsetPixels);

    self.captureRectPixels = CGRectMake(boundsPoints.origin.x + leftOffsetPixels,
                                        boundsPoints.origin.y + boundsPoints.size.height * scaleY - heightPixels - bottomOffsetPixels,
                                        widthPixels,
                                        heightPixels);
}

- (void)createOverlayWindow {
    NSScreen *screen = NSScreen.mainScreen;
    if (!screen) return;

    CGFloat scale = MAX(screen.backingScaleFactor, 1.0);
    CGFloat widthPoints = (CGFloat)self.config.widthPixels / scale;
    CGFloat heightPoints = (CGFloat)self.config.heightPixels / scale;
    CGFloat leftOffsetPoints = kLeftOffsetPixels / scale;
    CGFloat bottomOffsetPoints = kBottomOffsetPixels / scale;
    NSRect frame = NSMakeRect(NSMinX(screen.frame) + leftOffsetPoints,
                              NSMinY(screen.frame) + bottomOffsetPoints,
                              widthPoints,
                              heightPoints);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:NSWindowStyleMaskBorderless
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.level = NSFloatingWindowLevel;
    window.ignoresMouseEvents = YES;
    window.opaque = NO;
    window.backgroundColor = [NSColor clearColor];
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary;
    window.contentView = [[OverlayView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
    [window orderFrontRegardless];
    self.overlayWindow = window;
}

- (void)prepareSound {
    NSString *path = self.config.soundPath;
    if (!path) {
        path = [[NSBundle mainBundle] pathForResource:kDefaultSoundName ofType:@"wav"];
        if (!path) {
            path = ResolveAgainstExecutableFolder([kDefaultSoundName stringByAppendingPathExtension:@"wav"]);
        }
    } else {
        path = ResolveAgainstExecutableFolder(path);
    }

    if (path) {
        self.sound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
    }
    if (!self.sound) {
        self.sound = [NSSound soundNamed:@"Ping"];
    }
}

- (NSData *)pixelDataForCapture {
    CGImageRef image = CGDisplayCreateImageForRect(self.displayID, self.captureRectPixels);
    if (!image) return nil;

    CGDataProviderRef provider = CGImageGetDataProvider(image);
    CFDataRef dataRef = provider ? CGDataProviderCopyData(provider) : NULL;
    NSData *data = dataRef ? [NSData dataWithData:(__bridge NSData *)dataRef] : nil;
    if (dataRef) CFRelease(dataRef);
    CGImageRelease(image);
    return data;
}

- (void)captureTick:(NSTimer *)timer {
    NSData *current = [self pixelDataForCapture];
    if (!current) return;

    if (!self.previousPixels) {
        self.previousPixels = current;
        return;
    }

    if (![current isEqualToData:self.previousPixels]) {
        self.previousPixels = current;
        [self.sound stop];
        [self.sound play];
    }
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
    AppConfig *config = [[AppConfig alloc] init];
        if (!ParseConfig(config)) {
            return 2;
        }

        NSApplication *app = [NSApplication sharedApplication];
        PetWatcher *delegate = [[PetWatcher alloc] initWithConfig:config];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
