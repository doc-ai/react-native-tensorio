
#import "RNModelRepository.h"
#import "RNPixelBufferUtilities.h"

#import "TIOModelRepository.h"
#import "TIOModelBundle.h"
#import "TIOModelUpdater.h"

@interface RNModelRepository()

@property TIOModelRepository* repository;

@end

@implementation RNModelRepository

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSString*)baseUrl) {
    NSURL *URL = [NSURL URLWithString:baseUrl];
    self.repository = [[TIOModelRepository alloc] initWithBaseURL:URL session:nil];
}

RCT_EXPORT_METHOD(updateModel:(NSString*)pathToFile callback:(RCTResponseSenderBlock)callback) {
    //Get model bundle from url
    TIOModelBundle *bundle = [[TIOModelBundle alloc] initWithPath:pathToFile];

    //Use updator to actually update model
    TIOModelUpdater *updater = [[TIOModelUpdater alloc] initWithModelBundle:bundle repository:self.repository];
    [updater updateWithValidator:nil callback:^(BOOL updated, NSURL * _Nullable updatedBundleURL, NSError * _Nullable error) {
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        [result setValue:@(updated) forKey:@"updated"];
        [result setValue:updatedBundleURL forKey:@"updatedBundleURL"];
        return callback(@[error, result]);
    }];
}

@end

