#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>

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
  // Initialised even though every one of them is an out parameter: this
  // project builds the runner with /W4 /WX, where a warning is a failed build,
  // and "potentially uninitialised" is the one warning class this function
  // could plausibly trip.
  FILETIME created = {}, exited = {}, kernel = {}, user = {};
  if (!::GetProcessTimes(::GetCurrentProcess(), &created, &exited, &kernel,
                         &user)) {
    return -1;
  }
  ULARGE_INTEGER start = {};
  start.LowPart = created.dwLowDateTime;
  start.HighPart = created.dwHighDateTime;

  FILETIME now_file_time = {};
  ::GetSystemTimeAsFileTime(&now_file_time);
  ULARGE_INTEGER now = {};
  now.LowPart = now_file_time.dwLowDateTime;
  now.HighPart = now_file_time.dwHighDateTime;

  if (now.QuadPart < start.QuadPart) {
    return -1;
  }
  // FILETIME counts 100ns intervals.
  return (long long)((now.QuadPart - start.QuadPart) / 10000ULL);
}

// Formats an elapsed time as a Dart entrypoint argument.
//
// An argument rather than an environment variable: the first attempt used
// SetEnvironmentVariableW, and Dart's Platform.environment did not see the
// values — the trace came out saying "runner not instrumented" on a build that
// certainly was. Arguments go through set_dart_entrypoint_arguments and arrive
// in main(List<String> args) with nothing in between to lose them.
//
// Written with nothing but plain arithmetic: this file cannot be compiled on
// the machine it was written on, so it avoids every library call it does not
// need, integer formatting included.
std::string FormatTraceArgument(const char *name, long long value) {
  std::string text(name);
  if (value < 0) {
    text += '-';
    value = 1;
  }
  char digits[24];
  int count = 0;
  do {
    digits[count++] = static_cast<char>('0' + (value % 10));
    value /= 10;
  } while (value > 0 && count < 20);
  while (count > 0) {
    text += digits[--count];
  }
  return text;
}

}  // namespace

// Timings the runner can only take after the entrypoint arguments are fixed.
//
// Exported so Dart can read them with FFI: the arguments are handed to the
// engine before the engine starts, so anything measured after that has to
// travel some other way. Slot 0 is taken just before the Flutter view
// controller is built, slot 1 just after — and building it is what boots the
// engine and loads the AOT snapshot.
//
// This is here to answer one question: of the 2.7 seconds that pass between
// the runner starting and the first line of Dart, how much is the engine
// coming up? If it is nearly all of it, making app.so smaller is worth doing;
// if it is not, that work would achieve nothing.
extern "C" __declspec(dllexport) long long mt_trace_engine[2] = {-1, -1};

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Before anything else this function does: everything up to here is the
  // operating system loading the executable and its libraries.
  const long long runner_entry_ms = MillisecondsSinceProcessStart();

  // Ask the engine for the renderer this app used to have.
  //
  // The trace narrowed a two-second launch down to `window.Create()`, which is
  // where the engine comes up, the snapshot is read and the graphics surface is
  // made. Making the snapshot smaller moved the number, but not nearly enough:
  // version 1.2.3 of this same program starts in well under a second on the
  // same machine, and the only structural difference between them is the
  // Flutter engine — 1.2.3 was built in June, before Impeller became the
  // default renderer on Windows.
  //
  // Impeller builds its shader pipelines when it starts. On a machine whose
  // graphics driver cannot supply them from a cache, that is exactly the kind
  // of fixed, unavoidable, every-launch cost being measured here.
  //
  // The engine reads its switches from the environment: FLUTTER_ENGINE_SWITCHES
  // holds the count and FLUTTER_ENGINE_SWITCH_<n> the switches themselves. An
  // engine that no longer understands this one ignores it.
  //
  // Set here rather than left to whoever launches the program, because the
  // point is for it to hold however the program is started.
  //
  // Overridable, so one build can be measured both ways in one sitting:
  // setting MARKTEXT_IMPELLER=1 before launching leaves the new renderer on.
  // Comparing two builds means comparing two binaries; comparing two launches
  // of the same binary compares only the thing under test.
  wchar_t impeller_choice[8] = {0};
  const DWORD impeller_len = ::GetEnvironmentVariableW(
      L"MARKTEXT_IMPELLER", impeller_choice, 8);
  const bool keep_impeller =
      impeller_len > 0 && impeller_len < 8 && impeller_choice[0] == L'1';
  if (!keep_impeller) {
    ::SetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCHES", L"1");
    ::SetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCH_1",
                              L"enable-impeller=false");
  }
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

  command_line_arguments.push_back(
      FormatTraceArgument("--mt-trace-runner-entry=", runner_entry_ms));
  command_line_arguments.push_back(FormatTraceArgument(
      "--mt-trace-engine-start=", MillisecondsSinceProcessStart()));
  // So the trace says which renderer the run was asked for.
  command_line_arguments.push_back(keep_impeller ? "--mt-trace-impeller=1"
                                                 : "--mt-trace-impeller=0");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);

  mt_trace_engine[0] = MillisecondsSinceProcessStart();
  if (!window.Create(L"MarkText Plus", origin, size)) {
    return EXIT_FAILURE;
  }
  mt_trace_engine[1] = MillisecondsSinceProcessStart();
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // Leave immediately rather than returning.
  //
  // Returning from wWinMain hands control to the C runtime, which unwinds and
  // waits on every thread the process still has. Something in that set does not
  // come back: the window disappears and the process stays, sometimes for
  // seconds. The Dart side cannot fix it — a watchdog armed before
  // `destroy()` never got to log a single line, which says the isolate had
  // already stopped while the process was still alive, so whatever is holding
  // on is native and out of Dart's reach.
  //
  // Everything that had to reach disk — the document, the window geometry, the
  // settings — was written and flushed before the window was destroyed, so
  // there is nothing left to lose by not waiting.
  //
  // Before CoUninitialize, not after. Uninitialising COM on an apartment
  // thread waits for the objects that apartment still has outstanding, and
  // that wait is itself a place the process can sit for seconds. Nothing here
  // needs COM to be shut down tidily on the way out of a process that is
  // about to stop existing.
  ::ExitProcess(EXIT_SUCCESS);
}
