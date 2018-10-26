//
//  VideoPlaybackViewController.m
//  王延磊
//
//  Created by 王延磊 on 2017/2/15.
//  Copyright © 2017年 wangynalei. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "WYLHTTPManager.h"
#import "VideoModel.h"
#import "WMPlayer.h"
#import "VideoCell.h"
@interface VideoPlaybackViewController ()<WMPlayerDelegate,UIScrollViewDelegate>{
    WMPlayer *videoPlayer;
    NSIndexPath *currentIndexPath;
    BOOL isSmallScreen;
    
}
@property (nonatomic,strong)UITableView *videoTableView;
@property (nonatomic,strong)NSMutableArray *videoModelArrary;
@property(nonatomic,retain)VideoCell *currentCell;
@end

@implementation VideoPlaybackViewController




- (void)viewDidLoad {
    [super viewDidLoad];
    Navtitle(@"VideoPlaybackViewController", self);
    [self videoTableView];
    _videoModelArrary = [[NSMutableArray alloc]initWithCapacity:3];
    [self getVideoInforRequest];
    
//    注册屏幕旋转通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    
    
    // Do any additional setup after loading the view.
}

-(void)onDeviceOrientationChange{
    if (videoPlayer==nil||videoPlayer.superview==nil){
        return;
    }
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            if (videoPlayer.isFullscreen) {
                if (isSmallScreen) {
                    //放widow上,小屏显示
                    [self toSmallScreen];
                }else{
                    [self toCell];
                }
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            videoPlayer.isFullscreen = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            videoPlayer.isFullscreen = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
        }
            break;
        default:
            break;
    }
    
    
}


-(UITableView *)videoTableView{
    if (!_videoTableView) {
        _videoTableView = [[UITableView alloc]init];
        _videoTableView.tableFooterView = [UIView new];
        _videoTableView.delegate = self;
        _videoTableView.dataSource = self;
        [_videoTableView registerNib:[UINib nibWithNibName:@"VideoCell" bundle:nil] forCellReuseIdentifier:@"cell"];
        [self.view addSubview:_videoTableView];
        [_videoTableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    return _videoTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.videoModelArrary.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    VideoCell *cell = (VideoCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[[NSBundle mainBundle]loadNibNamed:@"VideoCell" owner:self options:nil] lastObject];
    }
    cell.model = self.videoModelArrary[indexPath.row];
    [cell.playBtn addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playBtn.tag = indexPath.row;
    if (videoPlayer&&videoPlayer.superview) {
        if (indexPath.row==currentIndexPath.row) {
            [cell.playBtn.superview bringSubviewToFront:cell.backgroundIV];
        }else{
            [cell.playBtn.superview sendSubviewToBack:cell.backgroundIV];
        }
//        NSArray *indexpaths = [tableView indexPathsForVisibleRows];
//        if (![indexpaths containsObject:currentIndexPath]&&currentIndexPath!=nil) {//复用
//            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:videoPlayer]) {
//                videoPlayer.hidden = NO;
//            }else{
//                videoPlayer.hidden = YES;
//                [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
//            }
//        }else{
//            if ([cell.backgroundIV.subviews containsObject:videoPlayer]) {
//                [cell.backgroundIV addSubview:videoPlayer];
//                
////                [videoPlayer play];
//                videoPlayer.hidden = NO;
//            }
//            
//        }
    }
    
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 274;
}



//开始播放
-(void)startPlayVideo:(UIButton *)sender{
    currentIndexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    if ([UIDevice currentDevice].systemVersion.floatValue>=8||[UIDevice currentDevice].systemVersion.floatValue<7) {
        self.currentCell = (VideoCell *)sender.superview.superview;
    }else{//ios7系统 UITableViewCell上多了一个层级UITableViewCellScrollView
        self.currentCell = (VideoCell *)sender.superview.superview.subviews;
    }
    VideoModel *model = [self.videoModelArrary objectAtIndex:sender.tag];
    
    //    isSmallScreen = NO;
    if (isSmallScreen) {
        [self releaseWMPlayer];
        isSmallScreen = NO;
    }
    if (videoPlayer) {
        [self releaseWMPlayer];
    }
    [self createVideoPlayer:model];
    [self.videoTableView reloadData];
    
}

//创建播放器
-(void)createVideoPlayer:(VideoModel *)model{
    WMPlayer *wmPlayer = [[WMPlayer alloc]initWithFrame:self.currentCell.backgroundIV.bounds];
    wmPlayer.delegate = self;
    wmPlayer.closeBtnStyle = CloseBtnStyleClose;
    wmPlayer.URLString = model.mp4_url;
    wmPlayer.titleLabel.text = model.title;
    //是否使用手势控制音量
    wmPlayer.enableVolumeGesture = YES;
    //是否可以拖拽
    wmPlayer.dragEnable = NO;
    wmPlayer.closeBtnStyle = CloseBtnStyleClose;
    wmPlayer.URLString = model.mp4_url;
    wmPlayer.titleLabel.text = model.title;
    [self.currentCell.backgroundIV addSubview:wmPlayer];
    [self.currentCell.backgroundIV bringSubviewToFront:wmPlayer];
    [self.currentCell.playBtn.superview sendSubviewToBack:self.currentCell.playBtn];
    videoPlayer = wmPlayer;
    [videoPlayer play];
}
//释放播放器
-(void)releaseWMPlayer{
    //堵塞主线程
    //    [wmPlayer.player.currentItem cancelPendingSeeks];
//        [wmPlayer.player.currentItem.asset cancelLoading];
    [videoPlayer pause];
    [videoPlayer removeFromSuperview];
    [videoPlayer.playerLayer removeFromSuperlayer];
    [videoPlayer.player replaceCurrentItemWithPlayerItem:nil];
    videoPlayer.player = nil;
    videoPlayer.currentItem = nil;
    //释放定时器，否侧不会调用WMPlayer中的dealloc方法
    [videoPlayer.autoDismissTimer invalidate];
    videoPlayer.autoDismissTimer = nil;
    videoPlayer.playOrPauseBtn = nil;
    videoPlayer.playerLayer = nil;
    videoPlayer = nil;
}


#pragma mark scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == self.videoTableView) {
        if (videoPlayer == nil) {
            return;
        }
    }
    if (videoPlayer.superview) {
        
        CGRect rectInTableView = [self.videoTableView rectForRowAtIndexPath:currentIndexPath];
        CGRect rectInSuperview = [self.videoTableView convertRect:rectInTableView toView:[self.videoTableView superview]];
        if (rectInSuperview.origin.y<-self.currentCell.backgroundIV.frame.size.height||rectInSuperview.origin.y>[UIScreen mainScreen].bounds.size.height-64-49) {//往上拖动
            
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:videoPlayer]&&isSmallScreen) {
                isSmallScreen = YES;
            }else{
                //放widow上,小屏显示
                [self toSmallScreen];
            }
            
        }else{
            if ([self.currentCell.backgroundIV.subviews containsObject:videoPlayer]) {
                
            }else{
                [self toCell];
            }
        }
    }
    

}
//全屏播放
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    [videoPlayer removeFromSuperview];
    videoPlayer.dragEnable = NO;
    
    [UIView animateWithDuration:.35f animations:^{
        videoPlayer.transform = CGAffineTransformIdentity;
        if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
            videoPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
            videoPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        videoPlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        videoPlayer.playerLayer.frame =  CGRectMake(0,0, [UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
        
        [videoPlayer.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo([UIScreen mainScreen].bounds.size.height);
            make.height.mas_equalTo([UIScreen mainScreen].bounds.size.width);
            make.left.equalTo(videoPlayer).with.offset(0);
            make.top.equalTo(videoPlayer).with.offset(0);
        }];
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            videoPlayer.effectView.frame = CGRectMake([UIScreen mainScreen].bounds.size.height/2-155/2, [UIScreen mainScreen].bounds.size.width/2-155/2, 155, 155);
        }else{
            //        wmPlayer.lightView.frame = CGRectMake(kScreenHeight/2-155/2, kScreenWidth/2-155/2, 155, 155);
        }
        [videoPlayer.FF_View  mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset([UIScreen mainScreen].bounds.size.height/2-120/2);
            make.top.equalTo(videoPlayer).with.offset([UIScreen mainScreen].bounds.size.width/2-60/2);
            make.height.mas_equalTo(60);
            make.width.mas_equalTo(120);
        }];
        [videoPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50);
            make.width.mas_equalTo([UIScreen mainScreen].bounds.size.height);
            make.bottom.equalTo(videoPlayer.contentView).with.offset(0);
        }];
        
        [videoPlayer.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(70);
            make.left.equalTo(videoPlayer).with.offset(0);
            make.width.mas_equalTo([UIScreen mainScreen].bounds.size.height);
        }];
        
        [videoPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer.topView).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(videoPlayer).with.offset(20);
            
        }];
        
        [videoPlayer.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer.topView).with.offset(45);
            make.right.equalTo(videoPlayer.topView).with.offset(-45);
            make.center.equalTo(videoPlayer.topView);
            make.top.equalTo(videoPlayer.topView).with.offset(0);
        }];
        
        [videoPlayer.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(0);
            make.top.equalTo(videoPlayer).with.offset([UIScreen mainScreen].bounds.size.width/2-30/2);
            make.height.equalTo(@30);
            make.width.mas_equalTo([UIScreen mainScreen].bounds.size.height);
        }];
        
        [videoPlayer.loadingView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset([UIScreen mainScreen].bounds.size.height/2-22/2);
            make.top.equalTo(videoPlayer).with.offset([UIScreen mainScreen].bounds.size.width/2-22/2);
            make.height.mas_equalTo(22);
            make.width.mas_equalTo(22);
        }];
        
        [self.view addSubview:videoPlayer];
        [[UIApplication sharedApplication].keyWindow addSubview:videoPlayer];
        videoPlayer.fullScreenBtn.selected = YES;
        videoPlayer.isFullscreen = YES;
//        videoPlayer.FF_View.hidden = YES;
    }];
    
}

//小窗播放
-(void)toSmallScreen{
    //放widow上
    videoPlayer.dragEnable = YES;
    [videoPlayer removeFromSuperview];
    [UIView animateWithDuration:0.7f animations:^{
        videoPlayer.transform = CGAffineTransformIdentity;
        videoPlayer.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height-([UIScreen mainScreen].bounds.size.width/2)*0.75, [UIScreen mainScreen].bounds.size.width/2, ([UIScreen mainScreen].bounds.size.width/2)*0.75);
        videoPlayer.freeRect = CGRectMake(0,64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-64-49);
        videoPlayer.playerLayer.frame =  videoPlayer.frame;
        [[UIApplication sharedApplication].keyWindow addSubview:videoPlayer];

        [videoPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(0);
            make.right.equalTo(videoPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(videoPlayer).with.offset(0);
        }];
        [videoPlayer.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(0);
            make.right.equalTo(videoPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.top.equalTo(videoPlayer).with.offset(0);
        }];
        [videoPlayer.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer.topView).with.offset(45);
            make.right.equalTo(videoPlayer.topView).with.offset(-45);
            make.center.equalTo(videoPlayer.topView);
            make.top.equalTo(videoPlayer.topView).with.offset(0);
        }];
        [videoPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(videoPlayer).with.offset(5);
            
        }];
        [videoPlayer.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(videoPlayer);
            make.width.equalTo(videoPlayer);
            make.height.equalTo(@30);
        }];
        
    }completion:^(BOOL finished) {
        videoPlayer.isFullscreen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        videoPlayer.fullScreenBtn.selected = NO;
        isSmallScreen = YES;
        videoPlayer.FF_View.hidden = YES;
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:videoPlayer];
    }];
    
}

//回到cell
-(void)toCell{
    videoPlayer.dragEnable = NO;
    VideoCell *currentCell = (VideoCell *)[self.videoTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndexPath.row inSection:0]];
    [videoPlayer removeFromSuperview];
    [UIView animateWithDuration:0.7f animations:^{
        videoPlayer.transform = CGAffineTransformIdentity;
        videoPlayer.frame = currentCell.backgroundIV.bounds;
        videoPlayer.playerLayer.frame =  videoPlayer.bounds;
        [currentCell.backgroundIV addSubview:videoPlayer];
        [currentCell.backgroundIV bringSubviewToFront:videoPlayer];
        [videoPlayer.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.edges.equalTo(videoPlayer).with.offset(0);
            make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width);
            make.height.mas_equalTo(videoPlayer.frame.size.height);
            
        }];
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            videoPlayer.effectView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2-155/2, [UIScreen mainScreen].bounds.size.height/2-155/2, 155, 155);
        }else{
            //            wmPlayer.lightView.frame = CGRectMake(kScreenWidth/2-155/2, kScreenHeight/2-155/2, 155, 155);
        }
        
        [videoPlayer.FF_View  mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(CGPointMake([UIScreen mainScreen].bounds.size.width/2-180, videoPlayer.frame.size.height/2-144));
            make.height.mas_equalTo(60);
            make.width.mas_equalTo(120);
            
        }];
        
        [videoPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(0);
            make.right.equalTo(videoPlayer).with.offset(0);
            make.height.mas_equalTo(50);
            make.bottom.equalTo(videoPlayer).with.offset(0);
        }];
        [videoPlayer.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(0);
            make.right.equalTo(videoPlayer).with.offset(0);
            make.height.mas_equalTo(70);
            make.top.equalTo(videoPlayer).with.offset(0);
        }];
        [videoPlayer.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer.topView).with.offset(45);
            make.right.equalTo(videoPlayer.topView).with.offset(-45);
            make.center.equalTo(videoPlayer.topView);
            make.top.equalTo(videoPlayer.topView).with.offset(0);
        }];
        [videoPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(videoPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(videoPlayer).with.offset(20);
        }];
        [videoPlayer.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(videoPlayer);
            make.width.equalTo(videoPlayer);
            make.height.equalTo(@30);
        }];
    }completion:^(BOOL finished) {
        videoPlayer.isFullscreen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        isSmallScreen = NO;
        videoPlayer.fullScreenBtn.selected = NO;
        videoPlayer.FF_View.hidden = YES;
    }];
    
}



///播放器事件

//关闭按钮
-(void)wmplayer:(WMPlayer *)wmplayer clickedCloseButton:(UIButton *)closeBtn{
    NSLog(@"didClickedCloseButton");
    VideoCell *currentCell = (VideoCell *)[self.videoTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self releaseWMPlayer];
    [self setNeedsStatusBarAppearanceUpdate];
    
}
//全屏按钮
-(void)wmplayer:(WMPlayer *)wmplayer clickedFullScreenButton:(UIButton *)fullScreenBtn{
    if (fullScreenBtn.isSelected) {//全屏显示
        videoPlayer.isFullscreen = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        if (isSmallScreen) {
            //放widow上,小屏显示
            [self toSmallScreen];
        }else{
            [self toCell];
        }
    }
}
//点击视频
-(void)wmplayer:(WMPlayer *)wmplayer singleTaped:(UITapGestureRecognizer *)singleTap{
    NSLog(@"didSingleTaped");
}
-(void)wmplayer:(WMPlayer *)wmplayer doubleTaped:(UITapGestureRecognizer *)doubleTap{
    NSLog(@"didDoubleTaped");
}

///播放状态
-(void)wmplayerFailedPlay:(WMPlayer *)wmplayer WMPlayerStatus:(WMPlayerState)state{
    NSLog(@"wmplayerDidFailedPlay");
}
-(void)wmplayerReadyToPlay:(WMPlayer *)wmplayer WMPlayerStatus:(WMPlayerState)state{
    NSLog(@"wmplayerDidReadyToPlay");
}
-(void)wmplayerFinishedPlay:(WMPlayer *)wmplayer{
    NSLog(@"wmplayerDidFinishedPlay");
    [self setNeedsStatusBarAppearanceUpdate];
}

//网络请求
-(void)getVideoInforRequest{
    [[WYLHTTPManager sharedManager] requestWithMethod:GET WithPath:@"http://c.m.163.com/nc/video/home/0-10.html" WithParams:nil WithSuccessBlock:^(NSDictionary *dic, NSError *error) {
        
        NSArray *videoList = dic[@"videoList"];
        if (IsNotArrEmpty(videoList)) {
            _videoModelArrary = [VideoModel mj_objectArrayWithKeyValuesArray:videoList];
        }
        [self.videoTableView reloadData];
    } WithFailurBlock:^(NSDictionary *dic, NSError *error) {
        NSLog(@"%@",dic);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self releaseWMPlayer];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
