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

@interface RNTensorIO()

@property id<TIOModel> model;

@end

@implementation RNTensorIO

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(load:(NSString*)name) {
    [self unload];
    
    if ([name.pathExtension isEqualToString:@"tfbundle"]) {
        name = [name stringByDeletingPathExtension];
    }
    
    NSString *path = [NSBundle.mainBundle pathForResource:name ofType:@"tfbundle"];
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
    
    // Return results
    
    callback(@[NSNull.null, results]);
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
    
    NSString *format = input[@"format"];
    CVPixelBufferRef pixelBuffer;
    
    if ([format isEqualToString:@"ARGB"]) {
        OSType imageFormat = kCVPixelFormatType_32ARGB;
        NSUInteger width = [input[@"width"] unsignedIntegerValue];
        NSUInteger height = [input[@"height"] unsignedIntegerValue];
        
        NSString *base64 = input[@"data"];
        NSData *data = [RCTConvert NSData:base64];
        unsigned char *bytes = (unsigned char *)data.bytes;
        
        pixelBuffer = CreatePixelBufferWithBytes(bytes, width, height, imageFormat);
        CFAutorelease(pixelBuffer);
        
    } else if ([format isEqualToString:@"BGRA"]) {
        OSType imageFormat = kCVPixelFormatType_32BGRA;
        NSUInteger width = [input[@"width"] unsignedIntegerValue];
        NSUInteger height = [input[@"height"] unsignedIntegerValue];
        
        NSString *base64 = input[@"data"];
        NSData *data = [RCTConvert NSData:base64];
        unsigned char *bytes = (unsigned char *)data.bytes;
        
        pixelBuffer = CreatePixelBufferWithBytes(bytes, width, height, imageFormat);
        CFAutorelease(pixelBuffer);
        
    } else if ([format isEqualToString:@"JPG"]) {
        NSString *base64 = input[@"data"];
        NSData *data = [RCTConvert NSData:base64];
        UIImage *image = [[UIImage alloc] initWithData:data];
        
        pixelBuffer = image.pixelBuffer;
        
    } else if ([format isEqualToString:@"PNG"]) {
        NSString *base64 = input[@"data"];
        NSData *data = [RCTConvert NSData:base64];
        UIImage *image = [[UIImage alloc] initWithData:data];
        
        pixelBuffer = image.pixelBuffer;
    
    } else if ([format isEqualToString:@"FILE"]) {
        NSString *path = input[@"data"];
        NSURL *URL = [NSURL fileURLWithPath:path];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:URL.path];
        
        pixelBuffer = image.pixelBuffer;
        
    } else  {
        // TODO: return an error or raise an exception
    }
    
    // Derive the image orientation
    
    CGImagePropertyOrientation orientation = [self orientationForString:input[@"orientation"]];
    
    // Return the results
    
    return [[TIOPixelBuffer alloc] initWithPixelBuffer:pixelBuffer orientation:orientation];
}

- (CGImagePropertyOrientation)orientationForString:(nullable NSString*)string {
    CGImagePropertyOrientation orientation;
    
    if (string == nil) {
        orientation = kCGImagePropertyOrientationUp;
    } else if ([string isEqualToString:@"UP"]) {
        orientation = kCGImagePropertyOrientationUp;
    } else if ([string isEqualToString:@"DOWN"]) {
        orientation = kCGImagePropertyOrientationDown;
    } else if ([string isEqualToString:@"LEFT"]) {
        orientation = kCGImagePropertyOrientationLeft;
    } else if ([string isEqualToString:@"RIGHT"]) {
        orientation = kCGImagePropertyOrientationRight;
    } else {
        // TODO: return an error or raise an exception
    }
    
    return orientation;
}

// MARK: -

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

@end
