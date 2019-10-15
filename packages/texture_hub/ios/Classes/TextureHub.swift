//
//  TextureHub.swift
//  texture_hub
//
//  Created by tohru on 2019/10/14.
//

@objc public protocol TextureHubListener: NSObjectProtocol {
  func textureHubListner(didReceive pixelBuffer: CVPixelBuffer)
}

@objc public protocol TextureHub: NSObjectProtocol {
  func addListener(handle: Int64, listener: TextureHubListener)
  func removeListener(handle: Int64, listener: TextureHubListener)
  func handlePixelBuffer(handle: Int64, pixelBuffer: CVPixelBuffer)
}

@objc public class TextureHubAdapter: NSObject, TextureHub {
  private let slots: TextureSlots
  
  init(_ slots: TextureSlots) {
    self.slots = slots
  }
  
  public func addListener(handle: Int64, listener: TextureHubListener) {
    guard let slot = slots.getSlot(handle) else { return }
    slot.addListener(listener)
  }
  
  public func removeListener(handle: Int64, listener: TextureHubListener) {
    guard let slot = slots.getSlot(handle) else { return }
    slot.removeListener(listener)
  }

  public func handlePixelBuffer(handle: Int64, pixelBuffer: CVPixelBuffer) {
    guard let slot = slots.getSlot(handle) else { return }
    slot.handlePixelBuffer(pixelBuffer)
  }
}
