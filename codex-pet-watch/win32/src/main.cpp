#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0A00
#endif

#include <windows.h>
#include <shellapi.h>
#include <shellscalingapi.h>
#include <mmsystem.h>
#include <cstdio>
#include <cwchar>
#include <cwctype>
#include <cstdint>
#include <cstring>
#include <vector>
#include <string>
#include <algorithm>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "shcore.lib")
#pragma comment(lib, "shell32.lib")

namespace {

constexpr wchar_t kWindowClassName[] = L"CodexPetAreaOverlayWindow";
constexpr wchar_t kDefaultSoundFolder[] = L"C:\\Windows\\Media";
constexpr wchar_t kDefaultSoundFile[] = L"ringout.wav";
constexpr UINT_PTR kCaptureTimerId = 1;
constexpr UINT kTrayIconMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kTrayExitCommand = 1001;
constexpr int kDefaultWidthDip = 48;
constexpr int kDefaultHeightDip = 48;
constexpr int kLeftOffsetPx = 32;
constexpr int kBottomOffsetPx = 48;

struct Config {
    std::wstring soundPath;
    int widthDip = kDefaultWidthDip;
    int heightDip = kDefaultHeightDip;
    UINT pollMs = 1000;
    bool useWorkArea = false;
    bool followForegroundMonitor = false;
    bool useCursorMonitor = false;
    bool usePrimaryMonitor = false;
};

struct MonitorSnapshot {
    HMONITOR handle = nullptr;
    RECT rcMonitorPx{};
    RECT rcWorkPx{};
    UINT dpiX = 96;
    UINT dpiY = 96;
};

struct AppState {
    Config cfg;
    HWND hwnd = nullptr;
    RECT captureRectPx{};
    MonitorSnapshot monitor{};
    std::vector<std::uint8_t> previousPixels;
    bool haveBaseline = false;
    unsigned long long changeCount = 0;
    HICON trayIcon = nullptr;
    bool trayIconAdded = false;
};

AppState g_app;

std::wstring ToLower(std::wstring s) {
    std::transform(s.begin(), s.end(), s.begin(), [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
    return s;
}

bool StartsWith(const std::wstring& s, const wchar_t* prefix) {
    const size_t n = std::wcslen(prefix);
    return s.size() >= n && s.compare(0, n, prefix) == 0;
}

bool IsAbsoluteOrRootedPath(const std::wstring& p) {
    if (p.size() >= 3 && std::iswalpha(p[0]) && p[1] == L':' && (p[2] == L'\\' || p[2] == L'/')) return true;
    if (p.size() >= 2 && p[0] == L'\\' && p[1] == L'\\') return true; // UNC
    return false;
}

std::wstring ResolveAgainstDefaultSoundFolder(const std::wstring& maybeRelative) {
    if (IsAbsoluteOrRootedPath(maybeRelative)) return maybeRelative;
    std::wstring base = kDefaultSoundFolder;
    if (!base.empty() && base.back() != L'\\' && base.back() != L'/') base += L'\\';
    return base + maybeRelative;
}

void PrintUsage() {
    std::fwprintf(stderr,
        L"codex_pet_watch - bottom-left screen rectangle watcher\n\n"
        L"Usage:\n"
        L"  codex_pet_watch.exe [sound.wav] [widthDip heightDip] [options]\n\n"
        L"Options:\n"
        L"  --size=WxH              Rectangle size in logical DIP units. Default: 48x48\n"
        L"  --poll-ms=N             Capture interval in milliseconds. Default: 1000\n"
        L"  --work-area             Anchor to monitor work area instead of full monitor.\n"
        L"  --follow-foreground     Re-anchor if the foreground-window monitor changes.\n"
        L"  --cursor-monitor        Use monitor containing the cursor at launch.\n"
        L"  --primary-monitor       Use primary monitor at launch.\n"
        L"  --help                  Show this help.\n\n"
        L"Notes:\n"
        L"  If no sound file is specified, ringout.wav is used.\n"
        L"  Relative sound paths are loaded from C:\\Windows\\Media. PlaySound is WAV-oriented.\n"
        L"  Coordinates/capture use physical pixels internally; size args are logical DIP.\n");
}

bool TryParseInt(const std::wstring& s, int& out) {
    if (s.empty()) return false;
    wchar_t* end = nullptr;
    long v = std::wcstol(s.c_str(), &end, 10);
    if (end == s.c_str() || *end != L'\0') return false;
    if (v <= 0 || v > 32768) return false;
    out = static_cast<int>(v);
    return true;
}

bool ParseSizeValue(const std::wstring& value, int& w, int& h) {
    size_t x = value.find_first_of(L"xX");
    if (x == std::wstring::npos) return false;
    int ww = 0, hh = 0;
    if (!TryParseInt(value.substr(0, x), ww)) return false;
    if (!TryParseInt(value.substr(x + 1), hh)) return false;
    w = ww;
    h = hh;
    return true;
}

bool ParseArgs(int argc, wchar_t** argv, Config& cfg) {
    std::vector<std::wstring> positionals;
    for (int i = 1; i < argc; ++i) {
        std::wstring a = argv[i];
        if (a == L"--help" || a == L"-h" || a == L"/?") {
            PrintUsage();
            return false;
        } else if (StartsWith(a, L"--size=")) {
            if (!ParseSizeValue(a.substr(7), cfg.widthDip, cfg.heightDip)) {
                std::fwprintf(stderr, L"Invalid --size value. Use --size=48x48.\n");
                return false;
            }
        } else if (StartsWith(a, L"--poll-ms=")) {
            int parsed = 0;
            if (!TryParseInt(a.substr(10), parsed)) {
                std::fwprintf(stderr, L"Invalid --poll-ms value.\n");
                return false;
            }
            cfg.pollMs = static_cast<UINT>(parsed);
        } else if (a == L"--work-area") {
            cfg.useWorkArea = true;
        } else if (a == L"--follow-foreground") {
            cfg.followForegroundMonitor = true;
        } else if (a == L"--cursor-monitor") {
            cfg.useCursorMonitor = true;
        } else if (a == L"--primary-monitor") {
            cfg.usePrimaryMonitor = true;
        } else if (!a.empty() && a[0] == L'-') {
            std::fwprintf(stderr, L"Unknown option: %ls\n", a.c_str());
            return false;
        } else {
            positionals.push_back(a);
        }
    }

    cfg.soundPath = ResolveAgainstDefaultSoundFolder(positionals.empty() ? kDefaultSoundFile : positionals[0]);

    if (positionals.size() >= 3) {
        if (!TryParseInt(positionals[1], cfg.widthDip) || !TryParseInt(positionals[2], cfg.heightDip)) {
            std::fwprintf(stderr, L"Width/height must be positive integers.\n");
            return false;
        }
    } else if (positionals.size() == 2) {
        std::fwprintf(stderr, L"Provide both widthDip and heightDip, or use --size=WxH.\n");
        return false;
    }

    if (cfg.usePrimaryMonitor && cfg.useCursorMonitor) {
        std::fwprintf(stderr, L"Choose only one of --primary-monitor or --cursor-monitor.\n");
        return false;
    }

    return true;
}

void EnableBestEffortDpiAwareness() {
    // Prefer Per-Monitor v2 on Windows 10/11. Fall back gracefully for older SDK/runtime combos.
    HMODULE user32 = LoadLibraryW(L"user32.dll");
    if (user32) {
        using SetProcessDpiAwarenessContextFn = BOOL(WINAPI*)(DPI_AWARENESS_CONTEXT);
        auto fn = reinterpret_cast<SetProcessDpiAwarenessContextFn>(GetProcAddress(user32, "SetProcessDpiAwarenessContext"));
        if (fn && fn(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
            FreeLibrary(user32);
            return;
        }
        FreeLibrary(user32);
    }

    HMODULE shcore = LoadLibraryW(L"shcore.dll");
    if (shcore) {
        using SetProcessDpiAwarenessFn = HRESULT(WINAPI*)(PROCESS_DPI_AWARENESS);
        auto fn = reinterpret_cast<SetProcessDpiAwarenessFn>(GetProcAddress(shcore, "SetProcessDpiAwareness"));
        if (fn && SUCCEEDED(fn(PROCESS_PER_MONITOR_DPI_AWARE))) {
            FreeLibrary(shcore);
            return;
        }
        FreeLibrary(shcore);
    }

    SetProcessDPIAware();
}

void FillDpiForMonitor(HMONITOR hmon, UINT& dpiX, UINT& dpiY) {
    dpiX = dpiY = 96;

    HMODULE shcore = LoadLibraryW(L"shcore.dll");
    if (shcore) {
        using GetDpiForMonitorFn = HRESULT(WINAPI*)(HMONITOR, MONITOR_DPI_TYPE, UINT*, UINT*);
        auto fn = reinterpret_cast<GetDpiForMonitorFn>(GetProcAddress(shcore, "GetDpiForMonitor"));
        if (fn && SUCCEEDED(fn(hmon, MDT_EFFECTIVE_DPI, &dpiX, &dpiY))) {
            FreeLibrary(shcore);
            return;
        }
        FreeLibrary(shcore);
    }

    HDC screen = GetDC(nullptr);
    if (screen) {
        dpiX = static_cast<UINT>(GetDeviceCaps(screen, LOGPIXELSX));
        dpiY = static_cast<UINT>(GetDeviceCaps(screen, LOGPIXELSY));
        ReleaseDC(nullptr, screen);
    }
}

HMONITOR SelectMonitor(const Config& cfg) {
    if (cfg.usePrimaryMonitor) {
        POINT pt{0, 0};
        return MonitorFromPoint(pt, MONITOR_DEFAULTTOPRIMARY);
    }

    if (cfg.useCursorMonitor) {
        POINT pt{};
        if (GetCursorPos(&pt)) return MonitorFromPoint(pt, MONITOR_DEFAULTTOPRIMARY);
    }

    HWND fg = GetForegroundWindow();
    if (fg) return MonitorFromWindow(fg, MONITOR_DEFAULTTOPRIMARY);

    POINT pt{};
    if (GetCursorPos(&pt)) return MonitorFromPoint(pt, MONITOR_DEFAULTTOPRIMARY);

    return MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
}

bool ReadMonitorSnapshot(const Config& cfg, MonitorSnapshot& snap) {
    HMONITOR hmon = SelectMonitor(cfg);
    if (!hmon) return false;

    MONITORINFO mi{};
    mi.cbSize = sizeof(mi);
    if (!GetMonitorInfoW(hmon, &mi)) return false;

    snap.handle = hmon;
    snap.rcMonitorPx = mi.rcMonitor;
    snap.rcWorkPx = mi.rcWork;
    FillDpiForMonitor(hmon, snap.dpiX, snap.dpiY);
    return true;
}

int DipToPxX(int dip, UINT dpiX) {
    return std::max(1, MulDiv(dip, static_cast<int>(dpiX), 96));
}

int DipToPxY(int dip, UINT dpiY) {
    return std::max(1, MulDiv(dip, static_cast<int>(dpiY), 96));
}

RECT ComputeBottomLeftRectPx(const Config& cfg, const MonitorSnapshot& snap) {
    RECT anchor = cfg.useWorkArea ? snap.rcWorkPx : snap.rcMonitorPx;
    int wantedW = DipToPxX(cfg.widthDip, snap.dpiX);
    int wantedH = DipToPxY(cfg.heightDip, snap.dpiY);

    int maxW = std::max(1, static_cast<int>(anchor.right - anchor.left));
    int maxH = std::max(1, static_cast<int>(anchor.bottom - anchor.top));
    int w = std::min(wantedW, maxW);
    int h = std::min(wantedH, maxH);

    RECT r{};
    int leftOffset = std::min(kLeftOffsetPx, std::max(0, maxW - w));
    r.left = anchor.left + leftOffset;
    r.right = r.left + w;
    int bottomOffset = std::min(kBottomOffsetPx, std::max(0, maxH - h));
    r.bottom = anchor.bottom - bottomOffset;
    r.top = r.bottom - h;
    return r;
}

int RectWidth(const RECT& r) { return r.right - r.left; }
int RectHeight(const RECT& r) { return r.bottom - r.top; }

void PrintMonitorAndRect(const MonitorSnapshot& snap, const RECT& r, const Config& cfg) {
    const int monW = RectWidth(snap.rcMonitorPx);
    const int monH = RectHeight(snap.rcMonitorPx);
    const int logicalW = MulDiv(monW, 96, static_cast<int>(snap.dpiX));
    const int logicalH = MulDiv(monH, 96, static_cast<int>(snap.dpiY));

    std::fwprintf(stdout,
        L"Monitor px:     left=%ld top=%ld right=%ld bottom=%ld size=%dx%d\n"
        L"Monitor logical: size=%dx%d DIP at dpi=%ux%u\n"
        L"Anchor area:    %ls\n"
        L"Pet rect px:    left=%ld top=%ld width=%d height=%d\n"
        L"Pet rect DIP:   width=%d height=%d\n"
        L"Poll:           %u ms\n"
        L"Sound:          %ls\n\n",
        snap.rcMonitorPx.left, snap.rcMonitorPx.top, snap.rcMonitorPx.right, snap.rcMonitorPx.bottom, monW, monH,
        logicalW, logicalH, snap.dpiX, snap.dpiY,
        cfg.useWorkArea ? L"work area" : L"full monitor",
        r.left, r.top, RectWidth(r), RectHeight(r),
        cfg.widthDip, cfg.heightDip,
        cfg.pollMs,
        cfg.soundPath.c_str());
    std::fflush(stdout);
}

bool CaptureRectPixelsBgra(const RECT& r, std::vector<std::uint8_t>& pixels) {
    const int w = RectWidth(r);
    const int h = RectHeight(r);
    if (w <= 0 || h <= 0) return false;

    HDC screenDc = GetDC(nullptr);
    if (!screenDc) return false;

    HDC memDc = CreateCompatibleDC(screenDc);
    if (!memDc) {
        ReleaseDC(nullptr, screenDc);
        return false;
    }

    BITMAPINFO bmi{};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = w;
    bmi.bmiHeader.biHeight = -h; // top-down DIB
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    HBITMAP dib = CreateDIBSection(screenDc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
    if (!dib || !bits) {
        if (dib) DeleteObject(dib);
        DeleteDC(memDc);
        ReleaseDC(nullptr, screenDc);
        return false;
    }

    HGDIOBJ oldBitmap = SelectObject(memDc, dib);
    BOOL ok = BitBlt(memDc, 0, 0, w, h, screenDc, r.left, r.top, SRCCOPY | CAPTUREBLT);

    if (ok) {
        pixels.resize(static_cast<size_t>(w) * static_cast<size_t>(h) * 4u);
        std::memcpy(pixels.data(), bits, pixels.size());
    }

    SelectObject(memDc, oldBitmap);
    DeleteObject(dib);
    DeleteDC(memDc);
    ReleaseDC(nullptr, screenDc);
    return ok == TRUE;
}

void PlayConfiguredSound() {
    if (!PlaySoundW(g_app.cfg.soundPath.c_str(), nullptr, SND_FILENAME | SND_ASYNC | SND_NODEFAULT)) {
        std::fwprintf(stderr, L"PlaySound failed for: %ls\n", g_app.cfg.soundPath.c_str());
        std::fflush(stderr);
    }
}

HICON CreateTrayStatusIcon() {
    constexpr int iconSize = 32;
    constexpr int statusSize = 7;
    auto fallbackIcon = []() -> HICON {
        HICON shared = LoadIconW(nullptr, IDI_APPLICATION);
        return shared ? CopyIcon(shared) : nullptr;
    };

    HDC screenDc = GetDC(nullptr);
    if (!screenDc) return fallbackIcon();

    HDC memDc = CreateCompatibleDC(screenDc);
    if (!memDc) {
        ReleaseDC(nullptr, screenDc);
        return fallbackIcon();
    }

    BITMAPINFO bmi{};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = iconSize;
    bmi.bmiHeader.biHeight = -iconSize;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    HBITMAP colorBitmap = CreateDIBSection(screenDc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
    if (!colorBitmap || !bits) {
        if (colorBitmap) DeleteObject(colorBitmap);
        DeleteDC(memDc);
        ReleaseDC(nullptr, screenDc);
        return fallbackIcon();
    }

    HGDIOBJ oldBitmap = SelectObject(memDc, colorBitmap);

    HBRUSH bgBrush = CreateSolidBrush(RGB(28, 34, 42));
    RECT fullRect{0, 0, iconSize, iconSize};
    FillRect(memDc, &fullRect, bgBrush);
    DeleteObject(bgBrush);

    HPEN borderPen = CreatePen(PS_SOLID, 1, RGB(180, 190, 205));
    HGDIOBJ oldPen = SelectObject(memDc, borderPen);
    HGDIOBJ oldBrush = SelectObject(memDc, GetStockObject(NULL_BRUSH));
    RoundRect(memDc, 2, 2, iconSize - 2, iconSize - 2, 7, 7);

    HFONT font = CreateFontW(21, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                             OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                             DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    HGDIOBJ oldFont = SelectObject(memDc, font);
    SetBkMode(memDc, TRANSPARENT);
    SetTextColor(memDc, RGB(235, 240, 248));
    RECT textRect{6, 2, iconSize, iconSize - 2};
    DrawTextW(memDc, L"C", 1, &textRect, DT_SINGLELINE | DT_VCENTER | DT_LEFT);
    SelectObject(memDc, oldFont);
    DeleteObject(font);

    HBRUSH statusBrush = CreateSolidBrush(RGB(0, 220, 70));
    RECT statusRect{0, iconSize - statusSize, statusSize, iconSize};
    FillRect(memDc, &statusRect, statusBrush);
    DeleteObject(statusBrush);

    SelectObject(memDc, oldBrush);
    SelectObject(memDc, oldPen);
    DeleteObject(borderPen);
    SelectObject(memDc, oldBitmap);

    HBITMAP maskBitmap = CreateBitmap(iconSize, iconSize, 1, 1, nullptr);
    ICONINFO iconInfo{};
    iconInfo.fIcon = TRUE;
    iconInfo.hbmColor = colorBitmap;
    iconInfo.hbmMask = maskBitmap;
    HICON icon = CreateIconIndirect(&iconInfo);

    DeleteObject(maskBitmap);
    DeleteObject(colorBitmap);
    DeleteDC(memDc);
    ReleaseDC(nullptr, screenDc);
    return icon ? icon : fallbackIcon();
}

void RemoveTrayIcon() {
    if (g_app.trayIconAdded) {
        NOTIFYICONDATAW nid{};
        nid.cbSize = sizeof(nid);
        nid.hWnd = g_app.hwnd;
        nid.uID = kTrayIconId;
        Shell_NotifyIconW(NIM_DELETE, &nid);
        g_app.trayIconAdded = false;
    }
    if (g_app.trayIcon) {
        DestroyIcon(g_app.trayIcon);
        g_app.trayIcon = nullptr;
    }
}

bool AddTrayIcon(HWND hwnd) {
    g_app.trayIcon = CreateTrayStatusIcon();

    NOTIFYICONDATAW nid{};
    nid.cbSize = sizeof(nid);
    nid.hWnd = hwnd;
    nid.uID = kTrayIconId;
    nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    nid.uCallbackMessage = kTrayIconMessage;
    nid.hIcon = g_app.trayIcon;
    wcscpy_s(nid.szTip, L"codex_pet_watch");

    g_app.trayIconAdded = Shell_NotifyIconW(NIM_ADD, &nid) == TRUE;
    if (g_app.trayIconAdded) {
        nid.uVersion = NOTIFYICON_VERSION_4;
        Shell_NotifyIconW(NIM_SETVERSION, &nid);
    }
    return g_app.trayIconAdded;
}

void ShowTrayMenu(HWND hwnd) {
    POINT pt{};
    GetCursorPos(&pt);

    HMENU menu = CreatePopupMenu();
    if (!menu) return;

    AppendMenuW(menu, MF_STRING, kTrayExitCommand, L"Exit");
    SetForegroundWindow(hwnd);
    TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN | TPM_LEFTALIGN, pt.x, pt.y, 0, hwnd, nullptr);
    DestroyMenu(menu);
}

void EnsureOverlayPosition() {
    MonitorSnapshot next{};
    if (!ReadMonitorSnapshot(g_app.cfg, next)) return;
    RECT nextRect = ComputeBottomLeftRectPx(g_app.cfg, next);

    bool monitorChanged = next.handle != g_app.monitor.handle;
    bool rectChanged = !EqualRect(&nextRect, &g_app.captureRectPx);
    if (monitorChanged || rectChanged) {
        g_app.monitor = next;
        g_app.captureRectPx = nextRect;
        g_app.haveBaseline = false;
        g_app.previousPixels.clear();
        SetWindowPos(g_app.hwnd, HWND_TOPMOST, nextRect.left, nextRect.top,
                     RectWidth(nextRect), RectHeight(nextRect), SWP_NOACTIVATE | SWP_SHOWWINDOW);
        InvalidateRect(g_app.hwnd, nullptr, TRUE);
        PrintMonitorAndRect(g_app.monitor, g_app.captureRectPx, g_app.cfg);
    }
}

void CaptureTick() {
    if (g_app.cfg.followForegroundMonitor) {
        EnsureOverlayPosition();
    }

    std::vector<std::uint8_t> current;
    if (!CaptureRectPixelsBgra(g_app.captureRectPx, current)) {
        std::fwprintf(stderr, L"Capture failed.\n");
        std::fflush(stderr);
        return;
    }

    if (!g_app.haveBaseline) {
        g_app.previousPixels = std::move(current);
        g_app.haveBaseline = true;
        std::fwprintf(stdout, L"Baseline captured. Watching for bitmap changes...\n");
        std::fflush(stdout);
        return;
    }

    if (current.size() != g_app.previousPixels.size() ||
        std::memcmp(current.data(), g_app.previousPixels.data(), current.size()) != 0) {
        g_app.previousPixels = std::move(current);
        ++g_app.changeCount;
        SYSTEMTIME st{};
        GetLocalTime(&st);
        std::fwprintf(stdout, L"[%02u:%02u:%02u] bitmap change #%llu -> playing sound\n",
                      st.wHour, st.wMinute, st.wSecond, g_app.changeCount);
        std::fflush(stdout);
        PlayConfiguredSound();
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case kTrayIconMessage:
        if (LOWORD(lParam) == WM_CONTEXTMENU || LOWORD(lParam) == WM_RBUTTONUP) {
            ShowTrayMenu(hwnd);
            return 0;
        }
        break;
    case WM_COMMAND:
        if (LOWORD(wParam) == kTrayExitCommand) {
            DestroyWindow(hwnd);
            return 0;
        }
        break;
    case WM_NCHITTEST:
        return HTTRANSPARENT;
    case WM_PAINT: {
        PAINTSTRUCT ps{};
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc{};
        GetClientRect(hwnd, &rc);

        HBRUSH transparentKeyBrush = CreateSolidBrush(RGB(0, 0, 0));
        FillRect(hdc, &rc, transparentKeyBrush);
        DeleteObject(transparentKeyBrush);

        HBRUSH greenBrush = CreateSolidBrush(RGB(0, 255, 0));
        FrameRect(hdc, &rc, greenBrush);
        DeleteObject(greenBrush);

        EndPaint(hwnd, &ps);
        return 0;
    }
    case WM_TIMER:
        if (wParam == kCaptureTimerId) {
            CaptureTick();
            return 0;
        }
        break;
    case WM_DESTROY:
        KillTimer(hwnd, kCaptureTimerId);
        RemoveTrayIcon();
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

HWND CreateOverlayWindow(HINSTANCE hInstance, const RECT& r) {
    WNDCLASSEXW wc{};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    wc.lpszClassName = kWindowClassName;
    wc.hbrBackground = nullptr;
    if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
        return nullptr;
    }

    HWND hwnd = CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
        kWindowClassName,
        L"codex-pet-area",
        WS_POPUP,
        r.left,
        r.top,
        RectWidth(r),
        RectHeight(r),
        nullptr,
        nullptr,
        hInstance,
        nullptr);

    if (!hwnd) return nullptr;

    SetLayeredWindowAttributes(hwnd, RGB(0, 0, 0), 0, LWA_COLORKEY);
    SetWindowPos(hwnd, HWND_TOPMOST, r.left, r.top, RectWidth(r), RectHeight(r),
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
    UpdateWindow(hwnd);
    return hwnd;
}

} // namespace

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    EnableBestEffortDpiAwareness();

    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argv) {
        MessageBoxW(nullptr, L"Could not parse command line.", L"codex_pet_watch", MB_OK | MB_ICONERROR);
        return 1;
    }

    Config cfg{};
    if (!ParseArgs(argc, argv, cfg)) {
        LocalFree(argv);
        return 2;
    }
    LocalFree(argv);

    DWORD soundAttrs = GetFileAttributesW(cfg.soundPath.c_str());
    if (soundAttrs == INVALID_FILE_ATTRIBUTES || (soundAttrs & FILE_ATTRIBUTE_DIRECTORY)) {
        std::fwprintf(stderr, L"Warning: sound file was not found: %ls\n", cfg.soundPath.c_str());
        std::fwprintf(stderr, L"The watcher will still run, but PlaySound will fail until the path exists.\n\n");
    }

    g_app.cfg = cfg;
    if (!ReadMonitorSnapshot(g_app.cfg, g_app.monitor)) {
        std::fwprintf(stderr, L"Could not read monitor information.\n");
        return 3;
    }
    g_app.captureRectPx = ComputeBottomLeftRectPx(g_app.cfg, g_app.monitor);
    PrintMonitorAndRect(g_app.monitor, g_app.captureRectPx, g_app.cfg);

    g_app.hwnd = CreateOverlayWindow(hInstance, g_app.captureRectPx);
    if (!g_app.hwnd) {
        std::fwprintf(stderr, L"Could not create overlay window. LastError=%lu\n", GetLastError());
        return 4;
    }
    AddTrayIcon(g_app.hwnd);

    // Establish initial baseline shortly after the overlay has been rendered.
    Sleep(100);
    CaptureTick();
    SetTimer(g_app.hwnd, kCaptureTimerId, g_app.cfg.pollMs, nullptr);

    MSG msg{};
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return static_cast<int>(msg.wParam);
}
