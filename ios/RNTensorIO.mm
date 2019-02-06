//
//  RNTensirIO.mm
//  RNTensorIO
//
//  Created by Phil Dow on 2/1/19.
//  Copyright © 2019 doc.ai. All rights reserved.
//

#import "RNTensorIO.h"
#import "RNPixelBufferUtilities.h"

// Unsure why the library import statement does not work:
// #import <TensorIO/TensorIO.h>

#import "TensorIO.h"

static NSString * const RNTIOImageKeyData =         @"RNTIOImageKeyData";
static NSString * const RNTIOImageKeyFormat =       @"RNTIOImageKeyFormat";
static NSString * const RNTIOImageKeyWidth =        @"RNTIOImageKeyWidth";
static NSString * const RNTIOImageKeyHeight =       @"RNTIOImageKeyHeight";
static NSString * const RNTIOImageKeyOrientation =  @"RNTIOImageKeyOrientation";

typedef NS_ENUM(NSInteger, RNTIOImageDataType) {
    RNTIOImageDataTypeUnknown,
    RNTIOImageDataTypeARGB,
    RNTIOImageDataTypeBGRA,
    RNTIOImageDataTypeJPG,
    RNTIOImageDataTypePNG,
    RNTIOImageDataTypeFile
};

// MARK: -

@implementation RCTConvert (RNTensorIOEnumerations)

RCT_ENUM_CONVERTER(RNTIOImageDataType, (@{
    @"imageTypeUnknown": @(RNTIOImageDataTypeUnknown),
    @"imageTypeARGB":    @(RNTIOImageDataTypeARGB),
    @"imageTypeBGRA":    @(RNTIOImageDataTypeBGRA),
    @"imageTypeJPG":     @(RNTIOImageDataTypeJPG),
    @"imageTypePNG":     @(RNTIOImageDataTypePNG),
    @"imageTypeFile":    @(RNTIOImageDataTypeFile)
}), RNTIOImageDataTypeUnknown, integerValue);

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

// MARK: -

@interface RNTensorIO()

@property id<TIOModel> model;

@end

@implementation RNTensorIO

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(load:(NSString*)name) {
    [self unload];
    
    if ([name.pathExtension isEqualToString:kTFModelBundleExtension]) {
        name = [name stringByDeletingPathExtension];
    }
    
    NSString *path = [NSBundle.mainBundle pathForResource:name ofType:kTFModelBundleExtension];
    TIOModelBundle *bundle = [[TIOModelBundle alloc] initWithPath:path];
    
    self.model = bundle.newModel;
}

RCT_EXPORT_METHOD(unload) {
    [self.model unload];
    self.model = nil;
}

RCT_EXPORT_METHOD(run:(NSDictionary*)inputs callback:(RCTResponseSenderBlock)callback) {
    
    // Ensure that the provided keys match the model's expected keys, or return an error
    
    NSSet<NSString*> *expectedKeys = [NSSet setWithArray:[self inputKeysForModel:self.model]];
    NSSet<NSString*> *providedKeys = [NSSet setWithArray:inputs.allKeys];
    
    if (![expectedKeys isEqualToSet:providedKeys]) {
        NSString *error = [NSString stringWithFormat:@"Provided inputs %@ don't match model's expected inputs %@", providedKeys, expectedKeys];
        callback(@[error, NSNull.null]);
        return;
    }
    
    // Prepare inputs, converting byte64 encoded pixel buffers or reading image data from the filesystem
    
    NSDictionary *preparedInputs = [self preparedInputs:inputs];
    
    // Perform inference
    
    NSDictionary *results = (NSDictionary*)[self.model runOn:preparedInputs];
    
    // TODO: convert image outputs to byte64 data
    
    // Return results
    
    callback(@[NSNull.null, results]);
}

RCT_EXPORT_METHOD(topN:(NSUInteger)count threshold:(float)threshold classifications:(NSDictionary*)classifications callback:(RCTResponseSenderBlock)callback) {
    NSDictionary *topN = [classifications topN:count threshold:threshold];
    callback(@[NSNull.null, topN]);
}

// MARK: - Input Key Checking

- (NSArray<NSString*>*)inputKeysForModel:(id<TIOModel>)model {
    NSMutableArray<NSString*> *keys = [[NSMutableArray alloc] init];
    for (TIOLayerInterface *input in model.inputs) {
        [keys addObject:input.name];
    }
    return keys.copy;
}

// MARK: - Input Conversion

- (NSDictionary*)preparedInputs:(NSDictionary*)inputs {
    
    // Convert pixel buffer inputs, supporting ARGB/BGRA, PNG, and JPG byte conversions as well as filesystem paths
    // Pass other data through
    
    NSMutableDictionary<NSString*, id<TIOData>> *preparedInputs = [[NSMutableDictionary alloc] init];
    
    for (TIOLayerInterface *layer in self.model.inputs) {
        [layer matchCasePixelBuffer:^(TIOPixelBufferLayerDescription * _Nonnull pixelBufferDescription) {
            preparedInputs[layer.name] = [self pixelBufferForInput:inputs[layer.name]];
        } caseVector:^(TIOVectorLayerDescription * _Nonnull vectorDescription) {
            preparedInputs[layer.name] = inputs[layer.name];
        }];
    }
    
    return preparedInputs.copy;
}

- (TIOPixelBuffer*)pixelBufferForInput:(NSDictionary*)input {
    
    // Converts byte64 encoded image data or reads image data from the file system
    
    RNTIOImageDataType format = (RNTIOImageDataType)[input[RNTIOImageKeyFormat] integerValue];
    CVPixelBufferRef pixelBuffer;
    
    switch (format) {
    case RNTIOImageDataTypeUnknown: {
        // TODO: raise an error
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
        
    case RNTIOImageDataTypeJPG: {
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
    
    // TODO: raise an error if pixelbuffer is null
    
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

// MARK: -

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
        @"imageTypeJPG":        @(RNTIOImageDataTypeJPG),
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

@end
