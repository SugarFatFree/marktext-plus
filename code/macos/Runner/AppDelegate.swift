import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// Matches _filesChannel in lib/main.dart and kFilesChannel in
  /// linux/runner/my_application.cc.
  private static let filesChannelName = "com.marktextplus/files"

  /// Matches _clipboardChannel in lib/services/clipboard_service.dart.
  private static let clipboardChannelName = "com.marktextplus/clipboard"

  /// Paths handed over before the Dart side was listening.
  ///
  /// Double-clicking a document in Finder launches the app and delivers the
  /// path in the same breath, well before the engine has run `main`. Pushing
  /// it straight down the channel would drop it on the floor, which is
  /// indistinguishable from the app ignoring the double click.
  private var pendingFiles: [String] = []
  private var filesChannel: FlutterMethodChannel?
  private var dartIsListening = false

  override func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(
    _ app: NSApplication
  ) -> Bool {
    return true
  }

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    deliver([filename])
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    deliver(filenames)
    sender.reply(toOpenOrPrint: .success)
  }

  /// Puts one selection on the clipboard as both HTML and plain text.
  ///
  /// Pasting into Pages or Word then keeps the headings and the bold, while
  /// pasting into a text editor gets the text. This worked on Windows alone;
  /// here and on Linux the HTML flavour was simply never written.
  private func attachClipboardChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: AppDelegate.clipboardChannelName,
      binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "copyWithHtml",
            let args = call.arguments as? [String: Any],
            let html = args["html"] as? String,
            let text = args["text"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }

      let pasteboard = NSPasteboard.general
      // Declaring both types in one call is what makes them one item: two
      // separate writes would leave only the second on the pasteboard.
      pasteboard.declareTypes([.html, .string], owner: nil)
      pasteboard.setString(html, forType: .html)
      pasteboard.setString(text, forType: .string)
      result(true)
    }
    clipboardChannel = channel
  }

  private var clipboardChannel: FlutterMethodChannel?

  /// Called from MainFlutterWindow once the engine exists.
  func attachFileChannel(controller: FlutterViewController) {
    attachClipboardChannel(controller: controller)
    let channel = FlutterMethodChannel(
      name: AppDelegate.filesChannelName,
      binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "drainPendingFiles" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self else {
        result([String]())
        return
      }
      // Dart asking for the queue is also how it says it is ready.
      self.dartIsListening = true
      let queued = self.pendingFiles
      self.pendingFiles = []
      result(queued)
    }
    filesChannel = channel
  }

  private func deliver(_ paths: [String]) {
    if dartIsListening, let channel = filesChannel {
      channel.invokeMethod("openFiles", arguments: paths)
    } else {
      pendingFiles.append(contentsOf: paths)
    }
  }
}
