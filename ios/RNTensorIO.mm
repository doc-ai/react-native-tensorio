
#import "RNTensorIO.h"

// Unsure why the library import statement does not work:
// #import <TensorIO/TensorIO.h>

#import "TensorIO.h"

@implementation RNTensorIO

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

@end
  
