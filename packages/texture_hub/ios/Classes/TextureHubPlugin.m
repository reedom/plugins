#import "TextureHubPlugin.h"
#import <texture_hub/texture_hub-Swift.h>

@implementation TextureHubPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTextureHubPlugin registerWithRegistrar:registrar];
}
@end
