#import "FirebaseMlVisionPlugin.h"

@implementation TextRecognizer
static FIRVisionTextRecognizer *recognizer;

+ (void)handleDetection:(FIRVisionImage *)image
                options:(NSDictionary *)options
                 result:(FlutterResult)result {
  FIRVision *vision = [FIRVision vision];

  NSString *recognizerType = options[@"recognizerType"];
  if ([recognizerType isEqualToString:@"onDevice"]) {
    recognizer = [vision onDeviceTextRecognizer];
  } else if ([recognizerType isEqualToString:@"cloud"]) {
    FIRVisionCloudTextRecognizerOptions *recognizerOptions =
        [TextRecognizer parseCloudOptions:options result:result];
    if (!recognizerOptions) return;

    recognizer = [vision cloudTextRecognizerWithOptions:recognizerOptions];
  } else {
    NSString *errorString =
        [NSString stringWithFormat:@"No TextRecognizer for type: %@", recognizerType];
    @throw(
        [NSException exceptionWithName:NSInvalidArgumentException reason:errorString userInfo:nil]);
  }

  [recognizer processImage:image
                completion:^(FIRVisionText *_Nullable visionText, NSError *_Nullable error) {
                  if (error) {
                    [FLTFirebaseMlVisionPlugin handleError:error result:result];
                    return;
                  } else if (!visionText) {
                    result(@{@"text" : @"", @"blocks" : @[]});
                    return;
                  }

                  NSMutableDictionary *visionTextData = [NSMutableDictionary dictionary];
                  visionTextData[@"text"] = visionText.text;

                  NSMutableArray *allBlockData = [NSMutableArray array];
                  for (FIRVisionTextBlock *block in visionText.blocks) {
                    NSMutableDictionary *blockData = [NSMutableDictionary dictionary];

                    [self addData:blockData
                          confidence:block.confidence
                        cornerPoints:block.cornerPoints
                               frame:block.frame
                           languages:block.recognizedLanguages
                                text:block.text];

                    NSMutableArray *allLineData = [NSMutableArray array];
                    for (FIRVisionTextLine *line in block.lines) {
                      NSMutableDictionary *lineData = [NSMutableDictionary dictionary];

                      [self addData:lineData
                            confidence:line.confidence
                          cornerPoints:line.cornerPoints
                                 frame:line.frame
                             languages:line.recognizedLanguages
                                  text:line.text];

                      NSMutableArray *allElementData = [NSMutableArray array];
                      for (FIRVisionTextElement *element in line.elements) {
                        NSMutableDictionary *elementData = [NSMutableDictionary dictionary];

                        [self addData:elementData
                              confidence:element.confidence
                            cornerPoints:element.cornerPoints
                                   frame:element.frame
                               languages:element.recognizedLanguages
                                    text:element.text];

                        [allElementData addObject:elementData];
                      }

                      lineData[@"elements"] = allElementData;
                      [allLineData addObject:lineData];
                    }

                    blockData[@"lines"] = allLineData;
                    [allBlockData addObject:blockData];
                  }

                  visionTextData[@"blocks"] = allBlockData;
                  result(visionTextData);
                }];
}

+ (void)addData:(NSMutableDictionary *)addTo
      confidence:(NSNumber *)confidence
    cornerPoints:(NSArray<NSValue *> *)cornerPoints
           frame:(CGRect)frame
       languages:(NSArray<FIRVisionTextRecognizedLanguage *> *)languages
            text:(NSString *)text {
  __block NSMutableArray<NSArray *> *points = [NSMutableArray array];

  for (NSValue *point in points) {
    [points addObject:@[ @(((__bridge CGPoint *)point)->x), @(((__bridge CGPoint *)point)->y) ]];
  }

  __block NSMutableArray<NSDictionary *> *allLanguageData = [NSMutableArray array];
  for (FIRVisionTextRecognizedLanguage *language in languages) {
    [allLanguageData addObject:@{
      @"languageCode" : language.languageCode ? language.languageCode : [NSNull null]
    }];
  }

  [addTo addEntriesFromDictionary:@{
    @"confidence" : confidence ? confidence : [NSNull null],
    @"points" : points,
    @"left" : @((int)frame.origin.x),
    @"top" : @((int)frame.origin.y),
    @"width" : @((int)frame.size.width),
    @"height" : @((int)frame.size.height),
    @"recognizedLanguages" : allLanguageData,
    @"text" : text,
  }];
}

+ (FIRVisionCloudTextRecognizerOptions *)parseCloudOptions:(NSDictionary *)optionsData
                                                    result:(FlutterResult)result {
  FIRVisionCloudTextRecognizerOptions *options = [[FIRVisionCloudTextRecognizerOptions alloc] init];

  if ([optionsData[@"apiKeyOverride"] isKindOfClass:[NSString class]]) {
    options.APIKeyOverride = optionsData[@"apiKeyOverride"];
  }
  if ([optionsData[@"hintedLanguages"] isKindOfClass:[NSArray class]]) {
    options.languageHints = optionsData[@"hintedLanguages"];
  }

  NSString *modelType = optionsData[@"modelType"];
  if ([modelType isEqualToString:@"sparse"]) {
    options.modelType = FIRVisionCloudTextModelTypeSparse;
  } else if ([modelType isEqualToString:@"dense"]) {
    options.modelType = FIRVisionCloudTextModelTypeDense;
  } else {
    NSString *errorString = [NSString stringWithFormat:@"No support for model type: %@", modelType];
    NSError *error = [NSError errorWithDomain:errorString code:[@0 integerValue] userInfo:nil];
    [FLTFirebaseMlVisionPlugin handleError:error result:result];

    return nil;
  }

  return options;
}
@end
