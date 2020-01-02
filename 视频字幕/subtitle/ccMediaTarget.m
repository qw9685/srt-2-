//
//  FMediaTarget.m
//  FVideo
//
//  Created by wangxiang on 19-12-12.
//  Copyright (c) 2019年 cuichang. All rights reserved.
//

#import "ccMediaTarget.h"

typedef struct {
    CVPixelBufferRef frameData;
    CMTime frameTime;
    int frameIndex;
    
} VideoFrameData;

@interface ccMediaTarget ()

@end

@implementation ccMediaTarget {
    AVAssetWriter *_writer;
    AVAssetWriterInput *_audio_track_input;
    AVAssetWriterInput *_video_track_input;
    AVAssetWriterInputPixelBufferAdaptor *_pixel_buffer_adaptor;
    int _width;
    int _height;
    int _frameIndex;
    dispatch_queue_t _writeFileQueue;
    NSMutableArray *_videoFrameQueue;
     CGSize _naturalSize;
    
}

- (id)initWithURL:(NSURL *)outputURL fileType:(NSString *)outputFileType VideoNaturalSize:(CGSize)naturalSize{
    NSError *error = nil;
    _videoFrameQueue = [[NSMutableArray alloc] init];
    
    _naturalSize = naturalSize;

    _width = _naturalSize.width;
    _height = _naturalSize.height;
    
    _writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:outputFileType error:&error];
    
    [self createAudioTrack];
    [self createVideoTrack];
    
    [_writer startWriting];
    [_writer startSessionAtSourceTime:kCMTimeZero];
    
    _writeFileQueue = dispatch_queue_create("com.feinno.writevideo", nil);
    
    [_video_track_input requestMediaDataWhenReadyOnQueue:_writeFileQueue usingBlock:^{

        NSInteger count = [_videoFrameQueue count];
        
        if(_video_track_input.readyForMoreMediaData && count) {
            VideoFrameData frameData = {0};
            [[_videoFrameQueue objectAtIndex:0] getValue:&frameData];
            
            if (frameData.frameData) {
                
                @try
                {
                    [_pixel_buffer_adaptor appendPixelBuffer:frameData.frameData
                                        withPresentationTime:frameData.frameTime];
                    CVPixelBufferRelease(frameData.frameData);

                }
                @catch (NSException *exception)
                {
                    if (self.failBlock) {
                        self.failBlock();
                    }
                }

            } else {

                [_video_track_input markAsFinished];
                
                [_writer finishWritingWithCompletionHandler:^(void){

                }];
            }
            
            [_videoFrameQueue removeObjectAtIndex:0];
            
        } else {

            usleep(10000);
        }
        
    }];
    
    return self;
}

- (void)pushAudioSample:(CMSampleBufferRef)sample {
    if (_audio_track_input.readyForMoreMediaData) {
        [_audio_track_input appendSampleBuffer:sample];
        
    } else {
        NSLog(@"skip audio sample");
    }
}

- (void)pushPixelBuffer:(CVPixelBufferRef)frame withPresentationTime:(CMTime)tm {
    
    dispatch_sync(_writeFileQueue, ^{
        CVPixelBufferRef tmpBuffer = nil;
        CVPixelBufferPoolCreatePixelBuffer(nil, _pixel_buffer_adaptor.pixelBufferPool, &tmpBuffer);
        
        CVPixelBufferLockBaseAddress(frame, 0);
        CVPixelBufferLockBaseAddress(tmpBuffer, 0);
        
        char *frameData = CVPixelBufferGetBaseAddress(frame);
        char *tmpData = CVPixelBufferGetBaseAddress(tmpBuffer);
        size_t tmpDataSize = CVPixelBufferGetDataSize(tmpBuffer);
        memcpy(tmpData, frameData, tmpDataSize);
        
        CVPixelBufferUnlockBaseAddress(tmpBuffer, 0);
        CVPixelBufferUnlockBaseAddress(frame, 0);
        
        VideoFrameData tmpFrameData = {0};
        tmpFrameData.frameTime = tm;
        tmpFrameData.frameIndex = _frameIndex++;
        tmpFrameData.frameData = tmpBuffer;
        
//        if (_videoFrameQueue.count>1 && _videoFrameQueue!=nil) {
//            
//            [_video_track_input markAsFinished];
//            
//            [_writer finishWritingWithCompletionHandler:^(void){
//                
//                
//            }];
//            
//            self.doneBlock();
//            
//        }else{
        
            [_videoFrameQueue addObject:[NSValue value:&tmpFrameData withObjCType:@encode(VideoFrameData)]];
//            NSLog(@"========%lu",(unsigned long)_videoFrameQueue.count);
//        }
        
    });
}

- (void)close {
    //[_writer finishWritingWithCompletionHandler:^(void){}];
    [self closeVideoTrack];
}

- (void)closeVideoTrack {
    
    dispatch_sync(_writeFileQueue, ^{
        VideoFrameData tmpFrameData = {0};
        [_videoFrameQueue addObject:[NSValue value:&tmpFrameData withObjCType:@encode(VideoFrameData)]];
    });
}

- (void)createAudioTrack {
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *settings = @{
                               AVFormatIDKey :          @(kAudioFormatMPEG4AAC),
                               AVNumberOfChannelsKey :  @(2),
                               AVSampleRateKey :        @(44100),
                               AVEncoderBitRateKey :    @(64000),
                               AVChannelLayoutKey :     [NSData dataWithBytes:&acl length:sizeof(acl)]
                               };
    _audio_track_input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                            outputSettings:settings];
    [_writer addInput:_audio_track_input];
}

- (void)createVideoTrack {
    NSDictionary *settings = @{
                               AVVideoCodecKey :  AVVideoCodecH264,
                               AVVideoWidthKey :  @(_width),
                               AVVideoHeightKey : @(_height)
                               };
    _video_track_input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                    outputSettings:settings];
    _video_track_input.expectsMediaDataInRealTime = YES;
    
    [_writer addInput:_video_track_input];
    
    NSDictionary *buffer_attributes = @{
                        (id)kCVPixelBufferPixelFormatTypeKey :    @(kCVPixelFormatType_32BGRA),
                        (id)kCVPixelBufferWidthKey :              @(_width),
                        (id)kCVPixelBufferHeightKey :             @(_height),
                        (id)kCVPixelFormatOpenGLESCompatibility : @(NO)};
    _pixel_buffer_adaptor = [AVAssetWriterInputPixelBufferAdaptor
                             assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_video_track_input
                                                        sourcePixelBufferAttributes:buffer_attributes];
}

@end
