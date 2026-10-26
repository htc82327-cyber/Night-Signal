#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <signal.h>
#import <math.h>
#import <rootless.h>

static NSString * const NSStatePath = @"/var/mobile/Library/Preferences/com.thxrealx7.nightsignal.state.plist";
static NSString * const NStart = @"com.thxrealx7.nightsignal/start";
static NSString * const NRollback = @"com.thxrealx7.nightsignal/rollback";
static NSString * const NTest = @"com.thxrealx7.nightsignal/test";
static NSString * const NRefresh = @"com.thxrealx7.nightsignal/refresh";
static NSString * const NResume = @"com.thxrealx7.nightsignal/resume";
static NSString * const NGood = @"com.thxrealx7.nightsignal/good";
static NSString * const NBad = @"com.thxrealx7.nightsignal/bad";

static NSInteger const TAG_TINT = 933301;
static NSInteger const TAG_LABEL = 933302;
static NSInteger const TAG_WALL = 933303;
static NSInteger const TAG_GHOSTS = 933304;
static NSInteger const TAG_LOCK = 933305;
static NSInteger const TAG_SETTINGS = 933306;
static NSInteger const TAG_PHOTOS = 933307;

static NSTimer *StoryTimer = nil;
static UIWindow *EffectWindow = nil;
static SystemSoundID ScreamSound = 0;
static BOOL SoundLoaded = NO;

static NSMutableDictionary *LoadState(void) {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:NSStatePath];
    return d ? [d mutableCopy] : [NSMutableDictionary dictionary];
}
static void SaveState(NSDictionary *d) { [d writeToFile:NSStatePath atomically:YES]; }
static BOOL Active(void) { return [LoadState()[@"active"] boolValue]; }
static NSString *Lang(void) { return LoadState()[@"lang"] ?: @"ru"; }
static BOOL RU(void) { return ![Lang() isEqualToString:@"en"]; }
static NSTimeInterval Elapsed(void) {
    NSDictionary *s = LoadState();
    if (![s[@"active"] boolValue]) return 0;
    NSTimeInterval st = [s[@"startTime"] doubleValue];
    if (st <= 0) return 0;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if ([s[@"suppressed"] boolValue]) {
        NSTimeInterval ps = [s[@"pauseStart"] doubleValue];
        if (ps > 0) now = ps;
    }
    return MAX(0, now - st);
}
static NSInteger LastEvent(void) { return [LoadState()[@"lastEvent"] integerValue]; }
static void SetLastEvent(NSInteger i) {
    NSMutableDictionary *s = LoadState(); s[@"lastEvent"] = @(i); SaveState(s);
}
static NSString *T(NSString *ru, NSString *en) { return RU() ? ru : en; }

static BOOL Suppressed(void) { return [LoadState()[@"suppressed"] boolValue]; }
static NSString *Ending(void) { return LoadState()[@"ending"] ?: @""; }

static BOOL EffectsEnabled(void) {
    return Active() && !Suppressed();
}

static void SavePauseStart(void) {
    NSMutableDictionary *s = LoadState();
    s[@"suppressed"] = @YES;
    s[@"pauseStart"] = @([[NSDate date] timeIntervalSince1970]);
    SaveState(s);
}

static void ResumeFromPause(void) {
    NSMutableDictionary *s = LoadState();
    NSTimeInterval pauseStart = [s[@"pauseStart"] doubleValue];
    NSTimeInterval start = [s[@"startTime"] doubleValue];
    if (pauseStart > 0 && start > 0) {
        NSTimeInterval pausedFor = MAX(0, [[NSDate date] timeIntervalSince1970] - pauseStart);
        s[@"startTime"] = @(start + pausedFor);
    }
    s[@"suppressed"] = @NO;
    s[@"pauseStart"] = @0;
    SaveState(s);
}

static UIWindowScene *Scene(void) {
    if (@available(iOS 13.0,*)) {
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes)
            if ([s isKindOfClass:UIWindowScene.class] && s.activationState == UISceneActivationStateForegroundActive)
                return (UIWindowScene *)s;
    }
    return nil;
}
static UIWindow *MakeWindow(void) {
    UIWindow *w=nil;
    if (@available(iOS 13.0,*)) { UIWindowScene *sc=Scene(); if(sc) w=[[UIWindow alloc] initWithWindowScene:sc]; }
    if(!w) w=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    w.frame=UIScreen.mainScreen.bounds; w.windowLevel=UIWindowLevelAlert+180;
    UIViewController *vc=[UIViewController new]; vc.view.backgroundColor=UIColor.clearColor; w.rootViewController=vc;
    return w;
}
static void CloseWindow(void){ if(EffectWindow){EffectWindow.hidden=YES;EffectWindow=nil;} }

static void LoadSound(void) {
    if(SoundLoaded)return; SoundLoaded=YES;
    NSArray *paths=@[
        ROOT_PATH_NS(@"/Applications/NightSignal.app/scream.wav"),
        ROOT_PATH_NS(@"/Applications/NightSignal.app/Resources/scream.wav")
    ];
    for(NSString *p in paths) if([[NSFileManager defaultManager] fileExistsAtPath:p]){
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:p], &ScreamSound); break;
    }
}
static void PlayScare(void){ LoadSound(); if(ScreamSound)AudioServicesPlaySystemSound(ScreamSound); AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); }

static void Screamer(NSString *text, NSInteger style, NSTimeInterval duration) {
    CloseWindow(); EffectWindow=MakeWindow(); UIView *v=EffectWindow.rootViewController.view;
    v.backgroundColor = style==2 ? UIColor.whiteColor : UIColor.blackColor;
    CGFloat W=v.bounds.size.width,H=v.bounds.size.height;

    if(style==0 || style==1){
        UIView *wash=[[UIView alloc] initWithFrame:v.bounds];
        wash.backgroundColor=[UIColor colorWithRed:0.58 green:0 blue:0 alpha:style==1?0.48:0.22];
        [v addSubview:wash];
        for(int i=0;i<2;i++){
            UIView *eye=[[UIView alloc] initWithFrame:CGRectMake(W*(i?0.59:0.19),H*0.29,W*0.22,W*0.12)];
            eye.backgroundColor=style==1?UIColor.whiteColor:[UIColor colorWithRed:1 green:0.04 blue:0.03 alpha:1];
            eye.layer.cornerRadius=eye.bounds.size.height/2;
            eye.layer.shadowColor=UIColor.redColor.CGColor;eye.layer.shadowOpacity=1;eye.layer.shadowRadius=22;
            [v addSubview:eye];
        }
        UILabel *mouth=[[UILabel alloc] initWithFrame:CGRectMake(20,H*0.46,W-40,110)];
        mouth.text= style==1 ? @"▾ ▾ ▾ ▾ ▾ ▾" : @"│  │  │  │";
        mouth.textColor=UIColor.whiteColor;mouth.textAlignment=NSTextAlignmentCenter;
        mouth.font=[UIFont systemFontOfSize:38 weight:UIFontWeightBlack];[v addSubview:mouth];
    } else {
        UILabel *big=[[UILabel alloc] initWithFrame:CGRectMake(0,H*0.17,W,H*0.48)];
        big.text=@"03:33";big.textColor=UIColor.blackColor;big.textAlignment=NSTextAlignmentCenter;
        big.font=[UIFont monospacedDigitSystemFontOfSize:74 weight:UIFontWeightBlack];[v addSubview:big];
    }

    UILabel *l=[[UILabel alloc] initWithFrame:CGRectMake(20,H*0.68,W-40,130)];
    l.text=text;l.numberOfLines=0;l.textAlignment=NSTextAlignmentCenter;
    l.textColor=style==2?UIColor.blackColor:UIColor.whiteColor;
    l.font=[UIFont systemFontOfSize:28 weight:UIFontWeightBlack];[v addSubview:l];

    EffectWindow.hidden=NO; PlayScare();
    [UIView animateWithDuration:0.07 animations:^{v.transform=CGAffineTransformMakeScale(1.03,1.03);}
        completion:^(__unused BOOL f){[UIView animateWithDuration:0.1 animations:^{v.transform=CGAffineTransformIdentity;}];}];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(duration*NSEC_PER_SEC)),dispatch_get_main_queue(),^{CloseWindow();});
}

static void Thought(NSString *text) {
    CloseWindow(); EffectWindow=MakeWindow(); UIView *v=EffectWindow.rootViewController.view; v.backgroundColor=UIColor.clearColor;
    CGFloat W=v.bounds.size.width,H=v.bounds.size.height;
    UIView *card=[[UIView alloc] initWithFrame:CGRectMake(18,H-178,W-36,105)];
    card.backgroundColor=[UIColor colorWithWhite:0.04 alpha:0.91];card.layer.cornerRadius=20;
    card.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.08].CGColor;card.layer.borderWidth=1;[v addSubview:card];
    UILabel *cap=[[UILabel alloc] initWithFrame:CGRectMake(16,12,card.bounds.size.width-32,18)];
    cap.text=T(@"МЫСЛЬ",@"THOUGHT");cap.textColor=[UIColor colorWithRed:1 green:0.25 blue:0.22 alpha:1];
    cap.font=[UIFont systemFontOfSize:11 weight:UIFontWeightBlack];[card addSubview:cap];
    UILabel *body=[[UILabel alloc] initWithFrame:CGRectMake(16,31,card.bounds.size.width-32,62)];
    body.text=text;body.numberOfLines=0;body.textColor=UIColor.whiteColor;body.font=[UIFont italicSystemFontOfSize:15];[card addSubview:body];
    EffectWindow.hidden=NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(4.2*NSEC_PER_SEC)),dispatch_get_main_queue(),^{CloseWindow();});
}

static void FakeCall(NSString *caller, NSString *sub) {
    CloseWindow();EffectWindow=MakeWindow();UIView *v=EffectWindow.rootViewController.view;
    v.backgroundColor=[UIColor colorWithRed:0.025 green:0.03 blue:0.055 alpha:1];
    CGFloat W=v.bounds.size.width,H=v.bounds.size.height;
    UILabel *a=[[UILabel alloc] initWithFrame:CGRectMake((W-108)/2,106,108,108)];
    a.text=@"?";a.textAlignment=NSTextAlignmentCenter;a.textColor=UIColor.whiteColor;
    a.font=[UIFont systemFontOfSize:43 weight:UIFontWeightBold];a.backgroundColor=[UIColor colorWithWhite:0.18 alpha:1];
    a.layer.cornerRadius=54;a.clipsToBounds=YES;[v addSubview:a];
    UILabel *n=[[UILabel alloc] initWithFrame:CGRectMake(20,237,W-40,42)];
    n.text=caller;n.textAlignment=NSTextAlignmentCenter;n.textColor=UIColor.whiteColor;n.font=[UIFont systemFontOfSize:29 weight:UIFontWeightBold];[v addSubview:n];
    UILabel *s=[[UILabel alloc] initWithFrame:CGRectMake(20,283,W-40,28)];
    s.text=sub;s.textAlignment=NSTextAlignmentCenter;s.textColor=[UIColor colorWithWhite:0.74 alpha:1];s.font=[UIFont systemFontOfSize:15];[v addSubview:s];
    for(int i=0;i<2;i++){
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.frame=CGRectMake(i?W-120:42,H-145,78,78);b.layer.cornerRadius=39;
        b.backgroundColor=i?UIColor.systemGreenColor:UIColor.systemRedColor;
        [b setTitle:i?T(@"Открыть",@"Open"):T(@"Сбросить",@"End") forState:UIControlStateNormal];
        [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];[v addSubview:b];
    }
    EffectWindow.hidden=NO;AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(8*NSEC_PER_SEC)),dispatch_get_main_queue(),^{CloseWindow();});
}

static NSString *BundleForIcon(id view) {
    SEL isel=sel_registerName("icon"); if(![view respondsToSelector:isel])return nil;
    id icon=((id(*)(id,SEL))objc_msgSend)(view,isel); if(!icon)return nil;
    const char *sels[]={"applicationBundleID","bundleIdentifier","leafIdentifier","uniqueIdentifier"};
    for(int i=0;i<4;i++){SEL s=sel_registerName(sels[i]);if([icon respondsToSelector:s]){id x=((id(*)(id,SEL))objc_msgSend)(icon,s);if([x isKindOfClass:NSString.class]&&[x length])return x;}}
    return nil;
}
static NSString *HorrorName(NSString *b,NSTimeInterval e){
    if(!b||e<35)return nil;
    NSDictionary *a=@{
      @"com.apple.mobilesafari":T(@"НЕТ СИГНАЛА",@"NO SIGNAL"),
      @"com.apple.mobileslideshow":T(@"ЛИЦА",@"FACES"),
      @"com.apple.mobilenotes":T(@"Я ПОМНЮ",@"I REMEMBER"),
      @"com.thxrealx7.povozka":@"MARA",
      @"com.thxrealx7.nightsignalapp":T(@"НЕ ОТКРЫВАЙ",@"DON'T OPEN")
    };
    NSDictionary *m=@{
      @"com.apple.Preferences":T(@"НЕ ТРОГАЙ",@"DON'T TOUCH"),
      @"com.apple.DocumentsApp":T(@"ОТКРОЙ МЕНЯ",@"OPEN ME"),
      @"com.apple.mobilephone":T(@"ОТВЕТЬ",@"ANSWER"),
      @"com.apple.AppStore":T(@"НЕ ОБНОВЛЯЙ",@"DON'T UPDATE"),
      @"org.coolstar.SileoStore":T(@"НЕ УДАЛИТЬ",@"CAN'T REMOVE"),
      @"com.thxrealx7.povozka":@"03:33",
      @"com.thxrealx7.nightsignalapp":@"MARA // 03:33"
    };
    NSDictionary *z=@{
      @"com.apple.mobilesafari":T(@"Я ВИЖУ ТЕБЯ",@"I SEE YOU"),
      @"com.apple.mobileslideshow":T(@"НЕ ЛИСТАЙ",@"STOP LOOKING"),
      @"com.apple.mobilenotes":T(@"ПРОЧИТАЙ",@"READ ME"),
      @"com.apple.Preferences":@"MARA VEYL",
      @"com.apple.mobilephone":T(@"ВОЗЬМИ ТРУБКУ",@"PICK UP"),
      @"com.thxrealx7.povozka":T(@"ОНА ПИШЕТ",@"SHE IS TYPING"),
      @"com.thxrealx7.nightsignalapp":@"UNKNOWN"
    };
    if([Ending() isEqualToString:@"bad"]){
        NSDictionary *bad=@{
          @"com.apple.mobilesafari":@"MARA",
          @"com.apple.mobileslideshow":@"03:33",
          @"com.apple.mobilenotes":T(@"ОНА ОСТАЛАСЬ",@"SHE STAYED"),
          @"com.apple.Preferences":@"MARA VEYL",
          @"com.apple.mobilephone":T(@"ОТВЕТЬ ЕЙ",@"ANSWER HER"),
          @"com.thxrealx7.povozka":T(@"ВСЕГДА В СЕТИ",@"ALWAYS ONLINE"),
          @"com.thxrealx7.nightsignalapp":@"MARA // 03:33"
        };
        return bad[b]?:z[b]?:m[b]?:a[b];
    }
    if(e<150)return a[b];
    if(e<455)return m[b]?:a[b];
    return z[b]?:m[b]?:a[b];
}
static UIColor *Tint(NSTimeInterval e){
    if(e<35)return UIColor.clearColor;
    if(e<120)return [UIColor colorWithRed:0.04 green:0.06 blue:0.22 alpha:.24];
    if(e<240)return [UIColor colorWithRed:.56 green:0 blue:.02 alpha:.32];
    if(e<430)return [UIColor colorWithRed:.66 green:0 blue:0 alpha:.46];
    return [UIColor colorWithRed:.38 green:0 blue:.03 alpha:.5];
}
static void ApplyIcon(UIView *v){
    UIView *t=[v viewWithTag:TAG_TINT],*lb=[v viewWithTag:TAG_LABEL];
    NSString *ending=Ending();
    if(!EffectsEnabled() || [ending isEqualToString:@"good"]){
        [t removeFromSuperview];[lb removeFromSuperview];v.transform=CGAffineTransformIdentity;return;
    }
    NSTimeInterval e=Elapsed();NSString *b=BundleForIcon(v);NSString *nm=HorrorName(b,e);
    if(!t){t=[[UIView alloc]init];t.tag=TAG_TINT;t.userInteractionEnabled=NO;t.layer.cornerRadius=14;[v addSubview:t];}
    CGFloat sz=MIN(60,MAX(42,v.bounds.size.width*.74));t.frame=CGRectMake((v.bounds.size.width-sz)/2,1,sz,sz);t.backgroundColor=Tint(e);
    if(nm){
        if(!lb){UILabel *l=[UILabel new];l.tag=TAG_LABEL;l.textAlignment=NSTextAlignmentCenter;l.font=[UIFont systemFontOfSize:9.5 weight:UIFontWeightSemibold];l.textColor=UIColor.whiteColor;l.backgroundColor=[UIColor colorWithWhite:0 alpha:.68];l.layer.cornerRadius=5;l.clipsToBounds=YES;l.userInteractionEnabled=NO;[v addSubview:l];lb=l;}
        ((UILabel*)lb).text=nm;lb.frame=CGRectMake(-6,MAX(62,v.bounds.size.height-19),v.bounds.size.width+12,17);[v bringSubviewToFront:lb];
    }else [lb removeFromSuperview];
    if((e>140&&e<185)||(e>310&&e<365)||e>545){v.transform=CGAffineTransformMakeTranslation(sin(CACurrentMediaTime()*34)*.9,cos(CACurrentMediaTime()*27)*.7);}else v.transform=CGAffineTransformIdentity;
}
static void Ghosts(UIView *root,NSTimeInterval e){
    UIView *g=[root viewWithTag:TAG_GHOSTS];BOOL on=((e>145&&e<190)||(e>300&&e<405));
    if(!on){[g removeFromSuperview];return;}if(g)return;
    g=[[UIView alloc]initWithFrame:root.bounds];g.tag=TAG_GHOSTS;g.userInteractionEnabled=NO;g.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[root addSubview:g];
    NSArray *letters=@[@"P",@"S",@"F",@"?",@"N",@"M"];NSArray *names=@[@"PovoZka",@"Sileo",@"Files",@"Unknown",@"Notes",@"MARA"];
    CGFloat W=root.bounds.size.width;
    for(NSInteger i=0;i<6;i++){
        UIView *box=[[UIView alloc]initWithFrame:CGRectMake(20+(i%3)*(W-90)/2,120+(i/3)*155,58,58)];
        box.backgroundColor=[UIColor colorWithRed:.18 green:.01 blue:.02 alpha:.55];box.layer.cornerRadius=15;box.layer.borderColor=UIColor.redColor.CGColor;box.layer.borderWidth=.7;[g addSubview:box];
        UILabel *x=[[UILabel alloc]initWithFrame:box.bounds];x.text=letters[i];x.textColor=UIColor.whiteColor;x.textAlignment=NSTextAlignmentCenter;x.font=[UIFont systemFontOfSize:22 weight:UIFontWeightBlack];[box addSubview:x];
        UILabel *n=[[UILabel alloc]initWithFrame:CGRectMake(box.frame.origin.x-12,CGRectGetMaxY(box.frame)+3,82,17)];n.text=names[i];n.textColor=[UIColor colorWithWhite:1 alpha:.72];n.textAlignment=NSTextAlignmentCenter;n.font=[UIFont systemFontOfSize:9];[g addSubview:n];
    }
}
static void ApplyWallpaper(UIView *root){
    UIView *o=[root viewWithTag:TAG_WALL];
    NSString *ending=Ending();
    if(!EffectsEnabled() || [ending isEqualToString:@"good"]){
        [o removeFromSuperview];
        [[root viewWithTag:TAG_GHOSTS] removeFromSuperview];
        return;
    }
    NSTimeInterval e=Elapsed();

    if(!o){
        o=[[UIView alloc]initWithFrame:root.bounds];
        o.tag=TAG_WALL;
        o.userInteractionEnabled=NO;
        o.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [root insertSubview:o atIndex:0];
    }
    o.frame=root.bounds;

    if([ending isEqualToString:@"bad"]){
        o.backgroundColor=[UIColor colorWithRed:.70 green:0 blue:.012 alpha:.74];
    } else if(e<45){
        o.backgroundColor=UIColor.clearColor;
    } else if(e<150){
        o.backgroundColor=[UIColor colorWithRed:.02 green:.03 blue:.12 alpha:.27];
    } else if(e<300){
        o.backgroundColor=[UIColor colorWithRed:.44 green:0 blue:.02 alpha:.43];
    } else if(e<455){
        o.backgroundColor=[UIColor colorWithWhite:0 alpha:.50];
    } else {
        o.backgroundColor=[UIColor colorWithRed:.34 green:0 blue:.025 alpha:.58];
    }

    Ghosts(root,e);
}

static void LockOverlay(UIView *root){
    UIView *old=[root viewWithTag:TAG_LOCK];if(!EffectsEnabled() || [Ending() isEqualToString:@"good"]){[old removeFromSuperview];return;}
    NSTimeInterval e=Elapsed();if(e<205){[old removeFromSuperview];return;}
    if(!old){old=[[UIView alloc]initWithFrame:root.bounds];old.tag=TAG_LOCK;old.userInteractionEnabled=NO;old.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[root addSubview:old];}
    [old.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    old.backgroundColor=[UIColor colorWithRed:.22 green:0 blue:0 alpha:e>420?.42:.24];
    UILabel *top=[[UILabel alloc]initWithFrame:CGRectMake(18,115,root.bounds.size.width-36,32)];
    top.text=e>430?@"MARA // 03:33":T(@"НЕ БЛОКИРУЙ ТЕЛЕФОН",@"DON'T LOCK THE PHONE");top.textColor=UIColor.whiteColor;top.textAlignment=NSTextAlignmentCenter;top.font=[UIFont systemFontOfSize:17 weight:UIFontWeightBlack];[old addSubview:top];
    UILabel *msg=[[UILabel alloc]initWithFrame:CGRectMake(30,root.bounds.size.height*.58,root.bounds.size.width-60,90)];
    msg.text=e>500?T(@"Я была здесь до установки.",@"I was here before the install."):T(@"PovoZka: новое сообщение от mara.unknown",@"PovoZka: new message from mara.unknown");
    msg.textColor=[UIColor colorWithWhite:1 alpha:.82];msg.numberOfLines=0;msg.textAlignment=NSTextAlignmentCenter;msg.font=[UIFont systemFontOfSize:14 weight:UIFontWeightMedium];[old addSubview:msg];
}
static void SettingsOverlay(UIView *root){
    UIView *old=[root viewWithTag:TAG_SETTINGS];if(!EffectsEnabled()||[Ending() isEqualToString:@"good"]||Elapsed()<235){[old removeFromSuperview];return;}
    if(!old){old=[[UIView alloc]initWithFrame:CGRectMake(12,94,root.bounds.size.width-24,152)];old.tag=TAG_SETTINGS;old.backgroundColor=[UIColor colorWithRed:.09 green:.09 blue:.105 alpha:.98];old.layer.cornerRadius=18;old.layer.borderColor=[UIColor colorWithRed:.7 green:0 blue:.04 alpha:.6].CGColor;old.layer.borderWidth=1;old.userInteractionEnabled=NO;[root addSubview:old];}
    [old.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(16,12,old.bounds.size.width-32,32)];title.text=@"MARA VEYL";title.textColor=UIColor.whiteColor;title.font=[UIFont systemFontOfSize:23 weight:UIFontWeightBold];[old addSubview:title];
    UILabel *icloud=[[UILabel alloc]initWithFrame:CGRectMake(16,48,old.bounds.size.width-32,24)];icloud.text=T(@"Apple ID • iCloud • Найти iPhone",@"Apple ID • iCloud • Find My");icloud.textColor=[UIColor colorWithWhite:.67 alpha:1];icloud.font=[UIFont systemFontOfSize:12];[old addSubview:icloud];
    UILabel *model=[[UILabel alloc]initWithFrame:CGRectMake(16,86,old.bounds.size.width-32,50)];model.text=T(@"Модель устройства: UNKNOWN // 03:33\nСерийный номер: LISTENING",@"Device Model: UNKNOWN // 03:33\nSerial: LISTENING");model.numberOfLines=2;model.textColor=[UIColor colorWithRed:1 green:.26 blue:.22 alpha:1];model.font=[UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightSemibold];[old addSubview:model];
}
static void PhotosOverlay(UIView *root){
    UIView *old=[root viewWithTag:TAG_PHOTOS];if(!EffectsEnabled()||[Ending() isEqualToString:@"good"]||Elapsed()<365){[old removeFromSuperview];return;}
    if(!old){old=[[UIView alloc]initWithFrame:root.bounds];old.tag=TAG_PHOTOS;old.backgroundColor=[UIColor colorWithWhite:.02 alpha:.96];old.userInteractionEnabled=NO;old.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[root addSubview:old];}
    [old.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UILabel *h=[[UILabel alloc]initWithFrame:CGRectMake(18,55,root.bounds.size.width-36,40)];h.text=T(@"Недавние • 9 новых",@"Recents • 9 new");h.textColor=UIColor.whiteColor;h.font=[UIFont systemFontOfSize:28 weight:UIFontWeightBold];[old addSubview:h];
    CGFloat gap=4,sz=(root.bounds.size.width-2*gap)/3.0;
    for(int i=0;i<9;i++){
        UIView *cell=[[UIView alloc]initWithFrame:CGRectMake((i%3)*(sz+gap),(i/3)*(sz+gap)+112,sz,sz)];
        cell.backgroundColor=[UIColor colorWithRed:.08+(i%3)*.03 green:.005 blue:.008 alpha:1];[old addSubview:cell];
        UILabel *eye=[[UILabel alloc]initWithFrame:cell.bounds];eye.text=(i==4||i==8)?@"●  ●":(i==2?@"03:33":@"");eye.textAlignment=NSTextAlignmentCenter;eye.textColor=i==2?UIColor.whiteColor:UIColor.redColor;eye.font=[UIFont systemFontOfSize:i==2?18:25 weight:UIFontWeightBlack];[cell addSubview:eye];
        if(i==6){UILabel *m=[[UILabel alloc]initWithFrame:CGRectInset(cell.bounds,8,8)];m.text=T(@"НЕ\nЛИСТАЙ",@"STOP\nLOOKING");m.numberOfLines=2;m.textAlignment=NSTextAlignmentCenter;m.textColor=UIColor.whiteColor;m.font=[UIFont systemFontOfSize:17 weight:UIFontWeightBlack];[cell addSubview:m];}
    }
}


static void RedPulse(NSTimeInterval duration) {
    CloseWindow();
    EffectWindow=MakeWindow();
    UIView *v=EffectWindow.rootViewController.view;
    v.backgroundColor=[UIColor colorWithRed:.68 green:0 blue:.015 alpha:.88];
    UILabel *l=[[UILabel alloc]initWithFrame:CGRectInset(v.bounds,24,120)];
    l.text=T(@"СИГНАЛ УСИЛИВАЕТСЯ",@"SIGNAL STRENGTH RISING");
    l.textColor=UIColor.whiteColor;
    l.textAlignment=NSTextAlignmentCenter;
    l.numberOfLines=0;
    l.font=[UIFont systemFontOfSize:27 weight:UIFontWeightBlack];
    [v addSubview:l];
    EffectWindow.hidden=NO;
    [UIView animateWithDuration:.22 delay:0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        v.alpha=.35;
    } completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(duration*NSEC_PER_SEC)),dispatch_get_main_queue(),^{CloseWindow();});
}

static void Respring(void){dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.35*NSEC_PER_SEC)),dispatch_get_main_queue(),^{kill(getpid(),SIGTERM);});}
static NSArray *Times(void){return @[@20,@38,@58,@78,@98,@122,@148,@176,@202,@228,@252,@282,@312,@342,@372,@402,@430,@456,@480,@505,@530,@550,@565,@575,@585,@595];}
static void Event(NSInteger i){
    switch(i){
      case 0: Thought(T(@"Почему этот чат уже был здесь после установки?",@"Why was this chat already here after install?"));break;
      case 1: Screamer(T(@"НЕ ОБОРАЧИВАЙСЯ",@"DON'T TURN AROUND"),0,1.0);break;
      case 2: FakeCall(@"mara.unknown",T(@"PovoZka аудиозвонок",@"PovoZka audio call"));break;
      case 3: Thought(T(@"Она пишет о телефоне так, будто видит мой экран.",@"She talks about the phone like she can see my screen."));break;
      case 4: RedPulse(1.8);break;
      case 5: Screamer(T(@"Я ВИЖУ ИКОНКИ",@"I SEE THE ICONS"),2,.85);break;
      case 6: FakeCall(T(@"Нет номера",@"No Caller ID"),@"03:33");break;
      case 7: Screamer(T(@"НЕ ЗАКРЫВАЙ POVOZKA",@"DON'T CLOSE POVOZKA"),1,1.15);break;
      case 8: Respring();break;
      case 9: Thought(T(@"Это был настоящий respring. Но история продолжилась.",@"That was a real respring. But the story continued."));break;
      case 10: RedPulse(2.2);break;
      case 11: Screamer(@"MARA VEYL",0,1.05);break;
      case 12: FakeCall(T(@"Ты",@"You"),T(@"Вызов с этого iPhone",@"Call from this iPhone"));break;
      case 13: Screamer(T(@"ОНА УЖЕ В НАСТРОЙКАХ",@"SHE'S IN SETTINGS"),1,1.15);break;
      case 14: Thought(T(@"Имя Apple ID не настоящее. Но почему я всё равно испугался?",@"The Apple ID name isn't real. So why did it scare me?"));break;
      case 15: RedPulse(2.0);break;
      case 16: Screamer(T(@"НЕ ОТКРЫВАЙ ФОТО",@"DON'T OPEN PHOTOS"),2,.9);break;
      case 17: FakeCall(@"MARA // 03:33",T(@"Не отвечай",@"Do not answer"));break;
      case 18: Screamer(T(@"ТЫ ВСЁ РАВНО ОТКРЫЛ",@"YOU OPENED IT ANYWAY"),0,1.25);break;
      case 19: Thought(T(@"В галерее нет этих фотографий. Это только слой. Значит, её можно отключить.",@"Those photos aren't real. It's only a layer. That means I can shut it off."));break;
      case 20: Respring();break;
      case 21: Screamer(T(@"Я ВЕРНУЛАСЬ",@"I CAME BACK"),1,1.15);break;
      case 22: RedPulse(2.4);break;
      case 23: FakeCall(@"PovoZka",T(@"mara.unknown ждёт ответа…",@"mara.unknown is waiting for an answer…"));break;
      case 24: Thought(T(@"Теперь выбор за мной. Ответить ей — или оборвать сигнал.",@"Now it's my choice. Answer her — or cut the signal."));break;
      case 25: Screamer(T(@"РЕШИ СЕЙЧАС",@"CHOOSE NOW"),0,1.0);break;
    }
}
static void Tick(void){
    if(!Active() || Suppressed()) return;
    NSTimeInterval e=Elapsed();
    NSString *ending=Ending();

    if([ending isEqualToString:@"good"]){
        return;
    }
    if([ending isEqualToString:@"bad"] && e>=600){
        return;
    }

    NSArray *ts=Times();
    NSInteger last=LastEvent();
    for(NSInteger i=last+1;i<(NSInteger)ts.count;i++){
        if(e>=[ts[i] doubleValue]){
            SetLastEvent(i);
            Event(i);
            break;
        }
    }
}
static void StartTimer(void){
    [StoryTimer invalidate];StoryTimer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(__unused NSTimer *t){Tick();}];Tick();
}
static void Callback(CFNotificationCenterRef c,void *o,CFStringRef name,const void *obj,CFDictionaryRef u){
    NSString *n=(__bridge NSString*)name;
    dispatch_async(dispatch_get_main_queue(),^{
      if([n isEqualToString:NStart]){
          StartTimer();
      } else if([n isEqualToString:NRollback]){
          [StoryTimer invalidate];
          StoryTimer=nil;
          CloseWindow();
          Respring();
      } else if([n isEqualToString:NResume]){
          StartTimer();
          Respring();
      } else if([n isEqualToString:NGood]){
          CloseWindow();
          Screamer(T(@"СИГНАЛ ОБОРВАН",@"SIGNAL DISCONNECTED"),2,.7);
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.0*NSEC_PER_SEC)),dispatch_get_main_queue(),^{Respring();});
      } else if([n isEqualToString:NBad]){
          RedPulse(3.0);
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.2*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
              Screamer(T(@"ТЫ ОТВЕТИЛ ЕЙ",@"YOU ANSWERED HER"),1,1.4);
          });
      } else if([n isEqualToString:NTest]){
          Screamer(T(@"ТЕСТ СКРИМЕРА",@"TEST SCREAMER"),0,1.1);
      } else if([n isEqualToString:NRefresh]){
          Tick();
      }
    });
}

%group SpringBoardHooks
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)a{
    %orig;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NStart,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NRollback,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NTest,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NRefresh,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NResume,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NGood,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,Callback,(__bridge CFStringRef)NBad,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    StartTimer();
}
%end
%hook SBIconView
- (void)layoutSubviews{%orig;ApplyIcon((UIView*)self);}
%end
%hook SBRootFolderView
- (void)layoutSubviews{%orig;ApplyWallpaper((UIView*)self);}
%end
%hook CSCoverSheetViewController
- (void)viewDidAppear:(BOOL)a{%orig;LockOverlay(self.view);}
- (void)viewDidLayoutSubviews{%orig;LockOverlay(self.view);}
%end
%end

%group SettingsHooks
%hook UIViewController
- (void)viewDidAppear:(BOOL)a{%orig;if(self.view.window)SettingsOverlay(self.view);}
- (void)viewDidLayoutSubviews{%orig;if(self.view.window)SettingsOverlay(self.view);}
%end
%end

%group PhotosHooks
%hook UIViewController
- (void)viewDidAppear:(BOOL)a{%orig;if(self.view.window)PhotosOverlay(self.view);}
- (void)viewDidLayoutSubviews{%orig;if(self.view.window)PhotosOverlay(self.view);}
%end
%end

%ctor{
    LoadSound();
    NSString *bid=NSBundle.mainBundle.bundleIdentifier;
    if([bid isEqualToString:@"com.apple.springboard"])%init(SpringBoardHooks);
    else if([bid isEqualToString:@"com.apple.Preferences"])%init(SettingsHooks);
    else if([bid isEqualToString:@"com.apple.mobileslideshow"])%init(PhotosHooks);
}
