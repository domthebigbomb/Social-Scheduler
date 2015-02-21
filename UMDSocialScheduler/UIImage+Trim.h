//
//  UIImage+Trim.h
//  UMDSocialScheduler
//
//  Created by Dominic Ong on 2/20/15.
//  Copyright (c) 2015 DTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Trim)

- (UIEdgeInsets)transparencyInsetsRequiringFullOpacity:(BOOL)fullyOpaque;
- (UIImage *)imageByTrimmingTransparentPixels;
- (UIImage *)imageByTrimmingTransparentPixelsRequiringFullOpacity:(BOOL)fullyOpaque;
- (UIImage *)imageByTrimmingWhitePixelsWithOpacity:(UInt8)tolerance;

@end