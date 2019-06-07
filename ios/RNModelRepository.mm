#import "RNModelRepository.h"
#import "RNPixelBufferUtilities.h"

#import "TIOModelRepositoryClient.h"
#import "TIOModelBundle.h"
#import "TIOModelUpdater.h"
#import "TIOMRClientSessionDelegate.h"
#import "TIOModelUpdaterDelegate.h"

@interface RNModelRepository() <TIOModelUpdaterDelegate>

@property TIOModelRepositoryClient* repositoryClient;
@property TIOModelUpdater* updater;

@end

@implementation RNModelRepository

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSString*)baseUrl authToken:(NSString*)authToken callback:(RCTResponseSenderBlock)callback) {
    NSURL *URL = [NSURL URLWithString:baseUrl];
    
    // API Session Configfuration
    
    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.defaultSessionConfiguration;
    configuration.HTTPAdditionalHeaders = @{
        @"Authorization": authToken
    };
    
    NSURLSession *URLSession = [NSURLSession sessionWithConfiguration:configuration];
    
    // Download Session Configuration
    
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:TIOModelRepositoryClient.backgroundSessionIdentifier];
    TIOMRClientSessionDelegate *delegate = [[TIOMRClientSessionDelegate alloc] init];
    NSURLSession *downloadSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:delegate delegateQueue:nil];
    
    // Set Up Client
    
    self.repositoryClient = [[TIOModelRepositoryClient alloc] initWithBaseURL:URL session:URLSession downloadSession:downloadSession];
    
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
    self.updater.delegate = self;
    
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
    self.updater.delegate = self;

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

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"DownloadProgress"];
}


// MARK: - TIOModelUpdaterDelegate

- (void)modelUpdater:(TIOModelRepositoryClient*)client didProgress:(float)progress {
    [self sendEventWithName:@"DownloadProgress" body:@{@"progress": @(progress)}];
}

@end
