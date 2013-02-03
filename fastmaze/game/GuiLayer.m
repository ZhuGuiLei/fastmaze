//
// @author Jonny Brannum <jonny.brannum@gmail.com> 
//         1/22/12
//
#import <UIKit/UIKit.h>
#import "GuiLayer.h"
#import "CCMenuItem.h"
#import "CCMenu.h"
#import "CCDirector.h"
#import "CGPointExtension.h"
#import "Constants.h"
#import "MenuLayer.h"
#import "HelpLayer.h"
#import "GameLayer.h"

@implementation GuiLayer
{
    CGSize winSize;
    CCProgressTimer* progressTimer;
    CCLabelBMFont *timerLable;
    BOOL isPause;
    float shortestTime;
    float takedTime;
    int prepareTime;
    CCLabelBMFont *prepareLable;
}


@synthesize gameLayer=_gameLayer;


- (id)init
{
    self = [super init];
    winSize = [[CCDirector sharedDirector] winSize];
    
    progressTimer=[CCProgressTimer progressWithFile:@"progress_bar.png"];
    progressTimer.position=ccp( winSize.width*1/2 , winSize.height-30);
    progressTimer.anchorPoint=ccp(0.5, 1);
    progressTimer.type=kCCProgressTimerTypeHorizontalBarRL;  
    CCSprite* progressTimerBg=[CCSprite spriteWithFile:@"progress_bar_bg.png"];
    progressTimerBg.position=progressTimer.position;
    progressTimerBg.anchorPoint=ccp(0.5, 1);
    [self addChild:progressTimerBg z:zBelowOperation];
    [self addChild:progressTimer z:zBelowOperation];
    
    timerLable = [CCLabelBMFont labelWithString:[NSString stringWithFormat:kGAME_TIME_MODEL,0.0f,0.0f] fntFile:@"futura-48.fnt"];
	[self addChild:timerLable z:zBelowOperation];
	timerLable.position = ccp(winSize.width/2-20,winSize.height-(IS_IPAD()?100:40));
    timerLable.scale=0.3;

    CCMenu* back= [SpriteUtil createMenuWithImg:@"button_previous.png" pressedColor:ccYELLOW target:self selector:@selector(goBack)];
    [self addChild:back z:zBelowOperation];
    back.position=ccp(winSize.width*1/3-200, winSize.height-50);


    CCMenu* pauseButton= [SpriteUtil createMenuWithImg:@"button_pause.png" pressedColor:ccYELLOW target:self selector:@selector(pauseGame)];    
    pauseButton.position=ccp(winSize.width*2/3+200, winSize.height-50);
    [self addChild:pauseButton z:zBelowOperation tag:tPause];
    
    
    
    return self;
}
-(void) update:(ccTime)delta{
//    NSLog(@"update--");
    progressTimer.percentage += delta * 100/shortestTime;
    if (progressTimer.percentage >= 100)
    {
        progressTimer.percentage = 0;
    }
}


-(void)goBack{
    if (!isPause) {
         [[CCDirector sharedDirector] replaceScene: [CCTransitionSplitRows transitionWithDuration:1.0f scene:[MenuLayer scene]]];
    }
   
}
- (id)initWithGameLayer:(GameLayer*)gameLayer
{
    self = [self init];
    self.gameLayer=gameLayer;
    return self;
}

- (void)regenerateMaze
{
    [self nextLevel];
}
- (void)showMazeAnswer
{
    [_gameLayer showMazeAnswer];
    [self scheduleUpdate];
    [self showOperationLayer:NO];
}

#pragma mark menu

-(void)pauseGame{
    if (!isPause) {
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"button_select.mp3"];
        }
        [self showOperationLayer:YES type:tLayerPause];
    }
    isPause=YES;
    [self unscheduleUpdate];
}
-(void)audio:(id)sender{
    CCMenuItemSprite* i=(CCMenuItemSprite*)sender;
    NSUserDefaults* def= [NSUserDefaults standardUserDefaults];
    BOOL isAudioOn= ![def boolForKey:UDF_AUDIO];
    [def setBool:isAudioOn forKey:UDF_AUDIO];
    [SysConfig setNeedAudio:isAudioOn];
    CCSprite* audion,*audios;
    if (isAudioOn) {
        audion= [CCSprite spriteWithFile:@"button_audio.png"];
        audios= [CCSprite spriteWithFile:@"button_audio.png"];
    }else{
        audion= [CCSprite spriteWithFile:@"button_audio_bar.png"];
        audios= [CCSprite spriteWithFile:@"button_audio_bar.png"];
    }
    audios.color=ccYELLOW;
    i.normalImage = audion;
    i.selectedImage=audios;
    
}
-(void)music:(id)sender{
    CCMenuItemSprite* i=(CCMenuItemSprite*)sender;
    NSUserDefaults* def= [NSUserDefaults standardUserDefaults];
    BOOL isMusicOn= ![def boolForKey:UDF_MUSIC];
    [def setBool:isMusicOn forKey:UDF_MUSIC];
    [SysConfig setNeedMusic:isMusicOn];
    if (isMusicOn) {
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"gamebg.mp3" loop:YES];
    } else {
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    }
    
    CCSprite* musicn,*musics;
    if (isMusicOn) {
        musicn= [CCSprite spriteWithFile:@"button_music.png"];
        musics= [CCSprite spriteWithFile:@"button_music.png"];
    }else{
        musicn= [CCSprite spriteWithFile:@"button_music_bar.png"];
        musics= [CCSprite spriteWithFile:@"button_music_bar.png"];
    }
    musics.color=ccYELLOW;
    i.normalImage = musicn;
    i.selectedImage=musics;
    
}
-(void)resumeGame{
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine] playEffect:@"button_select.mp3"];
    }
    [self showOperationLayer:NO];
    [self showPrepareLayer];
    
}
-(void)nextLevel{
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine] playEffect:@"button_select.mp3"];
    }
    [self regenerateMaze];
    [self gameInit];
    [self showOperationLayer:NO];
    [self showPrepareLayer];
    
}

-(void)restartGame{
    [self gameInit];
    [self showOperationLayer:NO];
}
-(void) menu
{
	CCScene *sc = [CCScene node];
	[sc addChild:[MenuLayer node]];
	[[CCDirector sharedDirector] replaceScene:  [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
}
-(void)showOperationLayer:(BOOL)show{
    [self showOperationLayer:show type:tLayerNone];    
}
- (void)initBaseOperationLayer:(CCLayer *)operationLayer {
    //---same for all kind of layer
    //audio & music
    BOOL isAudioOn= [[NSUserDefaults standardUserDefaults] boolForKey:UDF_AUDIO];
    CCMenu* audioButton=nil;
    if (isAudioOn) {
        audioButton=[SpriteUtil createMenuWithImg:@"button_audio.png" pressedColor:ccYELLOW target:self selector:@selector(audio:)];
    }else{
        audioButton=[SpriteUtil createMenuWithImg:@"button_audio_bar.png" pressedColor:ccYELLOW target:self selector:@selector(audio:)];
    }
    audioButton.position=ccp(winSize.width /2-(IS_IPAD()?100:60), winSize.height*1/3+30);
    [operationLayer addChild:audioButton z:zAboveOperation tag:tAudio];
    
    BOOL isMusicOn= [[NSUserDefaults standardUserDefaults] boolForKey:UDF_MUSIC];
    CCMenu* musicButton=nil;
    if (isMusicOn) {
        musicButton=[SpriteUtil createMenuWithImg:@"button_music.png" pressedColor:ccYELLOW target:self selector:@selector(music:)];
    }else{
        musicButton=[SpriteUtil createMenuWithImg:@"button_music_bar.png" pressedColor:ccYELLOW target:self selector:@selector(music:)];
    }
    musicButton.position=ccp(winSize.width /2+(IS_IPAD()?100:60), winSize.height*1/3+30);
    [operationLayer addChild:musicButton z:zAboveOperation tag:tMusic];
    
    //menu & refresh & start
    CCMenu* menuButton= [SpriteUtil createMenuWithImg:@"button_menu.png" pressedColor:ccYELLOW target:self selector:@selector(menu)];
    menuButton.position=ccp(winSize.width /2-(IS_IPAD()?200:100), winSize.height*1/3-100);
    [operationLayer addChild:menuButton z:zAboveOperation];
    
    CCMenu* restartButton= [SpriteUtil createMenuWithImg:@"button_refresh.png" pressedColor:ccYELLOW target:self selector:@selector(restartGame)];
    restartButton.position=ccp(winSize.width /2, winSize.height*1/3-100);
    [operationLayer addChild:restartButton z:zAboveOperation];
}

-(void)showOperationLayer:(BOOL)show type:(LayerType)layerType{
    if (show) {
        //暂停layer
        CCLayer* operationLayer =[CCLayerColor layerWithColor:ccc4(166,166,166,122) ];
        [self addChild:operationLayer z:zPauseLayer tag:tOperationLayer];
        operationLayer.isTouchEnabled=NO;
        self.isTouchEnabled=NO;
        switch (layerType) {
            case tLayerPause:
            {
                [self initBaseOperationLayer:operationLayer];
                
                CCMenu* regenerateMaze=[SpriteUtil createMenuWithImg:@"button_new_maze.png" pressedColor:ccYELLOW target:self selector:@selector(regenerateMaze)];
                [operationLayer addChild:regenerateMaze z:zBelowOperation];
                regenerateMaze.position=ccp(winSize.width*1/3, winSize.height*1/3+160);
                
                
                CCMenu* showMazeAnswer= [SpriteUtil createMenuWithImg:@"button_show_answer.png" pressedColor:ccYELLOW target:self selector:@selector(showMazeAnswer)];
                [operationLayer addChild:showMazeAnswer z:zBelowOperation];
                showMazeAnswer.position=ccp(winSize.width*2/3, winSize.height*1/3+160);
                
                CCMenu* resumeButton=[SpriteUtil createMenuWithImg:@"button_start.png" pressedColor:ccYELLOW target:self selector:@selector(resumeGame)];
                resumeButton.position=ccp(winSize.width/2+(IS_IPAD()?200:100), winSize.height*1/3-100);
                [operationLayer addChild:resumeButton z:zAboveOperation];
            }
                
                break;
            case tLayerWin:
            {
                [self initBaseOperationLayer:operationLayer];
                
                CCMenu* nextLevelButton=[SpriteUtil createMenuWithImg:@"button_next_level.png" pressedColor:ccYELLOW target:self selector:@selector(nextLevel)];
                nextLevelButton.position=ccp(winSize.width/2+(IS_IPAD()?200:100), winSize.height*1/3-100);
                [operationLayer addChild:nextLevelButton z:zAboveOperation];
                
                CCSprite* winGoodSprite=[CCSprite spriteWithFile:@"result_win_good.png"];
                winGoodSprite.position=ccp(winSize.width/2, winSize.height*2/3);
                [operationLayer addChild:winGoodSprite z:zAboveOperation];
            }
                
                break;
            case tLayerLose:
            {
                
            }
            case tLayerPrepare:
            {
                prepareLable = [CCLabelBMFont labelWithString:@"" fntFile:@"futura-48.fnt"];
                [operationLayer addChild:prepareLable z:zBelowOperation];
                prepareLable.position = ccp(winSize.width/2,winSize.height/2);
                prepareLable.scale=2;
                [self updatePrepareTimer];
            }
                break;
            case tLayerNone:
            {
                
            }
                break;
        }
    } else {
        CCLayer* pl=(CCLayer*)[self getChildByTag:tOperationLayer];
        [pl removeAllChildrenWithCleanup:YES];
        [pl removeFromParentAndCleanup:YES];
    }    
}
//显示倒计时
-(void)updatePrepareTimer{
    if (prepareTime>0) {        
        [prepareLable setString:[NSString stringWithFormat:@"%d",prepareTime]];
        [self performSelector:@selector(updatePrepareTimer) withObject:nil afterDelay:1];
        prepareTime--;
    }else{
        isPause=NO;
        [self scheduleUpdate];
        [self showOperationLayer:NO];
    }
}
-(void)gameInit{
    isPause=NO;
    progressTimer.percentage=100;
    shortestTime=[[NSUserDefaults standardUserDefaults]integerForKey:UFK_SHOTTTEST_TIMER];
    [self showPrepareLayer];
}
-(void)showPrepareLayer{
    prepareTime=kPREPARE_TIME;
    [self showOperationLayer:YES type:tLayerPrepare];
}

-(void)help{
    [[CCDirector sharedDirector] replaceScene: [CCTransitionSplitRows transitionWithDuration:1.0f scene:[HelpLayer scene]]];
    
    /*
    FIXME scene方向会改变，不知道原因
    AppDelegate* delegate=(AppDelegate*) [[UIApplication sharedApplication]delegate];
    HelpViewController* controller= [[[HelpViewController alloc]initWithNibName:@"HelpViewController" bundle:nil]autorelease];
    NSLog(@"--self.boundingBox.size width:%f,height:%f",self.boundingBox.size.width,self.boundingBox.size.height);
    NSLog(@"delegate.viewController.view:%@",delegate.viewController);

    [delegate.viewController presentModalViewController:controller animated:YES];
    NSLog(@"--self.boundingBox.size width:%f,height:%f",self.boundingBox.size.width,self.boundingBox.size.height);
     */
}

@end