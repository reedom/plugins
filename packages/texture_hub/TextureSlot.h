//
//  TextureSlot.h
//  texture_hub
//
//  Created by tohru on 2019/10/12.
//

#import <Flutter/Flutter.h>

@interface _TextureSlot : NSObject

@property(readonly, nonatomic) int64_t handle;
@property(readonly, nonatomic, nullable) NSString* tag;
@property(readonly, nonatomic) BOOL keepLatest;
@property(readonly, nonatomic) BOOL useCopy;
@property(readonly, nonatomic) BOOL active;
@property(readonly, nonatomic) int64_t textureId;

- (nonnull instancetype)initWithRegistry:(nonnull NSObject<FlutterTextureRegistry>*)registry
                                  handle:(int64_t)handle
                                     tag:(nullable NSString*)tag
                              keepLatest:(BOOL)keepLatest
                                 useCopy:(BOOL)useCopy;
- (void)registerTexture;
- (void)unregisterTexture;

- (void)addListener:(nonnull NSObject*)listener;
- (void)removeListener:(nonnull NSObject*)listener;
- (void)removeAllListeners;

- (void)handlePixelBuffer:(nonnull CVPixelBufferRef)pixelBuffer;
- (void)repaint;
- (nullable CVPixelBufferRef)getPixelBufferRetained;

@end
