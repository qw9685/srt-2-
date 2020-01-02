//
//  ccSubtitleComposition.h
//  视频字幕
//
//  Created by cc on 2019/12/24.
//  Copyright © 2019 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ccSubtitleConfig.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ccSubtitleComposition : NSObject

+ (void)addSubtitles:(ccSubtitleConfig*)config handleBlock:(void(^)(bool success))handleBlock progressBlock:(void(^)(CGFloat progress))progressBlock;

@end

NS_ASSUME_NONNULL_END
