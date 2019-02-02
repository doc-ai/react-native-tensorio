
#import "RNTensorIO.h"

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

RCT_EXPORT_METHOD(run:(NSDictionary*)input callback:(RCTResponseSenderBlock)callback) {
    
    // Ensure that the provided keys match the model's expected keys, or return an error
    
    NSSet<NSString*> *expectedKeys = [NSSet setWithArray:[self inputKeysForModel:self.model]];
    NSSet<NSString*> *providedKeys = [NSSet setWithArray:input.allKeys];
    
    if (![expectedKeys isEqualToSet:providedKeys]) {
        NSString *error = [NSString stringWithFormat:@"Provided inputs %@ don't match model's expected inputs %@", providedKeys, expectedKeys];
        callback(@[error, NSNull.null]);
        return;
    }
    
    // TODO: convert pixel buffer inputs
    
    // Perform inference and return results
    
    NSDictionary *results = (NSDictionary*)[self.model runOn:input];
    callback(@[NSNull.null, results]);
}

// MARK: -

- (NSArray<NSString*>*)inputKeysForModel:(id<TIOModel>)model {
    NSMutableArray<NSString*> *keys = [[NSMutableArray alloc] init];
    for (TIOLayerInterface *input in model.inputs) {
        [keys addObject:input.name];
    }
    return keys.copy;
}

// MARK: -

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

@end
