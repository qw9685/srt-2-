//
//  FMediaSource.h
//  FVideo
//
//  Created by cuichang on 19-12-12.
//  Copyright (c) 2019年 cuichang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ccMediaSource : NSObject

@property(readonly) NSURL *sourceVideoURL;
@property(readonly) int durationMiliSecond;

- (id)initWithURL:(NSURL *)url setBGRA32Pixel:(BOOL)isRGB;
- (CMSampleBufferRef)nextVideoSample;
- (CMSampleBufferRef)nextAudioSample;
- (void)close;

@end
