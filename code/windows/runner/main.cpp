#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Milliseconds between this process being created and right now.
//
// The Dart side can only start counting once Dart is running, which leaves out
// everything the person actually waits through first: the shell starting the
// process, Windows mapping the executable and its DLLs, the Flutter engine
// coming up and loading the AOT snapshot. On a launch that felt like two
// seconds, the Dart side accounted for 191 ms of it — so the missing time is
// all in here, and it has to be measured from in here.
//
// Deliberately written with nothing but windows.h and plain arithmetic: this
// file cannot be compiled or tested on the machine it was written on, so it
// avoids every library call it does not strictly need, the integer formatting
// included.
long long MillisecondsSinceProcessStart() {
  FILETIME created, exited, kernel, user;
  if (!::GetProcessTimes(::GetCurrentProcess(), &created, &exited, &kernel,
                         &user)) {
    return -1;
  }
  ULARGE_INTEGER start;
  start.LowPart = created.dwLowDateTime;
  start.HighPart = created.dwHighDateTime;

  FILETIME now_file_time;
  ::GetSystemTimeAsFileTime(&now_file_time);
  ULARGE_INTEGER now;
  now.LowPart = now_file_time.dwLowDateTime;
  now.HighPart = now_file_time.dwHighDateTime;

  if (now.QuadPart < start.QuadPart) {
    return -1;
  }
  // FILETIME counts 100ns intervals.
  return (long long)((now.QuadPart - start.QuadPart) / 10000ULL);
}

// Leaves the elapsed time where Dart can read it.
//
// An environment variable rather than a file or a channel: it costs nothing,
// it is already in place before the engine starts, and Dart reads it through
// Platform.environment without either side needing to know about the other.
void RecordStartupMark(const wchar_t *name) {
  long long value = MillisecondsSinceProcessStart();
  wchar_t buffer[24];
  int end = 0;
  if (value < 0) {
    buffer[end++] = L'-';
    value = 1;
  }
  // Write the digits backwards into the tail, then copy them forwards.
  wchar_t digits[24];
  int count = 0;
  do {
    digits[count++] = (wchar_t)(L'0' + (value % 10));
    value /= 10;
  } while (value > 0 && count < 20);
  while (count > 0) {
    buffer[end++] = digits[--count];
  }
  buffer[end] = L'\0';
  ::SetEnvironmentVariableW(name, buffer);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Before anything else this function does: everything up to here is the
  // operating system loading the executable and its libraries.
  RecordStartupMark(L"MARKTEXT_TRACE_RUNNER_ENTRY");
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  RecordStartupMark(L"MARKTEXT_TRACE_ENGINE_START");

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"MarkText Plus", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Creating the window is what starts the engine and runs the Dart
  // entrypoint, so the gap from the mark above is engine startup and snapshot
  // loading.
  RecordStartupMark(L"MARKTEXT_TRACE_WINDOW_CREATED");

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
