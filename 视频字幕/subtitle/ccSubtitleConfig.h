//
//  ccSubtitleConfig.h
//  视频字幕
//
//  Created by cc on 2019/12/11.
//  Copyright © 2019 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ccSubtitleConfig : NSObject

@property (nonatomic,strong) NSURL *inputPath;//视频输入路径
@property (nonatomic,strong) NSURL *outputPath;//视频输出路径

/**
 * 字幕组
 * 固定格式[@{@"begin":@"",@"end":@"",@"subtitle":@""}]
 */
@property (nonatomic,strong) NSArray *array_subtitles;
@property (nonatomic,assign) BOOL subtitleFail;//插入字幕是否失败


@end

NS_ASSUME_NONNULL_END
