#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

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

namespace {
// -1 until each thing happens. Written from the window procedure and read on
// the way out, both on the same thread.
long long close_asked_at_ms = -1;
long long close_queued_for_ms = -1;
long long window_destroyed_at_ms = -1;

// How long the message being handled waited in the queue.
//
// GetMessageTime gives the moment the message was posted, in the same ticks
// GetTickCount counts, so the difference is how long it sat there. For WM_CLOSE
// sent by the frame in response to a click, the last message collected is that
// click, which is the moment worth having: the reader's own.
//
// Returns -1 rather than a number it cannot vouch for. The tick counter wraps
// roughly every 49 days; unsigned arithmetic carries that correctly, but a
// result beyond any plausible wait means the two values did not belong
// together, and a wrong number here would send somebody looking in the wrong
// half of the close.
long long QueuedForMs() {
  const DWORD posted = (DWORD)::GetMessageTime();
  const DWORD now = ::GetTickCount();
  const DWORD waited = now - posted;
  // A day. Nothing a reader waits through comes near it.
  if (waited > 86400000UL) {
    return -1;
  }
  return (long long)waited;
}
}  // namespace

void RecordCloseAsked() {
  // Every time, so what is reported is the last one — the close that actually
  // ended the process.
  //
  // Keeping the first instead looks defensible and is not. A close can be
  // refused: unsaved work, a prompt, and the reader says cancel. If they close
  // again five minutes later, measuring from the first click puts those five
  // minutes of somebody thinking into "inside the editor", and whoever reads
  // that line goes looking for five minutes of work in a handler that does
  // none.
  //
  // The case keeping the first would have served — a reader clicking twice
  // because nothing happened — is still served: both clicks sat in the queue
  // through the same freeze, so the queue wait reported for the second one
  // shows it just as well.
  close_queued_for_ms = QueuedForMs();
  close_asked_at_ms = MillisecondsSinceProcessStart();
}

long long CloseAskedAtMs() { return close_asked_at_ms; }

long long CloseQueuedForMs() { return close_queued_for_ms; }

void RecordWindowDestroyed() {
  if (window_destroyed_at_ms < 0) {
    window_destroyed_at_ms = MillisecondsSinceProcessStart();
  }
}

long long WindowDestroyedAtMs() { return window_destroyed_at_ms; }
