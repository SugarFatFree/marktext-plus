import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // The engine exists from here on, so this is the first moment a channel
    // can be built on it. Documents opened from Finder arrive at the app
    // delegate, which holds them until Dart drains the queue.
    if let delegate = NSApplication.shared.delegate as? AppDelegate {
      delegate.attachFileChannel(controller: flutterViewController)
    }

    super.awakeFromNib()
  }
}
