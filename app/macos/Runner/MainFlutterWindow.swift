import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    BookmarkChannel.register(with: flutterViewController)

    super.awakeFromNib()
  }
}

class BookmarkChannel {
  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "enterprise_tools/bookmark",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "createBookmark":
        guard let path = call.arguments as? String else {
          result(FlutterError(code: "bad_args", message: "缺少路径", details: nil))
          return
        }
        let url = URL(fileURLWithPath: path)
        do {
          let data = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          result(data.base64EncodedString())
        } catch {
          result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
        }
      case "startAccess":
        guard let base64 = call.arguments as? String,
              let data = Data(base64Encoded: base64) else {
          result(FlutterError(code: "bad_args", message: "缺少书签数据", details: nil))
          return
        }
        do {
          var stale = false
          let url = try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
          )
          let ok = url.startAccessingSecurityScopedResource()
          result(ok)
        } catch {
          result(FlutterError(code: "access_failed", message: error.localizedDescription, details: nil))
        }
      case "stopAccess":
        guard let base64 = call.arguments as? String,
              let data = Data(base64Encoded: base64) else {
          result(false)
          return
        }
        do {
          var stale = false
          let url = try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
          )
          url.stopAccessingSecurityScopedResource()
          result(true)
        } catch {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
