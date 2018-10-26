//
//  VideoModel.h
//  王延磊
//
//  Created by 王延磊 on 2017/2/15.
//  Copyright © 2017年 wangynalei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoModel : NSObject
//@property (nonatomic,copy)NSString *description2;
@property (nonatomic,strong)NSString *cover;
@property (nonatomic, strong) NSString * descriptionDe;
@property (nonatomic,assign)int length;
@property (nonatomic,copy)NSString *m3u8Hd_url;
@property (nonatomic,copy)NSString *m3u8_url;
@property (nonatomic,copy)NSString *mp4Hd_url;
@property (nonatomic,copy)NSString *mp4_url;
@property (nonatomic,assign)long playCount;
@property (nonatomic,assign)long playersize;
@property (nonatomic,copy)NSString *ptime;
@property (nonatomic,copy)NSString *replyBoard;
@property (nonatomic,assign)long replyid;
@property (nonatomic,copy)NSString *title;
@property (nonatomic,copy)NSString *topicDesc;
@property (nonatomic,copy)NSString *topicImg;
@property (nonatomic,copy)NSString *topicName;
@property (nonatomic,copy)NSString *topicSid;
@property (nonatomic,copy)NSString *vid;
@property (nonatomic,strong)NSDictionary *videoTopic;
@property (nonatomic,copy)NSString *videosource;
@end
