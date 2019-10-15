//
//  _TextureView.h
//  Pods
//
//  Created by tohru on 2019/10/13.
//

#import <Flutter/Flutter.h>

@interface _TextureView: NSObject<FlutterTexture>
- (nonnull instancetype)initWithRegistry:(nonnull NSObject<FlutterTextureRegistry>*)registry;
/**
 * Store a `pixelBuffer` to the instance.
 *
 * @param pixelBuffer a source data. The caller must ensure that `pixelBuffer` is available until `_storePixelBufferCopy` returns.
 */
- (void)storePixelBuffer:(nonnull CVPixelBufferRef)pixelBuffer;
- (int64_t)registerTexture;
- (void)unregisterTexture;

@property (readonly, nonatomic) BOOL hasTexture;
@property (readonly, nonatomic) int64_t textureId;

@end
