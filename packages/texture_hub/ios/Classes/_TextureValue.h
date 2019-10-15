//
//  _TextureValue.h
//  texture_hub
//
//  Created by tohru on 2019/10/13.
//

/**
 * `_TextureValue` stores 'original source image'.
 *
 * This class has been made from the observed fact; in iOS, a Flutter's `TextureWidget` lost its rendering image sometimes after when the app resumed from a background state. In that case, it required to re-render with an original source image.
 */
@interface _TextureValue: NSObject
- (nonnull instancetype)init;
/**
* Store a `pixelBuffer` to the instance.
*
* @param pixelBuffer a source data. The caller must ensure that `pixelBuffer` is available until `_storePixelBufferCopy` returns.
*/
- (void)storePixelBufferNoCopy:(nonnull CVPixelBufferRef)pixelBuffer;
/**
 * Store a copy of `pixelBuffer` to the instance.
 *
 * @param pixelBuffer a source data to be copied. The caller must ensure that `pixelBuffer` is available until `_storePixelBufferCopy` returns.
 * @return a retained pixelBuffer. It is the caller's responsibility to release(`CFRelease`) the returned value.
 */
- (nonnull CVPixelBufferRef)storePixelBufferCopy:(nonnull CVPixelBufferRef)pixelBuffer CF_RETURNS_RETAINED;
/**
 * Get a stored pixel buffer.
 *
 * @return a retained pixelBuffer. It is the caller's responsibility to release(`CFRelease`) the returned value.
 */
- (nullable CVPixelBufferRef)getPixelBufferRetained CF_RETURNS_RETAINED;
@end
