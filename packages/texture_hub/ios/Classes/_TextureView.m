//
//  _TextureView.m
//  texture_hub
//
//  Created by tohru on 2019/10/13.
//

#import <Foundation/Foundation.h>
#import <stdatomic.h>
#import "_TextureView.h"

@implementation _TextureView {
  NSObject<FlutterTextureRegistry>* _registry;
  CVPixelBufferRef _Atomic _pixelBuffer;
}

- (nonnull instancetype)initWithRegistry:(nonnull NSObject<FlutterTextureRegistry>*)registry {
  self = [super init];
  if (!self) {
    return nil;
  }

  _registry = registry;
  _textureId = -1;
  return self;
}

- (int64_t)registerTexture {
  if (!_hasTexture) {
    _hasTexture = YES;
    _textureId = [_registry registerTexture:self];
  }
  return _textureId;
}

- (void)unregisterTexture {
  if (!_hasTexture) {
    return;
  }

  _hasTexture = NO;
  _textureId = -1;
  [_registry unregisterTexture:_textureId];

  CVPixelBufferRef old = atomic_exchange(&_pixelBuffer, nil);
  if (old != nil) {
    CFRelease(old);
  }
}

- (void)storePixelBuffer:(nonnull CVPixelBufferRef)pixelBuffer {
  if (!_hasTexture) {
    return;
  }

  if (pixelBuffer) {
    CFRetain(pixelBuffer);
  }
  CVPixelBufferRef old = atomic_exchange(&_pixelBuffer, pixelBuffer);
  if (old != nil) {
    CFRelease(old);
  }
  [_registry textureFrameAvailable:_textureId];
}

- (CVPixelBufferRef)copyPixelBuffer {
  return atomic_exchange(&_pixelBuffer, nil);
}

@end
