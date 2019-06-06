#import "RNFleaClient.h"
#import "RNPixelBufferUtilities.h"

#import "TIOModel.h"
#import "TIOModelBundle.h"
#import "TIOPixelBuffer.h"
#import "TIOData.h"
#import "NSDictionary+TIOExtensions.h"
#import "UIImage+TIOCVPixelBufferExtensions.h"
#import "TIOTrainableModel.h"
#import "TIOFleaClient.h"
#import "TIOFleaStatus.h"
#import "TIOFederatedManager.h"
#import "TIOLayerInterface.h"
#import "TIOBatch.h"
#import "TIOBatchDataSource.h"
#import "TIOFederatedManagerDelegate.h"
#import "TIOFederatedManagerDataSourceProvider.h"

/**
 * Image input keys.
 */

static NSString * const RNTIOImageKeyData =         @"RNTIOImageKeyData";
static NSString * const RNTIOImageKeyFormat =       @"RNTIOImageKeyFormat";
static NSString * const RNTIOImageKeyWidth =        @"RNTIOImageKeyWidth";
static NSString * const RNTIOImageKeyHeight =       @"RNTIOImageKeyHeight";
static NSString * const RNTIOImageKeyOrientation =  @"RNTIOImageKeyOrientation";

/**
 * Supported image encodings.
 */

typedef NS_ENUM(NSInteger, RNTIOImageDataType) {
    RNTIOImageDataTypeUnknown,
    RNTIOImageDataTypeARGB,
    RNTIOImageDataTypeBGRA,
    RNTIOImageDataTypeJPEG,
    RNTIOImageDataTypePNG,
    RNTIOImageDataTypeFile
};

// MARK: -

@implementation RCTConvert (RNFleaClientEnumerations)

/**
 * Bridged constants for supported image encodings. React Native images are
 * encoded as base64 strings and their format must be specified for image
 * inputs.
 */

RCT_ENUM_CONVERTER(RNTIOImageDataType, (@{
                                          @"imageTypeUnknown": @(RNTIOImageDataTypeUnknown),
                                          @"imageTypeARGB":    @(RNTIOImageDataTypeARGB),
                                          @"imageTypeBGRA":    @(RNTIOImageDataTypeBGRA),
                                          @"imageTypeJPEG":    @(RNTIOImageDataTypeJPEG),
                                          @"imageTypePNG":     @(RNTIOImageDataTypePNG),
                                          @"imageTypeFile":    @(RNTIOImageDataTypeFile)
                                          }), RNTIOImageDataTypeUnknown, integerValue);

/**
 * Bridged constants for suppoted image orientations. Most images will be
 * oriented 'Up', and that is the default value, but images coming directly
 * from a camera pixel buffer will be oriented 'Right'.
 */

RCT_ENUM_CONVERTER(CGImagePropertyOrientation, (@{
                                                  @"imageOrientationUp":              @(kCGImagePropertyOrientationUp),
                                                  @"imageOrientationUpMirrored":      @(kCGImagePropertyOrientationUpMirrored),
                                                  @"imageOrientationDown":            @(kCGImagePropertyOrientationDown),
                                                  @"imageOrientationDownMirrored":    @(kCGImagePropertyOrientationDownMirrored),
                                                  @"imageOrientationLeftMirrored":    @(kCGImagePropertyOrientationLeftMirrored),
                                                  @"imageOrientationRight":           @(kCGImagePropertyOrientationRight),
                                                  @"imageOrientationRightMirrored":   @(kCGImagePropertyOrientationRightMirrored),
                                                  @"imageOrientationLeft":            @(kCGImagePropertyOrientationLeft)
                                                  }), kCGImagePropertyOrientationUp, integerValue);

@end

@interface RNFleaClient() <TIOFederatedManagerDelegate, TIOFederatedManagerDataSourceProvider, TIOBatchDataSource>

@property TIOFleaClient* fleaClient;
@property TIOFederatedManager *manager;
@property NSArray<NSDictionary *> *trainingSet;
@property RCTResponseSenderBlock trainingCallback;
@property TIOModelBundle* trainingModelBundle;
@property id<TIOModel> trainingModel;

@end

@implementation RNFleaClient

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSString*)baseUrl authToken:(NSString*)authToken callback:(RCTResponseSenderBlock)callback) {
    NSURL *URL = [NSURL URLWithString:baseUrl];
    
    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.defaultSessionConfiguration;
    configuration.HTTPAdditionalHeaders = @{
        @"Authorization": authToken
    };
    
    NSURLSession *URLSession = [NSURLSession sessionWithConfiguration:configuration];
    
    self.fleaClient = [[TIOFleaClient alloc] initWithBaseURL:URL session:URLSession downloadSession:nil];
    
    // Immediately perform a health check
    
    [self.fleaClient GETHealthStatus:^(TIOFleaStatus * _Nullable response, NSError * _Nonnull error) {
        if (error) {
            callback(@[[error localizedDescription], NSNull.null]);
            return;
        }
        
        self.manager = [[TIOFederatedManager alloc] initWithClient:self.fleaClient];
        self.manager.dataSourceProvider = self;
        self.manager.delegate = self;
        
        callback(@[NSNull.null, @(YES)]);
    }];
}

RCT_EXPORT_METHOD(unregisterTasks) {
    if (self.manager == nil) {
        return;
    }
    
    [self.manager.registeredModelIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.manager unregisterForTasksForModelWithId:obj];
    }];
}

RCT_EXPORT_METHOD(checkTasksForModel:(NSString*)modelPath callback:(RCTResponseSenderBlock)callback) {
    //Get model bundle from url
    TIOModelBundle *bundle = [[TIOModelBundle alloc] initWithPath:modelPath];
    // TODO: bundle can be nil
    
    [self.manager registerForTasksForModelWithId:bundle.identifier];
    
    [self.manager checkIfTasksAvailable:^(BOOL tasksAvailable, NSError * _Nullable error) {
        if (error) {
            callback(@[[error localizedDescription], NSNull.null]);
            return;
        }

        callback(@[NSNull.null, @(tasksAvailable)]);
    }];
}

RCT_EXPORT_METHOD(train:(NSString*)modelPath trainingSet:(NSArray<NSDictionary *> *)trainingSet callback:(RCTResponseSenderBlock)callback) {
    self.trainingSet = trainingSet;
    self.trainingCallback = callback;
    self.trainingModelBundle = [[TIOModelBundle alloc] initWithPath:modelPath];
    // TODO: bundle can be nil
    self.trainingModel = self.trainingModelBundle.newModel;
    // TODO: model can be nil
    
    [self.manager registerForTasksForModelWithId:self.trainingModelBundle.identifier];
    [self.manager beginProcessing];
}

- (id<TIOBatchDataSource>)federatedManager:(TIOFederatedManager*)manager dataSourceForTaskWithId:(NSString*)taskIdentifier {
    return self;
}

- (nullable TIOModelBundle*)federatedManager:(TIOFederatedManager*)manager modelBundleForModelWithId:(NSString*)modelIdentifier {
    if (![self.trainingModelBundle.identifier isEqualToString:modelIdentifier]) {
        NSString *errorStr = [NSString stringWithFormat:@"Training model bundle with identifier %@ does not match requested identifier %@", self.trainingModelBundle.identifier, modelIdentifier];
        NSLog(errorStr);
        self.trainingCallback(@[errorStr, NSNull.null]);
        return nil;
    }
    
    return self.trainingModelBundle;
}

// MARK: - Batch Data Source 

- (NSArray<NSString*>*)keys {
    return [self inputKeysForModel:self.trainingModel];
}

- (NSUInteger)numberOfItems {
    return self.trainingSet.count;
}

- (TIOBatchItem*)itemAtIndex:(NSUInteger)index {
    NSDictionary* input = self.trainingSet[index];
    NSSet<NSString*> *providedKeys = [NSSet setWithArray:input.allKeys];
    
    NSSet<NSString*> *expectedKeys = [NSSet setWithArray:[self inputKeysForModel:self.trainingModel]];
    
    if (![expectedKeys isEqualToSet:providedKeys]) {
        NSString *error = [NSString stringWithFormat:@"Provided inputs %@ don't match model's expected inputs %@", providedKeys, expectedKeys];
        self.trainingCallback(@[error, NSNull.null]);
        return nil;
    }
    
    // Prepare inputs, converting base64 encoded image data or reading image data from the filesystem
    
    NSDictionary *preparedInputs = [self preparedInputs:input];
    
    if (preparedInputs == nil) {
        NSString *error = @"There was a problem preparing the inputs. Ensure that your image inputs are property encoded.";
        self.trainingCallback(@[error, NSNull.null]);
        return nil;
    }
    
    return (TIOBatchItem *)preparedInputs;
}

// MARK: - Federated Manager Delegate Methods

- (void)federatedManager:(TIOFederatedManager*)manager didBeginAction:(TIOFederatedManagerAction)action {
    NSLog(@"didBeginAction: %ld", action);
}
- (void)federatedManager:(TIOFederatedManager*)manager willBeginProcessingTaskWithId:(NSString*)taskId {
    NSLog(@"willBeginProcessingTaskWithId: %@", taskId);
}
- (void)federatedManager:(TIOFederatedManager *)manager didCompleteTaskWithId:(NSString*)taskId {
    NSLog(@"didCompleteTaskWithId: %@", taskId);
    self.trainingCallback(@[NSNull.null, NSNull.null]);
}
- (void)federatedManager:(TIOFederatedManager*)manager didFailWithError:(NSError*)error forAction:(TIOFederatedManagerAction)action {
    NSLog(@"Error: %@", error);
    self.trainingCallback(@[[error localizedDescription], NSNull.null]);
}

- (NSArray<NSString*>*)inputKeysForModel:(id<TIOModel>)model {
    NSMutableArray<NSString*> *keys = [[NSMutableArray alloc] init];
    for (TIOLayerInterface *input in model.inputs) {
        [keys addObject:input.name];
    }
    return keys.copy;
}

/**
 * Prepares the model inputs sent from javascript for inference. Image inputs
 * are encoded as a base64 string and must be decoded and converted to pixel
 * buffers. Other inputs are taken as is.
 */

- (nullable NSDictionary*)preparedInputs:(NSDictionary*)inputs {
    
    NSMutableDictionary<NSString*, id<TIOData>> *preparedInputs = [[NSMutableDictionary alloc] init];
    __block BOOL error = NO;
    
    for (TIOLayerInterface *layer in self.trainingModel.inputs) {
        [layer matchCasePixelBuffer:^(TIOPixelBufferLayerDescription * _Nonnull pixelBufferDescription) {
            TIOPixelBuffer *pixelBuffer = [self pixelBufferForInput:inputs[layer.name]];
            if (pixelBuffer == nil) {
                error = YES;
            } else {
                preparedInputs[layer.name] = pixelBuffer;
            }
        } caseVector:^(TIOVectorLayerDescription * _Nonnull vectorDescription) {
            preparedInputs[layer.name] = inputs[layer.name];
        }];
    }
    
    if (error) {
        return nil;
    }
    
    return preparedInputs.copy;
}

/**
 * Prepares a pixel buffer input given an image encoding dictionary sent from
 * javascript, converting a base64 encoded string or reading data from the file
 * system.
 */

- (nullable TIOPixelBuffer*)pixelBufferForInput:(NSDictionary*)input {
    
    RNTIOImageDataType format = (RNTIOImageDataType)[input[RNTIOImageKeyFormat] integerValue];
    CVPixelBufferRef pixelBuffer;
    
    switch (format) {
        case RNTIOImageDataTypeUnknown: {
            pixelBuffer = NULL;
        }
            break;
            
        case RNTIOImageDataTypeARGB: {
            OSType imageFormat = kCVPixelFormatType_32ARGB;
            NSUInteger width = [input[RNTIOImageKeyWidth] unsignedIntegerValue];
            NSUInteger height = [input[RNTIOImageKeyHeight] unsignedIntegerValue];
            
            NSString *base64 = input[RNTIOImageKeyData];
            NSData *data = [RCTConvert NSData:base64];
            unsigned char *bytes = (unsigned char *)data.bytes;
            
            pixelBuffer = CreatePixelBufferWithBytes(bytes, width, height, imageFormat);
            CFAutorelease(pixelBuffer);
            
        }
            break;
            
        case RNTIOImageDataTypeBGRA: {
            OSType imageFormat = kCVPixelFormatType_32BGRA;
            NSUInteger width = [input[RNTIOImageKeyWidth] unsignedIntegerValue];
            NSUInteger height = [input[RNTIOImageKeyHeight] unsignedIntegerValue];
            
            NSString *base64 = input[RNTIOImageKeyData];
            NSData *data = [RCTConvert NSData:base64];
            unsigned char *bytes = (unsigned char *)data.bytes;
            
            pixelBuffer = CreatePixelBufferWithBytes(bytes, width, height, imageFormat);
            CFAutorelease(pixelBuffer);
            
        }
            break;
            
        case RNTIOImageDataTypeJPEG: {
            NSString *base64 = input[RNTIOImageKeyData];
            UIImage *image = [RCTConvert UIImage:base64];
            
            pixelBuffer = image.pixelBuffer;
            
        }
            break;
            
        case RNTIOImageDataTypePNG: {
            NSString *base64 = input[RNTIOImageKeyData];
            UIImage *image = [RCTConvert UIImage:base64];
            
            pixelBuffer = image.pixelBuffer;
            
        }
            break;
            
        case RNTIOImageDataTypeFile: {
            NSString *path = input[RNTIOImageKeyData];
            NSURL *URL = [NSURL fileURLWithPath:path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:URL.path];
            
            pixelBuffer = image.pixelBuffer;
            
        }
            break;
    }
    
    // Bail if the pixel buffer could not be created
    
    if (pixelBuffer == NULL)  {
        return nil;
    }
    
    // Derive the image orientation
    
    CGImagePropertyOrientation orientation;
    
    if ([input objectForKey:RNTIOImageKeyOrientation] == nil) {
        orientation = kCGImagePropertyOrientationUp;
    } else {
        orientation = (CGImagePropertyOrientation)[input[RNTIOImageKeyOrientation] integerValue];
    }
    
    // Return the results
    
    return [[TIOPixelBuffer alloc] initWithPixelBuffer:pixelBuffer orientation:orientation];
}

// MARK: - Output Conversion

/**
 * Prepares the model outputs for consumption by javascript. Pixel buffer outputs
 * are converted to base64 strings. Other outputs are taken as is.
 */

- (NSDictionary*)preparedOutputs:(NSDictionary*)outputs {
    NSMutableDictionary *preparedOutputs = [[NSMutableDictionary alloc] init];
    __block BOOL error = NO;
    
    for (TIOLayerInterface *layer in self.trainingModel.outputs) {
        [layer matchCasePixelBuffer:^(TIOPixelBufferLayerDescription * _Nonnull pixelBufferDescription) {
            NSString *base64 = [self base64JPEGDataForPixelBuffer:outputs[layer.name]];
            if (base64 == nil) {
                error = YES;
            } else {
                preparedOutputs[layer.name] = base64;
            }
        } caseVector:^(TIOVectorLayerDescription * _Nonnull vectorDescription) {
            preparedOutputs[layer.name] = outputs[layer.name];
        }];
    }
    
    if (error) {
        return nil;
    }
    
    return preparedOutputs.copy;
}

/**
 * Converts a pixel buffer output to a base64 encoded string that can be
 * consumed by React Native.
 */

- (nullable NSString*)base64JPEGDataForPixelBuffer:(TIOPixelBuffer*)pixelBuffer {
    UIImage *image = [[UIImage alloc] initWithPixelBuffer:pixelBuffer.pixelBuffer];
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    
    return base64;
}

- (NSDictionary *)constantsToExport {
    return @{
             @"imageKeyData":        RNTIOImageKeyData,
             @"imageKeyFormat":      RNTIOImageKeyFormat,
             @"imageKeyWidth":       RNTIOImageKeyWidth,
             @"imageKeyHeight":      RNTIOImageKeyHeight,
             @"imageKeyOrientation": RNTIOImageKeyOrientation,
             
             @"imageTypeUnknown":    @(RNTIOImageDataTypeUnknown),
             @"imageTypeARGB":       @(RNTIOImageDataTypeARGB),
             @"imageTypeBGRA":       @(RNTIOImageDataTypeBGRA),
             @"imageTypeJPEG":       @(RNTIOImageDataTypeJPEG),
             @"imageTypePNG":        @(RNTIOImageDataTypePNG),
             @"imageTypeFile":       @(RNTIOImageDataTypeFile),
             
             @"imageOrientationUp":              @(kCGImagePropertyOrientationUp),
             @"imageOrientationUpMirrored":      @(kCGImagePropertyOrientationUpMirrored),
             @"imageOrientationDown":            @(kCGImagePropertyOrientationDown),
             @"imageOrientationDownMirrored":    @(kCGImagePropertyOrientationDownMirrored),
             @"imageOrientationLeftMirrored":    @(kCGImagePropertyOrientationLeftMirrored),
             @"imageOrientationRight":           @(kCGImagePropertyOrientationRight),
             @"imageOrientationRightMirrored":   @(kCGImagePropertyOrientationRightMirrored),
             @"imageOrientationLeft":            @(kCGImagePropertyOrientationLeft)
             };
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

@end
