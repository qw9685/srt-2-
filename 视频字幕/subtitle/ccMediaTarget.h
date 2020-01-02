//
//  FMediaTarget.h
//  FVideo
//
//  Created by wangxiang on 19-12-12.
//  Copyright (c) 2019年 cuichang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreMedia/CoreMedia.h>

@interface ccMediaTarget : NSObject

- (id)initWithURL:(NSURL *)outputURL fileType:(NSString *)outputFileType VideoNaturalSize:(CGSize)naturalSize;
                                                                                                                                                     
- (void)close;

- (void)pushAudioSample:(CMSampleBufferRef)sample;
- (void)pushPixelBuffer:(CVPixelBufferRef)frame withPresentationTime:(CMTime)tm;

@property (nonatomic, copy) void(^failBlock)(void);

@end
