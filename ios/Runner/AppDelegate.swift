import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let widgetQueue = DispatchQueue(label: "schedule_app.home_widget")

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "schedule_app/home_widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [widgetQueue] call, result in
      guard call.method == "publish" else { result(FlutterMethodNotImplemented); return }
      guard #available(iOS 17, *) else { result(nil); return }
      guard let payload = call.arguments as? String,
            let file = WidgetSnapshotStore.fileURL else {
        result(FlutterError(code: "widget_container_unavailable", message: nil, details: nil))
        return
      }
      widgetQueue.async {
        do {
          try Data(payload.utf8).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
          DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshotStore.kind)
            result(nil)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "snapshot_write_failed", message: nil, details: nil))
          }
        }
      }
    }
  }
}
