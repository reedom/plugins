//
//  TextureSlots.swift
//  texture_hub
//
//  Created by tohru on 2019/10/15.
//

import Flutter

internal class TextureSlots {
  private let textureRegistry: FlutterTextureRegistry
  private let serialQueue = DispatchQueue(label: "flutter.plugins.io/texture_hub.slots")
  private var slots = [Int64: TextureSlot]()

  init(textureRegistry: FlutterTextureRegistry) {
    self.textureRegistry = textureRegistry
  }

  typealias ForEachCallback = (TextureSlot) -> Void
  
  func forEach(_ callback: ForEachCallback) {
    serialQueue.sync {
      slots.forEach { callback($1) }
    }
  }
  
  /// Allocate a new texture slot.
  ///
  func allocateSlot(handle: Int64,
                    tag: String?,
                    keepLatest: Bool,
                    useCopy: Bool,
                    useTextureWidget: Bool) {
    let slot = TextureSlot(registry: textureRegistry,
                           handle: handle,
                           tag: tag,
                           keepLatest: keepLatest,
                           useCopy: useCopy)
    if useTextureWidget {
      _ = slot.registerTexture();
    }
    
    serialQueue.sync {
      slots[handle] = slot
    }
  }

  func deallocateSlot(handle: Int64) {
    var slot: TextureSlot?
    serialQueue.sync {
      slot = slots.removeValue(forKey: handle)
    }
    slot?.deactivate()
  }
  
  func getSlot(_ handle: Int64) -> TextureSlot? {
    serialQueue.sync {
      return slots[handle]
    }
  }
  
  func createTexture(handle: Int64) -> Int64? {
    guard let slot = getSlot(handle) else { return -1 }
    return slot.registerTexture()
  }

  func getTextureId(handle: Int64) -> Int64? {
    guard let slot = getSlot(handle) else { return -1 }
    return slot.getTextureId()
  }
}
