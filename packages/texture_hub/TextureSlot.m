//
//  TextureSlot.m
//  camera
//
//  Created by tohru on 2019/10/12.
//

#import <Foundation/Foundation.h>
#import <stdatomic.h>
#import "TextureSlot.h"
#import "_TextureListeners.h"
#import "_TextureValue.h"
#import "_TextureView.h"

@implementation _TextureSlot {
  _TextureListeners* _listeners;
  _TextureValue* _textureValue;
  _TextureView* _textureView;
  BOOL _Atomic _handling;
}

- (nonnull instancetype)initWithRegistry:(nonnull NSObject<FlutterTextureRegistry>*)registry
                                  handle:(int64_t)handle
                                     tag:(nullable NSString*)tag
                              keepLatest:(BOOL)keepLatest
                                 useCopy:(BOOL)useCopy {
  self = [super init];
  _handle = handle;
  _tag = [tag copy];
  _keepLatest = keepLatest;
  _useCopy = useCopy;

  _listeners = [_TextureListeners new];
  _textureValue = [_TextureValue new];
  _textureView = [[_TextureView alloc] initWithRegistry:registry];
  return self;
}

- (void)registerTexture {
  [_textureView registerTexture];
}

- (void)unregisterTexture {
  [_textureView unregisterTexture];
}

- (void)addListener:(nonnull NSObject<TextureHubListner>*)listener {
  [_listeners addListener:listener];
}

- (void)removeListener:(nonnull NSObject<TextureHubListner>*)listener {
  [_listeners removeListener:listener];
}

- (void)removeAllListeners {
  [_listeners removeAllListeners];
}

- (void)handlePixelBuffer:(CVPixelBufferRef)pixelBuffer {
  if (!_keepLatest && !_textureView.hasTexture) {
    return;
  }

  if (atomic_exchange(&_handling, YES)) {
    // The previous call is still running.
    return;
  }

  CVPixelBufferRef pixelBufferForListeners = nil;
  if (_useCopy) {
    CVPixelBufferRef newPixelBuffer = [_textureValue storePixelBufferCopy:pixelBuffer];
    [_textureView storePixelBuffer:newPixelBuffer];
    pixelBufferForListeners = newPixelBuffer;
  } else {
    if (pixelBuffer) {
      pixelBufferForListeners = pixelBuffer;
      CFRetain(pixelBufferForListeners);
    }
    [_textureValue storePixelBufferNoCopy:pixelBuffer];
    [_textureView storePixelBuffer:pixelBuffer];
  }

  if (!pixelBufferForListeners && _listeners.isEmpty) {
    CFRelease(pixelBufferForListeners);
    atomic_exchange(&_handling, FALSE);
    return;
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    [self _notify:pixelBufferForListeners];
    CFRelease(pixelBufferForListeners);
    atomic_exchange(&self->_handling, FALSE);
  });
}

- (void)_notify:(CVPixelBufferRef)pixelBuffer {
  [_listeners invoke:^(NSObject<TextureHubListner>* _Nonnull listener) {
    [listener textureHubListnerDidReceivePixelBuffer:pixelBuffer];
  }];
}

- (void)repaint {
  if (!_textureView.hasTexture) return;

  CVPixelBufferRef pixelBuffer = [_textureValue getPixelBufferRetained];
  if (pixelBuffer) {
    [_textureView storePixelBuffer:pixelBuffer];
    CFRelease(pixelBuffer);
  }
}

- (nullable CVPixelBufferRef)getPixelBufferRetained {
  return [_textureValue getPixelBufferRetained];
}

@end
