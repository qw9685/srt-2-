//
//  ViewController.m
//  视频字幕
//
//  Created by cc on 2019/12/11.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ViewController.h"
#import "ccSubtitleConfig.h"
#import <AVKit/AVKit.h>
#import "ccSubtitleComposition.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    ccSubtitleConfig* config = [[ccSubtitleConfig alloc] init];
    config.inputPath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1.mp4" ofType:nil]];
    config.outputPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/cache.mp4",[self dirDoc]]];
    config.array_subtitles = [self getVideoSubtitles:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"srt"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:config.outputPath.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:config.outputPath error:nil];
    }
    [ccSubtitleComposition addSubtitles:config handleBlock:^(bool success) {
        
        NSLog(@"成功");
        
        NSURL* path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/cache.mp4",[self dirDoc]]];
        [self playVideoWithUrl:path];
        
    } progressBlock:^(CGFloat progress) {
        NSLog(@"==加载字幕%f",progress);
    }];    
}

-(void)playVideoWithUrl:(NSURL *)url{
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
    playerViewController.player = [[AVPlayer alloc]initWithURL:url];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    [self.navigationController pushViewController:playerViewController animated:YES];
}

//解析srt字幕
-(NSArray*)getVideoSubtitles:(NSString*)srtPath{
    
    NSString *content = [[NSString alloc] initWithContentsOfFile:srtPath encoding:NSUTF8StringEncoding error:nil];
    return [self setSrt:content];
    
}
// 设置字幕字符串
- (NSArray*)setSrt:(NSString *)srt {
    // 去除\t\r
    NSString *lyric = [NSString stringWithString:srt];
    lyric = [lyric stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    lyric = [lyric stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    NSArray *arr = [lyric componentsSeparatedByString:@"\n"];
    
    NSMutableArray *tempArr = [NSMutableArray new]; // 存放Item的数组
    NSMutableDictionary *itemDic = [NSMutableDictionary dictionary]; // 存放歌词信息的Item
    
    __block NSInteger i = 0; // 标记， 0：序号  1: 时间   2:英文    3:中文
    for (NSString *str in arr) {
        @autoreleasepool {
            NSString *tempStr = [NSString stringWithString:str];
            tempStr = [tempStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (tempStr.length > 0) {
                switch (i) {
                    case 0:
                        [itemDic setObject:tempStr forKey:@"index"];
                        break;
                    case 1:{
                        //时间
                        NSRange range2 = [tempStr rangeOfString:@"-->"];
                        if (range2.location != NSNotFound) {
                            NSString *beginstr = [tempStr substringToIndex:range2.location];
                            beginstr = [beginstr stringByReplacingOccurrencesOfString:@" " withString:@""];
                            NSArray * arr = [beginstr componentsSeparatedByString:@":"];
                            if (arr.count == 3) {
                                NSArray * arr1 = [arr[2] componentsSeparatedByString:@","];
                                if (arr1.count == 2) {
                                    //将开始时间数组中的时间换化成秒为单位的
                                    CGFloat start = [arr[0] floatValue] * 60*60 + [arr[1] floatValue]*60 + [arr1[0] floatValue] + [arr1[1] floatValue]/1000;
                                    [itemDic setObject:@(start) forKey:@"begin"];
                                    
                                    NSString *endstr = [tempStr substringFromIndex:range2.location+range2.length];
                                    endstr = [endstr stringByReplacingOccurrencesOfString:@" " withString:@""];
                                    NSArray * array = [endstr componentsSeparatedByString:@":"];
                                    if (array.count == 3) {
                                        NSArray * arr2 = [array[2] componentsSeparatedByString:@","];
                                        if (arr2.count == 2) {
                                            //将结束时间数组中的时间换化成秒为单位的
                                            CGFloat end = [array[0] floatValue] * 60*60 + [array[1] floatValue]*60 + [arr2[0] floatValue] + [arr2[1] floatValue]/1000;
                                            [itemDic setObject:@(end) forKey:@"end"];
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
                    case 2:
                        [itemDic setObject:tempStr forKey:@"subtitle"];
                        break;
                        //                    case 3: {
                        //                        [itemDic setObject:tempStr forKey:@"en"];
                        //                        break;
                        //                    }
                    default:
                        break;
                }
                i ++;
            }else {
                // 遇到空行，就添加到数组
                i = 0;
                NSDictionary *dic = [NSDictionary dictionaryWithDictionary:itemDic];
                [tempArr addObject:dic];
                [itemDic removeAllObjects];
            }
        }
    }
    return tempArr;
}


//转换时间 ms
- (CGFloat)dateFormTime:(NSString*)time{
    NSArray* times = [time componentsSeparatedByString:@":"];
    NSString* ms = [times[2] stringByReplacingOccurrencesOfString:@"," withString:@""];
    return [times[0] floatValue]*60*60*1000 + [times[1] floatValue]*60*1000 + [ms floatValue];
}

//获取Documents目录
-(NSString *)dirDoc{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

@end
