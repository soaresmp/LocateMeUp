import UIKit
import Flutter
import AVFoundation
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var audioPlayer: AVAudioPlayer?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyA_LXOMGRUc1m_C6tYNtnkCaRuo8xik8Wc")
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
        audioPlayer = nil

        let wavPath = Bundle.main.bundlePath + "/flutter_assets/assets/tones/\(id).wav"
        guard FileManager.default.fileExists(atPath: wavPath) else {
            result(FlutterError(code: "NOT_FOUND",
                                message: "Tone '\(id)' not found at \(wavPath)",
                                details: nil))
            return
        }
        let url = URL(fileURLWithPath: wavPath)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: [])
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            result(nil)
        } catch {
            result(FlutterError(code: "PLAY_ERROR",
                                message: error.localizedDescription,
                                details: nil))
        }
    }
}
