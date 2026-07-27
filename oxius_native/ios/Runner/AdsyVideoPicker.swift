import Flutter
import Photos
import PhotosUI
import UIKit

/// Instant video picking for the post composer (iOS).
///
/// `image_picker` only hands Dart a file once iOS has EXPORTED the asset — and
/// for the HEVC clips every recent iPhone records, that export is a full
/// transcode. On a two-minute clip the composer sat empty for many seconds
/// after the sheet closed, which read as "the upload already started".
///
/// This does the two halves separately:
///   * a poster frame comes back the moment the sheet closes, so the tile is
///     on screen immediately;
///   * the bytes are copied in the background with
///     `preferredAssetRepresentationMode = .current` and PHAssetResource, i.e.
///     the ORIGINAL file, no transcode. Dart waits for that only when the user
///     actually presses Post — by which time it is usually done.
///
/// Dart falls back to `image_picker` whenever any of this is unavailable, so
/// the composer keeps working on older systems and denied permissions.
@available(iOS 14, *)
final class AdsyVideoPicker: NSObject {

  static let shared = AdsyVideoPicker()
  private static let channelName = "adsyclub/video_picker"

  /// Reply for the in-flight `pick` call (the picker allows one at a time).
  private var pickResult: FlutterResult?

  /// token -> copied file path, or an error string once the copy finishes.
  private var finished: [String: Result<String, String>] = [:]
  /// token -> Dart callers parked in `resolve` before the copy landed.
  private var waiting: [String: [FlutterResult]] = [:]
  private let lock = NSLock()

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "pick":
        shared.present(from: controller, result: result)
      case "resolve":
        let args = call.arguments as? [String: Any]
        shared.resolve(token: (args?["token"] as? String) ?? "", result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Picking

  private func present(from controller: UIViewController, result: @escaping FlutterResult) {
    if pickResult != nil {
      result(FlutterError(code: "busy", message: "A picker is already open", details: nil))
      return
    }
    pickResult = result

    var config = PHPickerConfiguration(photoLibrary: .shared())
    config.filter = .videos
    config.selectionLimit = 1
    // The whole point: hand back what is already on disk instead of asking
    // iOS to build a "compatible" copy.
    config.preferredAssetRepresentationMode = .current

    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    controller.present(picker, animated: true)
  }

  /// Report the pick exactly once, whatever path we came through.
  private func reply(_ value: Any?) {
    guard let r = pickResult else { return }
    pickResult = nil
    r(value)
  }

  // MARK: - Background copy

  private func store(token: String, outcome: Result<String, String>) {
    lock.lock()
    finished[token] = outcome
    let parked = waiting.removeValue(forKey: token) ?? []
    lock.unlock()
    for r in parked { deliver(outcome, to: r) }
  }

  private func deliver(_ outcome: Result<String, String>, to result: @escaping FlutterResult) {
    switch outcome {
    case .success(let path):
      DispatchQueue.main.async { result(path) }
    case .failure(let message):
      DispatchQueue.main.async {
        result(FlutterError(code: "copy_failed", message: message, details: nil))
      }
    }
  }

  private func resolve(token: String, result: @escaping FlutterResult) {
    if token.isEmpty {
      result(FlutterError(code: "bad_token", message: "token required", details: nil))
      return
    }
    lock.lock()
    if let outcome = finished[token] {
      lock.unlock()
      deliver(outcome, to: result)
      return
    }
    waiting[token, default: []].append(result)
    lock.unlock()
  }

  private func tempURL(_ name: String) -> URL {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("adsy_video", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent(name)
  }

  /// Poster frame, written as a JPEG we can hand to Dart as a path.
  private func writeThumbnail(_ image: UIImage, token: String) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
    let url = tempURL("\(token).jpg")
    do {
      try data.write(to: url, options: .atomic)
      return url.path
    } catch {
      return nil
    }
  }

  /// Copy the ORIGINAL bytes off the asset. No AVAssetExportSession, so no
  /// transcode and no quality loss — the app's own 720p pass happens later,
  /// once, at submit time.
  private func copyOriginal(asset: PHAsset, token: String) {
    let resources = PHAssetResource.assetResources(for: asset)
    let resource = resources.first(where: { $0.type == .video })
      ?? resources.first(where: { $0.type == .fullSizePairedVideo })
      ?? resources.first
    guard let res = resource else {
      store(token: token, outcome: .failure("no video resource"))
      return
    }
    let ext = (res.originalFilename as NSString).pathExtension
    let url = tempURL("\(token).\(ext.isEmpty ? "mov" : ext)")
    try? FileManager.default.removeItem(at: url)

    let options = PHAssetResourceRequestOptions()
    options.isNetworkAccessAllowed = true   // iCloud-only clips still work
    PHAssetResourceManager.default().writeData(for: res, toFile: url, options: options) {
      [weak self] error in
      if let error = error {
        self?.store(token: token, outcome: .failure(error.localizedDescription))
      } else {
        self?.store(token: token, outcome: .success(url.path))
      }
    }
  }

  /// No PHAsset (limited library access): fall back to the item provider. Same
  /// contract, just slower — iOS may build a copy for us here.
  private func copyViaProvider(_ provider: NSItemProvider, token: String) {
    let type = UTType.movie.identifier
    guard provider.hasItemConformingToTypeIdentifier(type) else {
      store(token: token, outcome: .failure("not a movie"))
      return
    }
    provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] src, error in
      guard let self = self else { return }
      guard let src = src else {
        self.store(token: token, outcome: .failure(error?.localizedDescription ?? "load failed"))
        return
      }
      // The provider's file is deleted as soon as this block returns.
      let dest = self.tempURL("\(token).\(src.pathExtension.isEmpty ? "mov" : src.pathExtension)")
      try? FileManager.default.removeItem(at: dest)
      do {
        try FileManager.default.copyItem(at: src, to: dest)
        self.store(token: token, outcome: .success(dest.path))
      } catch {
        self.store(token: token, outcome: .failure(error.localizedDescription))
      }
    }
  }
}

@available(iOS 14, *)
extension AdsyVideoPicker: PHPickerViewControllerDelegate {

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard let item = results.first else {
      reply(nil)                     // cancelled
      return
    }

    let token = UUID().uuidString
    let provider = item.itemProvider

    // PHAsset gives us both the instant poster and the no-transcode copy, but
    // only when the library is actually readable.
    var asset: PHAsset?
    if let id = item.assetIdentifier,
       PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized {
      asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }

    if let asset = asset {
      let durationMs = Int(asset.duration * 1000.0)
      let options = PHImageRequestOptions()
      options.isSynchronous = false
      options.deliveryMode = .fastFormat        // whatever is cached, now
      options.isNetworkAccessAllowed = true
      PHImageManager.default().requestImage(
        for: asset,
        targetSize: CGSize(width: 640, height: 640),
        contentMode: .aspectFill,
        options: options
      ) { [weak self] image, _ in
        guard let self = self else { return }
        var thumb: String?
        if let image = image { thumb = self.writeThumbnail(image, token: token) }
        self.reply(["token": token, "thumb": thumb as Any, "durationMs": durationMs])
      }
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.copyOriginal(asset: asset, token: token)
      }
      return
    }

    // Limited/denied library: still answer immediately, with whatever preview
    // the provider can give us.
    provider.loadPreviewImage(options: [:]) { [weak self] object, _ in
      guard let self = self else { return }
      var thumb: String?
      if let image = object as? UIImage { thumb = self.writeThumbnail(image, token: token) }
      self.reply(["token": token, "thumb": thumb as Any, "durationMs": 0])
    }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.copyViaProvider(provider, token: token)
    }
  }
}
