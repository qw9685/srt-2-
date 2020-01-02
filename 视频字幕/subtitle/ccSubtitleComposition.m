//
//  ccSubtitleComposition.m
//  视频字幕
//
//  Created by cc on 2019/12/24.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ccSubtitleComposition.h"
#import <AVFoundation/AVFoundation.h>

@implementation ccSubtitleComposition


+ (void)addSubtitles:(ccSubtitleConfig*)config handleBlock:(void(^)(bool success))handleBlock progressBlock:(void(^)(CGFloat progress))progressBlock
{
 
    AVAsset* asset = [AVAsset assetWithURL:config.inputPath];
    
    //时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), asset.duration);

    //AVMutableComposition 用来加载轨道/naturalSize
    AVMutableComposition *mix = [AVMutableComposition composition];
    
    //音视频采集通道
    AVAssetTrack * videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack * audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    //视频轨道
    AVMutableCompositionTrack *videoTrack = [mix addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //加载视频轨道
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];

    //音频轨道
    AVMutableCompositionTrack *audioTrack = [mix addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //加载音频轨道
    [audioTrack insertTimeRange:videoTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //输出对象
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mix presetName:AVAssetExportPreset3840x2160];

    //视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = videoTimeRange;
    
    //视频轨道中的一个视频图层
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    //设置视频的旋转角度,否则可能输出的视频会旋转
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:asset.duration];
    
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

    //用来管理视频中的所有视频轨道
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    //根据视频中的naturalSize及获取到的视频旋转角度是否是竖屏来决定输出的视频图层的横竖屏
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
    } else {
        naturalSize = videoTrack.naturalSize;
    }
    
    //设置分辨率
    mainCompositionInst.renderSize = naturalSize;
    //可加载多个轨道
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    //设置视频帧率
    mainCompositionInst.frameDuration = CMTimeMake(1,30);
    mainCompositionInst.renderScale = 1.0;
    
    //这里的parentLayer可以加载字幕的layer
    [ccSubtitleComposition addSubtitles:config.array_subtitles naturalSize:naturalSize mainCompositionInst:mainCompositionInst];
    
    //exporter设置
    exporter.outputURL = config.outputPath;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;//适合网络传输
    exporter.videoComposition = mainCompositionInst;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            handleBlock(exporter.status == AVAssetExportSessionStatusCompleted);
            
            switch (exporter.status)
            {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"Unknown");
                    break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"Waiting");
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"Exporting");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Created new water mark image");
                    
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Failed- %@", exporter.error);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Cancelled");
                    break;
            }
        });
    }];
}

+ (void)addSubtitles:(NSArray*)subtitles naturalSize:(CGSize)naturalSize mainCompositionInst:(AVMutableVideoComposition*)mainCompositionInst{
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    
    //开始添加字幕图层
    [subtitles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        float begin = [subtitles[idx][@"begin"] floatValue];
        float end = [subtitles[idx][@"end"] floatValue];
        NSString* subtitle = subtitles[idx][@"subtitle"];
        
        CATextLayer * textLayer = [CATextLayer layer];
        textLayer.opacity = 0;//优先透明
        textLayer.backgroundColor = [UIColor redColor].CGColor;
        textLayer.string = subtitle;
        textLayer.frame = CGRectMake(0, 0, naturalSize.width, 80);
        textLayer.alignmentMode = kCAAlignmentCenter;
        //添加动画
        [textLayer addAnimation:[ccSubtitleComposition addAnimationWithBegin:begin end:end] forKey:@"animateOpacity"];
        [parentLayer addSublayer:textLayer];
        mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
                                             videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }];
}

//文字动画
+ (CABasicAnimation*)addAnimationWithBegin:(float)begin end:(float)end{

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation setDuration:end - begin];
    [animation setFromValue:[NSNumber numberWithFloat:1.0]];
    [animation setToValue:[NSNumber numberWithFloat:1.0]];
    [animation setBeginTime: begin];
    [animation setRemovedOnCompletion:NO];

    return animation;
}

@end
