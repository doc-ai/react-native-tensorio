//
//  RNPixelBufferUtilities.h
//  RNTensorIO
//
//  Created by Phil Dow on 2/1/19.
//  Copyright © 2019 doc.ai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

_Nullable CVPixelBufferRef CreatePixelBufferWithBytes(unsigned char *bytes, size_t width, size_t height, OSType format);

NS_ASSUME_NONNULL_END
