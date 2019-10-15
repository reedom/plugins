//
//  _TextureValue.m
//  texture_hub
//
//  Created by tohru on 2019/10/13.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <stdatomic.h>
#import "_TextureValue.h"

static void _pixelBufferReleaseCallback(void *releaseRefCon, const void* baseAddress) {
  free((void*)baseAddress);
}

static CVPixelBufferRef _copyPixelBuffer(CVPixelBufferRef _Nonnull pixelBuffer) {
  CVPixelBufferLockBaseAddress(pixelBuffer, 0);
  void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
  int width = (int)CVPixelBufferGetWidth(pixelBuffer);
  int height = (int)CVPixelBufferGetHeight(pixelBuffer);

  vImage_Buffer inBuff;
  inBuff.width = width;
  inBuff.height = height;
  inBuff.rowBytes = bytesPerRow;

  int startpos = 0;
  inBuff.data = baseAddress+startpos;

  unsigned char *outImg = (unsigned char*)malloc(4 * width * height);
  vImage_Buffer outBuff = {outImg, height, width, 4 * width};

  vImage_Error err = vImageScale_ARGB8888(&inBuff, &outBuff, NULL, 0);
  if (err != kvImageNoError) {
    NSLog(@" error %ld", err);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return NULL;
  }

  CVPixelBufferRef outPixedBuffer = NULL;
  CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                               width, height, kCVPixelFormatType_32BGRA,
                               outImg, width * 4,
                               _pixelBufferReleaseCallback,
                               NULL, NULL, &outPixedBuffer);
  CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
  // free((void*)outImg); no need to free the buffer

  return outPixedBuffer;
}

@implementation _TextureValue {
  dispatch_queue_t _dispatch_queue;
  CVPixelBufferRef _Atomic _pixelBuffer;
}

- (nonnull instancetype)init {
  self = [super init];
  NSString* queue_name = [NSString stringWithFormat:@"flutter.plugins.io/texture_hub/TextureValue/%lu", (unsigned long)self.hash];
  _dispatch_queue = dispatch_queue_create([queue_name cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_CONCURRENT);
  return self;
}

- (void)storePixelBufferNoCopy:(nonnull CVPixelBufferRef)pixelBuffer {
  CFRetain(pixelBuffer);

  // To work with `getPixelBufferRetained()`, we need to use `_dispatch_queue` over `atomic_exchange()`.
  dispatch_barrier_sync(_dispatch_queue, ^{
    if (self->_pixelBuffer != nil) {
      CFRelease(self->_pixelBuffer);
    }
    self->_pixelBuffer = pixelBuffer;
  });
}

- (nonnull CVPixelBufferRef)storePixelBufferCopy:(nonnull CVPixelBufferRef)pixelBuffer {
  CVPixelBufferRef newPixelBuffer = _copyPixelBuffer(pixelBuffer);
  // Prepare for returning the copied value.
  CFRetain(newPixelBuffer);
  
  // To work with `getPixelBufferRetained()`, we need to use `_dispatch_queue` over `atomic_exchange()`.
  dispatch_barrier_sync(_dispatch_queue, ^{
    if (self->_pixelBuffer != nil) {
      CFRelease(self->_pixelBuffer);
    }
    self->_pixelBuffer = newPixelBuffer;
  });
  
  return newPixelBuffer;
}

- (nullable CVPixelBufferRef)getPixelBufferRetained {
  __block CVPixelBufferRef pixelBuffer;
  dispatch_sync(_dispatch_queue, ^{
    pixelBuffer = self->_pixelBuffer;
    if (pixelBuffer) {
      CFRetain(pixelBuffer);
    }
  });
  return pixelBuffer;
}

@end
