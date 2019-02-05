//
//  RNPixelBufferUtilities.mm
//  RNTensorIO
//
//  Created by Phil Dow on 2/1/19.
//  Copyright © 2019 doc.ai. All rights reserved.
//

#import "RNPixelBufferUtilities.h"

// Format must be kCVPixelFormatType_32ARGB or kCVPixelFormatType_32BGRA
// You must call CFRelease on the pixel buffer

_Nullable CVPixelBufferRef CreatePixelBufferWithBytes(unsigned char *bytes, size_t width, size_t height, OSType format) {
    size_t bytes_per_row = width * 4; // ARGB and BGRA are four channel formats
    size_t byte_count = height * bytes_per_row;
    
    CVPixelBufferRef pixelBuffer;
    
    CVReturn status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        format,
        NULL,
        &pixelBuffer);
    
    if ( status != kCVReturnSuccess ) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kNilOptions);
    unsigned char *base_address = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    memcpy(base_address, bytes, byte_count);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kNilOptions);
    
    return pixelBuffer;
}
