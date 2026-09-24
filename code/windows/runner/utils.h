#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a console for the process, and redirects stdout and stderr to
// it for both the runner and the Flutter library.
void CreateAndAttachConsole();

// Milliseconds between this process being created and right now.
//
// Here rather than in main.cpp because the window procedure needs it too: the
// one number nobody was recording is when the close was asked for, and that
// arrives as a message long before Dart hears about it.
long long MillisecondsSinceProcessStart();

// Records that the window has been asked to close, the first time it is.
//
// Called from the window procedure while the message that asked for it is
// still the one being handled, because that is the only moment Windows can
// still say when it was posted.
void RecordCloseAsked();

// When the window was asked to close, or -1 if it never was.
long long CloseAskedAtMs();

// How long the message asking for the close sat in the queue before it was
// handled, or -1 if that is not known.
//
// The one stretch neither end could see. A window that has been asked to close
// stays on screen until Dart answers, so a thread too busy to collect the
// message is a window sitting there doing nothing — which is what a reader
// means by the close being slow, and it happens before anything else here
// starts counting.
long long CloseQueuedForMs();

// Records that the window has been destroyed, the first time it is.
void RecordWindowDestroyed();

// When the window was destroyed, or -1 if it never was.
long long WindowDestroyedAtMs();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. Returns an empty std::string on failure.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty std::vector<std::string> on failure.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_
