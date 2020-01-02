//
//  FMediaSource.m
//  FVideo
//
//  Created by cuichang on 19-12-12.
//  Copyright (c) 2019年 cuichang. All rights reserved.
//

#import "ccMediaSource.h"

@implementation ccMediaSource {
    AVAsset *_asset;
    AVAssetReader *_reader;
    AVAssetReaderTrackOutput *_video_track_output;
    AVAssetReaderTrackOutput *_audio_track_output;
}

- (id)initWithURL:(NSURL *)url setBGRA32Pixel:(BOOL)isRGB {
    if(!(self = [super init])) {
        return nil;
    }
    _sourceVideoURL = url;
    NSError *error = nil;
    _asset = [[AVURLAsset alloc] initWithURL:_sourceVideoURL options:nil];
    _reader = [AVAssetReader assetReaderWithAsset:_asset error:&error];
    
    CMTime duration = [_asset duration];
    _durationMiliSecond = (int) (duration.value * 1000 / duration.timescale);
    
    [self openAudio];
    [self openVideo:isRGB];
    [_reader startReading];
    return self;
}

- (void)openAudio {
    NSArray *audio_tracks = [_asset tracksWithMediaType:AVMediaTypeAudio];
    if ([audio_tracks count]) {
        _audio_track_output =
            [AVAssetReaderTrackOutput
                assetReaderTrackOutputWithTrack:audio_tracks[0]
             outputSettings:@{AVFormatIDKey: @(kAudioFormatLinearPCM)}];
             
        _audio_track_output.alwaysCopiesSampleData = NO;
    }
    if(_audio_track_output) [_reader addOutput:_audio_track_output];
}

- (void)openVideo:(BOOL)isRGB {
    NSArray *video_tracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    if ([video_tracks count]) {
        int pixelFormat = 0;
        if (isRGB) {
            pixelFormat = kCVPixelFormatType_32BGRA;
            
        } else {
            pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        }
        NSDictionary *setting = @{(id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat)};
        
        _video_track_output =
            [AVAssetReaderTrackOutput
                assetReaderTrackOutputWithTrack:video_tracks[0]
                                 outputSettings:setting];
        _video_track_output.alwaysCopiesSampleData = NO;
    }
    
    if(_video_track_output) [_reader addOutput:_video_track_output];
}

- (CMSampleBufferRef)nextAudioSample {
    if (!_audio_track_output) {
        return nil;
    }
    
    return [_audio_track_output copyNextSampleBuffer];
}

- (CMSampleBufferRef)nextVideoSample {
    if (!_video_track_output) {
        return nil;
    }

    return [_video_track_output copyNextSampleBuffer];
}

- (void)close {
    [_reader cancelReading];
}

@end
