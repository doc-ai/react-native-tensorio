#import "RNModelRepository.h"
#import "RNPixelBufferUtilities.h"

#import "TIOModelRepository.h"
#import "TIOModelBundle.h"
#import "TIOModelUpdater.h"

@interface RNModelRepository()

@property TIOModelRepository* repository;
@property TIOModelUpdater* updater;

@end

@implementation RNModelRepository

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSString*)baseUrl) {
    NSURL *URL = [NSURL URLWithString:baseUrl];
    self.repository = [[TIOModelRepository alloc] initWithBaseURL:URL session:nil];
}

RCT_EXPORT_METHOD(updateModel:(NSString*)pathToFile callback:(RCTResponseSenderBlock)callback) {
    // Prevent multiple calls to this method
    if (self.updater != nil) {
        callback(@[@"updateModel is already running.", NSNull.null]);
        return;
    }
    
    //Get model bundle from url
    TIOModelBundle *bundle = [[TIOModelBundle alloc] initWithPath:pathToFile];

    //Use updator to actually update model
    self.updater = [[TIOModelUpdater alloc] initWithModelBundle:bundle repository:self.repository];

    [self.updater updateWithValidator:nil callback:^(BOOL updated, NSURL * _Nullable updatedBundleURL, NSError * _Nullable error) {
        if (error != nil) {
            callback(@[[error localizedDescription], NSNull.null]);
            return;
        }
        
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        
        [result setValue:@(updated) forKey:@"updated"];
        [result setValue:updatedBundleURL forKey:@"updatedBundleURL"];
        
        callback(@[NSNull.null, result]);
        
        // Free the updater reference, so we can call updateModel again
        self.updater = nil;
    }];
}

@end
