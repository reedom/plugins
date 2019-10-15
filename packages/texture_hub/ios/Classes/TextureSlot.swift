//
//  TextureSlot.swift
//  texture_hub
//
//  Created by tohru on 2019/10/14.
//

import Flutter

/// `TextureSlot` is a primitive unit in this plugin.
///
/// - A `TextureSlot` instance represents a `handle`, which is a unique value that the Dart side library generates.
/// - It receives a pixelBuffer from any external services, then it may store the buffer, may broadcast the buffer to its listeners.
internal class TextureSlot {
  /// An identifier. It should unique among `TextureSlot` instances.
  let handle: Int64
  /// `tag` is just a string data that any plugin clients can attach to a `handle`.
  let tag: String?
  /// If `true`, the instance keeps a most recent pixelBuffer received via `handlePixelBuffer()`.
  let keepLatest: Bool
  /// If `true`, the instance uses a copy of pixelBuffer, instead of its original, for storing or broadcasting. This should impact on runtime performance but it will bring a sort of 'safety'.
  let useCopy: Bool  
  private(set) var active = true
  private let listeners: _TextureListeners
  private let textureValue: _TextureValue
  private let textureView: _TextureView

  init(registry: FlutterTextureRegistry, handle: Int64, tag: String?, keepLatest: Bool, useCopy: Bool) {
    self.handle = handle
    self.tag = tag
    self.keepLatest = keepLatest
    self.useCopy = useCopy
    
    listeners = _TextureListeners()
    textureValue = _TextureValue()
    textureView = _TextureView(registry: registry)
  }

  /// Deactivate the instance so that it won't handle incoming pixelBuffers anymore.
  func deactivate() {
    active = false
  }
  
  /// Register the instance to the Flutter plugin registrar as a texture provider and returns a texutureId. With a textureId, a `Texture` widget (in Dart side) can render textures that the instance handles.
  func registerTexture() -> Int64? {
    let textureId = textureView.registerTexture()
    guard 0 <= textureId else { return nil }
    if let pixelBuffer = textureValue.getPixelBufferRetained() {
      textureView.store(pixelBuffer)
    }
    return textureId
  }
  
  func unregisterTexture() {
    textureView.unregisterTexture()
  }
  
  func getTextureId() -> Int64? {
    let textureId = textureView.textureId
    guard 0 <= textureId else { return nil }
    return textureId
  }
  
  /// Add a listener. A listener will be notified whenever the instance receives a new pixelBuffer.
  func addListener(_ listener: TextureHubListener) {
    guard listener is NSObject else { fatalError() }
    listeners.addListener(listener as! NSObject)
  }

  /// Remove a listener.
  func removeListener(_ listener: TextureHubListener) {
    guard listener is NSObject else { fatalError() }
    listeners.removeListener(listener as! NSObject)
  }

  /// Drop all of listeners.
  func removeAllListeners() {
    listeners.removeAllListeners()
  }

  /// Get a pixelBuffer stored in the instance.
  ///
  /// The instance stores a pixelBuffer only if `keepLatest` is `true`.
  ///
  /// - returns: a pixelBuffer stored in the instance. If `keepLatest` is `false`, the instance always returns `nil`.
  func getPixelBuffer() -> CVPixelBuffer? {
    guard active else { return nil }
    return textureValue.getPixelBufferRetained()
  }
  
  /// Receive a new pixelBuffer and proceed further process.
  ///
  /// - If `keepLatest` is true, the instance stores the value and future call of `getPixelBuffer()` will return it.
  /// - If a texture is active(`registerTexture()` has been called), the instance passes the value so that the texture renders the value.
  /// - The instance notifies to all of listeners with the value.
  ///
  /// - parameters:
  ///   - pixelBuffer: new pixelBuffer to be handled.
  func handlePixelBuffer(_ pixelBuffer: CVPixelBuffer) {
    guard
      active,
      (keepLatest || textureView.hasTexture)
      else { return }
    
    var pb: CVPixelBuffer!
    if useCopy {
      let copiedPixelBuffer = textureValue.storePixelBufferCopy(pixelBuffer)
      textureView.store(copiedPixelBuffer)
      pb = copiedPixelBuffer
    } else {
      textureValue.storePixelBufferNoCopy(pixelBuffer)
      pb = pixelBuffer
    }
    
    if listeners.isEmpty() {
      return
    }
    
    DispatchQueue.global().async {
      self.listeners.invoke { listener in
        guard let listener = listener as? TextureHubListener else { return }
        listener.textureHubListner(didReceive: pb)
      }
    }
  }
  
  func repaint() {
    guard let pixelBuffer = textureValue.getPixelBufferRetained() else { return }
    textureView.store(pixelBuffer)
  }
}
