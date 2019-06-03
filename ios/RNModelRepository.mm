#import "RNModelRepository.h"
#import "RNPixelBufferUtilities.h"

#import "TIOModelRepositoryClient.h"
#import "TIOModelBundle.h"
#import "TIOModelUpdater.h"

@interface RNModelRepository()

@property TIOModelRepositoryClient* repositoryClient;
@property TIOModelUpdater* updater;

@end

@implementation RNModelRepository

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSString*)baseUrl authToken:(NSString*)authToken callback:(RCTResponseSenderBlock)callback) {
    NSURL *URL = [NSURL URLWithString:baseUrl];
    
    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.defaultSessionConfiguration;
    configuration.HTTPAdditionalHeaders = @{
        @"Authorization": authToken
    };
    
    NSURLSession *URLSession = [NSURLSession sessionWithConfiguration:configuration];
    
    self.repositoryClient = [[TIOModelRepositoryClient alloc] initWithBaseURL:URL session:URLSession downloadSession:nil];
    
    [self.repositoryClient GETHealthStatus:^(TIOMRStatus * _Nullable response, NSError * _Nonnull error) {
        if (error) {
            callback(@[[error localizedDescription], NSNull.null]);
            return;
        }
        
        callback(@[NSNull.null, @(YES)]);
    }];
}

RCT_EXPORT_METHOD(checkForModelUpdate:(NSString*)pathToFile callback:(RCTResponseSenderBlock)callback) {
    //Get model bundle from url
    TIOModelBundle *bundle = [[TIOModelBundle alloc] initWithPath:pathToFile];
    
    //Use updator to actually update model
    self.updater = [[TIOModelUpdater alloc] initWithModelBundle:bundle repository:self.repositoryClient];
    
    [self.updater checkForUpdate:^(BOOL updateAvailable, NSError * _Nullable error) {
        if (error != nil) {
            callback(@[[error localizedDescription], NSNull.null]);
            return;
        }
        
        callback(@[NSNull.null, @(updateAvailable)]);
        
        // Free the updater reference, so we can call updateModel again
        self.updater = nil;
    }];
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
    self.updater = [[TIOModelUpdater alloc] initWithModelBundle:bundle repository:self.repositoryClient];

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
