import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var audioPlayer: AVAudioPlayer?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Window is initialised by super — safe to access now
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return result
        }
        let channel = FlutterMethodChannel(
            name: "com.locatemeup/ringtone",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleRingtone(call: call, result: result)
        }
        return result
    }

    private func handleRingtone(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAvailableTones":
            result([
                ["id": "beep",  "title": "Beep"],
                ["id": "pulse", "title": "Pulse"],
                ["id": "alert", "title": "Alert"],
            ])
        case "playRingtone":
            let args = call.arguments as? [String: Any]
            let toneId = args?["uri"] as? String ?? "beep"
            playTone(id: toneId, result: result)
        case "stopRingtone":
            audioPlayer?.stop()
            audioPlayer = nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func playTone(id: String, result: @escaping FlutterResult) {
        audioPlayer?.stop()
        guard let url = Bundle.main.url(
            forResource: id,
            withExtension: "wav",
            subdirectory: "flutter_assets/assets/tones"
        ) else {
            result(FlutterError(code: "NOT_FOUND",
                                message: "Tone '\(id)' not found in bundle",
                                details: nil))
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            result(nil)
        } catch {
            result(FlutterError(code: "PLAY_ERROR",
                                message: error.localizedDescription,
                                details: nil))
        }
    }
}
