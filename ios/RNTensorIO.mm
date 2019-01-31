
#import "RNTensorIO.h"

// Unsure why the library import statement does not work:
// #import <TensorIO/TensorIO.h>

#import "TensorIO.h"

@interface RNTensorIO()

@property id<TIOModel> model;

@end

// MARK: -

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
    
    // TODO: convert pixel buffer inputs
    // TODO: error handling
    
    NSDictionary *results = (NSDictionary*)[self.model runOn:input];
    callback(@[NSNull.null, results]);
}

// MARK: -

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

@end
