#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {


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


// The arguments as the JSON array the running instance expects, or an empty
// string when this cannot be sure of the encoding.
//
// Hand-written rather than pulled in from a library, for the reason at the top
// of this file: nothing here can be compiled or tested on the machine it is
// written on, so it uses as little as it can get away with — and it gives up
// rather than guess. A backslash and a quote are all a path normally needs
// escaping, and those two are done here; anything JSON would want escaped
// beyond them makes this return nothing, and the launch takes the slow path
// where Dart's own encoder does the work.
//
// That is the whole of the safety argument. The far end parses what it is sent
// and swallows the error if it cannot, so a payload this got wrong would mean
// a document that silently never opens. A launch that is merely as slow as it
// used to be is a much better failure than that.
std::string JsonArrayOf(const std::vector<std::string>& arguments) {
  std::string json = "[";
  for (size_t i = 0; i < arguments.size(); i++) {
    if (i > 0) {
      json += ",";
    }
    json += "\"";
    for (size_t c = 0; c < arguments[i].size(); c++) {
      const unsigned char ch = static_cast<unsigned char>(arguments[i][c]);
      if (ch == '\\') {
        json += "\\\\";
      } else if (ch == '"') {
        json += "\\\"";
      } else if (ch < 0x20) {
        return std::string();
      } else {
        // Everything else, bytes above 0x7F included: the arguments are
        // already UTF-8 and JSON carries UTF-8 as it stands, so a Chinese
        // file name needs nothing done to it.
        json += static_cast<char>(ch);
      }
    }
    json += "\"";
  }
  json += "]";
  return json;
}

// Leaves the two numbers nobody had behind for the next launch to report.
//
// Dart times the close from the moment it is told about it, and every recorded
// close runs 17-35 ms from there to the window going — while a reader reports
// waiting seconds. So the wait is outside that: either before the message
// reaches Dart, or after the window has gone and the process has not. This
// records both ends of the whole thing, from the click to the last instruction
// this process runs.
//
// Beside the executable, which is where the startup trace already keeps one of
// its two copies, so it is known to be writable. One line, overwritten each
// time; the next launch reads it, says so, and deletes it.
void WriteLastExit(long long queued_ms, long long close_asked_ms,
                   long long gone_ms, long long exiting_ms) {
  wchar_t path[MAX_PATH] = {};
  const DWORD length = ::GetModuleFileNameW(nullptr, path, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) {
    return;
  }
  // Cut the file name off, leaving the trailing separator.
  DWORD end = length;
  while (end > 0 && path[end - 1] != L'\\') {
    end--;
  }
  if (end == 0) {
    return;
  }
  path[end] = L'\0';

  std::wstring file(path);
  file += L"last-exit.log";
  HANDLE handle = ::CreateFileW(file.c_str(), GENERIC_WRITE, 0, nullptr,
                                CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (handle == INVALID_HANDLE_VALUE) {
    return;
  }
  std::string line = FormatTraceArgument("queued-ms=", queued_ms);
  line += FormatTraceArgument(" close-asked-ms=", close_asked_ms);
  line += FormatTraceArgument(" gone-ms=", gone_ms);
  line += FormatTraceArgument(" exiting-ms=", exiting_ms);
  line += "\n";
  DWORD written = 0;
  ::WriteFile(handle, line.c_str(), static_cast<DWORD>(line.size()), &written,
              nullptr);
  ::CloseHandle(handle);
}

// Gives [arguments] to the copy of the editor already running, if there is one.
//
// A second launch — double-clicking a document while the editor is open — is
// routed to the running window by `windows_single_instance`. That check is in
// Dart, and Dart does not run until the engine has: measured on a reader's
// machine, 462 ms for Windows to map the executable and its libraries and
// another ~600 ms for the engine and the AOT snapshot. So opening a document
// that way cost a second or more of a whole second copy of the editor starting
// up, in order to forward one path and quit. That is what a reader means by
// "opening the second file is slow", and none of it is rendering.
//
// The protocol is the package's own: a named mutex says somebody is there, and
// the arguments go down a named pipe as a JSON array. Nothing here *creates*
// the mutex — creating it would make the Dart check later in this same process
// believe it was the second instance and quit the only copy running.
//
// Every failure falls through to starting normally, which is what happened
// before this existed: the editor still opens, and the Dart check still
// forwards the arguments the way it always did. This can only make a launch
// faster, never break one.
bool HandedOffToRunningInstance(const std::vector<std::string>& arguments) {
  HANDLE running = ::OpenMutexW(SYNCHRONIZE, FALSE,
                                L"marktext_plus_instance.win.mutex");
  if (running == nullptr) {
    return false;
  }
  ::CloseHandle(running);

  HANDLE pipe = ::CreateFileW(L"\\\\.\\pipe\\marktext_plus_instance",
                              GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0,
                              nullptr);
  if (pipe == INVALID_HANDLE_VALUE) {
    // A window is there but its pipe is not listening yet — it is still
    // starting up, and its own check has not run either. Starting normally is
    // the right answer: one of the two will win the mutex and the other will
    // forward from Dart.
    return false;
  }

  const std::string json = JsonArrayOf(arguments);
  if (json.empty()) {
    ::CloseHandle(pipe);
    return false;
  }
  DWORD written = 0;
  const BOOL wrote = ::WriteFile(pipe, json.c_str(),
                                 static_cast<DWORD>(json.size()), &written,
                                 nullptr);
  ::CloseHandle(pipe);
  return wrote != FALSE && written == json.size();
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

  // Before the console, before COM, before the engine: if the editor is
  // already running, this launch has nothing to do but hand over what it was
  // given. See [HandedOffToRunningInstance] for what that was costing.
  if (HandedOffToRunningInstance(GetCommandLineArguments())) {
    // Deliberately not recording an exit here. This process never had a window
    // and was never asked to close one; writing the file from here would put a
    // launch that merely forwarded a path where the next launch looks for the
    // close it is meant to report, and overwrite the real one.
    //
    // Ended the same way as the run below, for the same reason: the path has
    // been written and closed, nothing else here has anything to flush, and
    // the detach handlers of everything the loader already mapped are work on
    // behalf of a process with no future.
    ::TerminateProcess(::GetCurrentProcess(), EXIT_SUCCESS);
  }

  // Renderer choice. Read MARKTEXT_IMPELLER here; applied to the project
  // below, because only the project can carry it.
  //
  // The first attempt at this set FLUTTER_ENGINE_SWITCHES and
  // FLUTTER_ENGINE_SWITCH_1=enable-impeller=false. That does nothing in a
  // release build: GetSwitchesFromEnvironment in the engine is wrapped in
  // `#ifndef FLUTTER_RELEASE` and returns an empty list, so every shipped
  // build ran Impeller no matter what the variable said — and the trace line
  // reported the request rather than the result, which made an A/B of two
  // identical runs look like an answer. set_impeller_switch is the supported
  // way and is read directly by FlutterWindowsEngine.
  //
  // Off by default on Windows, because Impeller is what the launch cost is:
  // 3.44.9, which has no Impeller on Windows at all, creates the view in 284
  // and 306 ms; 3.47.2 with Impeller takes 2130 to 3330 ms on the same
  // machine and the same source. flutter/flutter#191860 measures the same
  // thing on a minimal project — 54 ms on Skia against 1183 ms on Impeller.
  //
  // The default is baked in at build time rather than read from the machine
  // that runs the program: a variable left over from an earlier experiment
  // has already made one set of measurements say the opposite of what was
  // intended. Nothing defines MARKTEXT_IMPELLER_DEFAULT now, so shipped
  // builds take the 0 below; CMake picks it up from the environment when two
  // installers need comparing again.
  // MARKTEXT_IMPELLER=1/0 still overrides it for a single launch.
#ifndef MARKTEXT_IMPELLER_DEFAULT
#define MARKTEXT_IMPELLER_DEFAULT 0
#endif
  bool enable_impeller = MARKTEXT_IMPELLER_DEFAULT != 0;
  wchar_t impeller_choice[8] = {0};
  const DWORD impeller_len = ::GetEnvironmentVariableW(
      L"MARKTEXT_IMPELLER", impeller_choice, 8);
  if (impeller_len > 0 && impeller_len < 8) {
    enable_impeller = impeller_choice[0] == L'1';
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
  project.set_impeller_switch(enable_impeller
                                  ? flutter::ImpellerSwitch::Enabled
                                  : flutter::ImpellerSwitch::Disabled);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  command_line_arguments.push_back(
      FormatTraceArgument("--mt-trace-runner-entry=", runner_entry_ms));
  command_line_arguments.push_back(FormatTraceArgument(
      "--mt-trace-engine-start=", MillisecondsSinceProcessStart()));
  // So the trace says which renderer the run was asked for.
  command_line_arguments.push_back(enable_impeller ? "--mt-trace-impeller=1"
                                                   : "--mt-trace-impeller=0");
  // What the build asked for, beside what the run got. Two installers were
  // built one each way and both reported "off", because a MARKTEXT_IMPELLER
  // left over on the machine outranks the built-in default — and the trace
  // could not say so, which cost a round of measurement to work out.
  command_line_arguments.push_back(MARKTEXT_IMPELLER_DEFAULT != 0
                                       ? "--mt-trace-impeller-built=1"
                                       : "--mt-trace-impeller-built=0");

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

  // Take the window off the screen before anything else.
  //
  // This is the whole of what a reader means by the close being slow, and it
  // was invisible to every measurement until the runner took one. Closing the
  // window does not destroy it: `window_manager`'s destroy() is a bare
  // PostQuitMessage, so the loop above ends while the window is still standing
  // there, and it goes only when the process itself finally dies — through all
  // of Windows unmapping a 51 MB install and running every DLL's detach hook.
  // Measured on a reader's machine: 0 ms for the click to be heard, 128 ms to
  // here, and seconds of a window sitting in front of them doing nothing.
  //
  // Hidden rather than destroyed, deliberately. DestroyWindow tears down the
  // Flutter view, which is more of the work this is trying to get out of the
  // reader's way; hiding is immediate and everything that had to reach disk
  // was written before the loop ended.
  if (HWND handle = window.GetHandle()) {
    ::ShowWindow(handle, SW_HIDE);
    RecordWindowGone();
  }

  // End the process now, rather than asking Windows to wind it down.
  //
  // This is the second half of the close; hiding the window above was only the
  // first. Hiding makes the close *look* immediate, this makes it be over, and
  // three things turn on the difference.
  //
  // A window that is gone while the program is not is the kind of untruth this
  // project keeps finding, and this one ends badly. A reader who closes the
  // editor and immediately double-clicks a document lands in the seconds when
  // the old process still holds the single-instance mutex and its named pipe
  // while nothing is left alive to read them: the new launch hands its path to
  // a dead listener and quits, and the document silently never opens. Ending
  // now takes both objects with it, so the next launch finds nobody and starts
  // normally.
  //
  // Everything slower than this is Windows undoing work that only matters to a
  // process with a future. ExitProcess still runs DLL_PROCESS_DETACH for each
  // of the 57 files and 51 MB this install loads — measured on a reader's
  // machine as 128 ms to the last instruction and seconds of window standing
  // there afterwards. Returning from wWinMain would be worse again: it hands
  // control to the C runtime, which waits on every thread the process has, and
  // one of them does not come back. CoUninitialize is skipped for the same
  // reason — an apartment waits for its outstanding objects.
  //
  // What had to be kept was kept before the loop ended: the document, the
  // window geometry, the settings and the trace all went through the file
  // system, which outlives the process that wrote them.
  //
  // This is what a reader means by other applications closing immediately, and
  // it is what several of them do. The cost is real and accepted: a library
  // that would have flushed something in its detach handler does not get to.
  //
  // Nothing here has anything left to flush, and that was checked rather than
  // asserted: no writer in this program holds a user-space buffer. There is no
  // openWrite or IOSink anywhere in lib/ — every one of them uses
  // writeAsString or writeAsBytes, which reach the operating system before
  // they return, and the log a reader reads is five hundred lines in memory
  // that no exit of any kind would have saved.

  // The last instruction this process runs, which is what makes the number
  // beside it worth having: it is the far end of what a reader waits through
  // after pressing the button, and the near end was recorded when WM_CLOSE
  // arrived. After the line below there is no "after this point".
  WriteLastExit(CloseQueuedForMs(), CloseAskedAtMs(), WindowGoneAtMs(),
                MillisecondsSinceProcessStart());
  ::TerminateProcess(::GetCurrentProcess(), EXIT_SUCCESS);
}
