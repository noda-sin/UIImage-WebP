// Copyright 2010 Google Inc.
//
// This code is licensed under the same terms as WebM:
//  Software License Agreement:  http://www.webmproject.org/license/software/
//  Additional IP Rights Grant:  http://www.webmproject.org/license/additional/
// -----------------------------------------------------------------------------
//
//  WebPImageData.m
//  ViewWebP
//
//  Created by Somnath Banerjee (somnath@google.com)
//  Copyright 2011 Google Inc. All rights

#import "UIImage+WebP.h"
#import "WebP/decode.h"

@implementation UIImage (WebP)

static const int kWPUseThreads = 1;

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size) {
    free((void*)data);
}

- (id)initWithWebPData:(NSData *)data {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    
    config.output.colorspace = MODE_rgbA;
    config.options.use_threads = kWPUseThreads;
    
    if (WebPDecode([data bytes], [data length], &config) != VP8_STATUS_OK) {
        return nil;
    }
    
    int width = (&config)->input.width;
    int height = (&config)->input.height;
    if ((&config)->options.use_scaling) {
        width = (&config)->options.scaled_width;
        height = (&config)->options.scaled_height;
    }
    
    // Construct a UIImage from the decoded RGBA value array.
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, (&config)->output.u.RGBA.rgba,
                                 (&config)->output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef =
    CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo,
                  provider, NULL, NO, renderingIntent);
    
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    self = [self initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return self;
}

+ imageWithWebPData:(NSData *)data {
    return [[self alloc] initWithWebPData:data];
}

@end
