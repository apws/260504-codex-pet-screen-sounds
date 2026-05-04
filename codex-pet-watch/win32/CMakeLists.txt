cmake_minimum_required(VERSION 3.20)
project(codex_pet_watch LANGUAGES CXX)

add_executable(codex_pet_watch WIN32 src/main.cpp)

target_compile_features(codex_pet_watch PRIVATE cxx_std_17)
target_compile_definitions(codex_pet_watch PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX _WIN32_WINNT=0x0A00)

target_link_libraries(codex_pet_watch PRIVATE user32 gdi32 winmm shcore shell32)

add_custom_command(TARGET codex_pet_watch POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${CMAKE_CURRENT_SOURCE_DIR}/../shared/sounds/ringout.wav"
          "$<TARGET_FILE_DIR:codex_pet_watch>/ringout.wav"
  COMMENT "Copying shared ringout.wav next to codex_pet_watch")

if(MSVC)
  target_compile_options(codex_pet_watch PRIVATE /W4 /permissive-)
endif()
