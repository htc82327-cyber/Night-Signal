#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
static NSString * const P=@"/var/mobile/Library/Preferences/com.thxrealx7.nightsignal.state.plist";
static NSString * const R=@"com.thxrealx7.nightsignal/rollback";
static NSString * const TST=@"com.thxrealx7.nightsignal/test";
static NSString * const RESUME=@"com.thxrealx7.nightsignal/resume";

@interface RootViewController()
@property UILabel *chapter,*status,*clock,*langLabel;
@property UIProgressView *bar;
@property NSTimer *timer;
@end
@implementation RootViewController
static NSMutableDictionary *L(void){NSDictionary*d=[NSDictionary dictionaryWithContentsOfFile:P];return d?[d mutableCopy]:[NSMutableDictionary dictionary];}
static void S(NSDictionary*d){[d writeToFile:P atomically:YES];}
static void Post(NSString*n){CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)n,NULL,NULL,true);}
- (UIButton*)button:(NSString*)t color:(UIColor*)c sel:(SEL)s{
 UIButton*b=[UIButton buttonWithType:UIButtonTypeSystem];[b setTitle:t forState:UIControlStateNormal];[b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];b.titleLabel.font=[UIFont systemFontOfSize:16 weight:UIFontWeightBold];b.backgroundColor=c;b.layer.cornerRadius=15;b.contentEdgeInsets=UIEdgeInsetsMake(15,12,15,12);[b addTarget:self action:s forControlEvents:UIControlEventTouchUpInside];return b;
}
- (void)viewDidLoad{
 [super viewDidLoad];self.view.backgroundColor=[UIColor colorWithRed:.025 green:.025 blue:.03 alpha:1];
 UILabel*title=[UILabel new];title.text=@"NIGHT SIGNAL";title.textColor=UIColor.whiteColor;title.font=[UIFont systemFontOfSize:34 weight:UIFontWeightBlack];
 UILabel*sub=[UILabel new];sub.text=@"MARA // 03:33";sub.textColor=UIColor.systemRedColor;sub.font=[UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightBold];
 self.chapter=[UILabel new];self.chapter.textColor=UIColor.whiteColor;self.chapter.font=[UIFont systemFontOfSize:18 weight:UIFontWeightBold];
 self.status=[UILabel new];self.status.textColor=[UIColor colorWithWhite:.67 alpha:1];self.status.font=[UIFont systemFontOfSize:14];self.status.numberOfLines=0;
 self.bar=[UIProgressView progressViewWithProgressViewStyle:UIProgressViewStyleDefault];self.bar.progressTintColor=UIColor.systemRedColor;self.bar.trackTintColor=[UIColor colorWithWhite:.17 alpha:1];
 self.clock=[UILabel new];self.clock.textColor=[UIColor colorWithWhite:.56 alpha:1];self.clock.font=[UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
 self.langLabel=[UILabel new];self.langLabel.textColor=[UIColor colorWithWhite:.7 alpha:1];self.langLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];

 UIButton*ru=[self button:@"RU" color:[UIColor colorWithWhite:.16 alpha:1] sel:@selector(ru)];
 UIButton*en=[self button:@"EN" color:[UIColor colorWithWhite:.16 alpha:1] sel:@selector(en)];
 UIStackView*langs=[[UIStackView alloc]initWithArrangedSubviews:@[ru,en]];langs.axis=UILayoutConstraintAxisHorizontal;langs.spacing=10;langs.distribution=UIStackViewDistributionFillEqually;

 UIButton*test=[self button:@"TEST SCREAMER" color:[UIColor colorWithWhite:.17 alpha:1] sel:@selector(test)];
 UIButton*rollback=[self button:@"ОТКАТ / SAFE MODE" color:UIColor.whiteColor sel:@selector(rollback)];
 [rollback setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
 UIButton*resume=[self button:@"ПРОДОЛЖИТЬ / RESUME STORY" color:[UIColor colorWithRed:.19 green:.34 blue:.22 alpha:1] sel:@selector(resumeStory)];
 UILabel*warning=[UILabel new];warning.text=@"⚠ Story resprings can close foreground apps. Unsaved data may be lost / Несохранённые данные в открытых приложениях могут не сохраниться.";
warning.textColor=[UIColor colorWithRed:1 green:.65 blue:.25 alpha:1];warning.font=[UIFont systemFontOfSize:12 weight:UIFontWeightMedium];warning.numberOfLines=0;
 UILabel*snow=[UILabel new];snow.text=@"Best experience: keep icon labels visible in SnowBoard. SAFE MODE pauses the story and temporarily restores a normal-looking phone.";
snow.textColor=[UIColor colorWithWhite:.46 alpha:1];snow.font=[UIFont systemFontOfSize:12];snow.numberOfLines=0;

 NSArray*views=@[title,sub,self.chapter,self.status,self.bar,self.clock,self.langLabel,langs,test,rollback,resume,warning,snow,developer];
 for(UIView*v in views){v.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:v];}
 [NSLayoutConstraint activateConstraints:@[
 [title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28],[title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
 [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],[sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
 [self.chapter.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:34],[self.chapter.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[self.chapter.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [self.status.topAnchor constraintEqualToAnchor:self.chapter.bottomAnchor constant:8],[self.status.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[self.status.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [self.bar.topAnchor constraintEqualToAnchor:self.status.bottomAnchor constant:18],[self.bar.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[self.bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [self.clock.topAnchor constraintEqualToAnchor:self.bar.bottomAnchor constant:8],[self.clock.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
 [self.langLabel.topAnchor constraintEqualToAnchor:self.clock.bottomAnchor constant:24],[self.langLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
 [langs.topAnchor constraintEqualToAnchor:self.langLabel.bottomAnchor constant:8],[langs.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[langs.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [test.topAnchor constraintEqualToAnchor:langs.bottomAnchor constant:22],[test.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[test.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [rollback.topAnchor constraintEqualToAnchor:test.bottomAnchor constant:12],[rollback.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[rollback.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [resume.topAnchor constraintEqualToAnchor:rollback.bottomAnchor constant:12],[resume.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[resume.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [warning.topAnchor constraintEqualToAnchor:resume.bottomAnchor constant:18],[warning.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[warning.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [snow.topAnchor constraintEqualToAnchor:warning.bottomAnchor constant:12],[snow.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[snow.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
 [developer.topAnchor constraintEqualToAnchor:snow.bottomAnchor constant:14],[developer.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[developer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24]
 ]];
 self.timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refresh) userInfo:nil repeats:YES];[self refresh];
}
- (void)ru{NSMutableDictionary*s=L();s[@"lang"]=@"ru";S(s);[self refresh];}
- (void)en{NSMutableDictionary*s=L();s[@"lang"]=@"en";S(s);[self refresh];}
- (void)test{Post(TST);}
- (void)rollback{
 NSMutableDictionary*s=L();
 if(![s[@"active"] boolValue]){
   self.status.text=@"Story is not active.";
   return;
 }
 if([s[@"suppressed"] boolValue]){
   self.status.text=@"SAFE MODE is already active.";
   return;
 }
 s[@"suppressed"]=@YES;
 s[@"pauseStart"]=@([[NSDate date]timeIntervalSince1970]);
 S(s);
 self.status.text=@"SAFE MODE enabled. Story paused. Respringing to normal appearance…";
 Post(R);
}

- (void)resumeStory{
 NSMutableDictionary*s=L();
 if(![s[@"active"] boolValue] || ![s[@"suppressed"] boolValue]){
   self.status.text=@"Nothing to resume.";
   return;
 }
 NSTimeInterval ps=[s[@"pauseStart"] doubleValue];
 NSTimeInterval st=[s[@"startTime"] doubleValue];
 if(ps>0 && st>0){
   NSTimeInterval pausedFor=MAX(0,[[NSDate date]timeIntervalSince1970]-ps);
   s[@"startTime"]=@(st+pausedFor);
 }
 s[@"suppressed"]=@NO;
 s[@"pauseStart"]=@0;
 S(s);
 self.status.text=@"Story resumed. Respringing back into Night Signal…";
 Post(RESUME);
}

- (void)refresh{
 NSDictionary*s=L();
 BOOL ru=![s[@"lang"] isEqualToString:@"en"];
 BOOL a=[s[@"active"] boolValue];
 BOOL suppressed=[s[@"suppressed"] boolValue];
 NSString*ending=s[@"ending"]?:@"";
 NSTimeInterval st=[s[@"startTime"] doubleValue];
 NSTimeInterval now=[[NSDate date]timeIntervalSince1970];
 if(suppressed){
   NSTimeInterval ps=[s[@"pauseStart"] doubleValue];
   if(ps>0)now=ps;
 }
 NSTimeInterval e=(a&&st>0)?MAX(0,now-st):0;
 if(e>600)e=600;

 NSInteger sec=(NSInteger)e;
 self.clock.text=[NSString stringWithFormat:@"%02ld:%02ld / 10:00",(long)(sec/60),(long)(sec%60)];
 self.bar.progress=e/600.0;
 self.chapter.text=[self chapter:e ru:ru];
 self.langLabel.text=ru?@"Язык истории: Русский":@"Story language: English";

 if(!a){
   self.status.text=ru?@"История запускается из PovoZka. Открой чат mara.unknown.":@"The story starts in PovoZka. Open the mara.unknown chat.";
 }else if(suppressed){
   self.status.text=ru?@"ОТКАТ включён. Телефон в безопасном режиме, сюжет на паузе. Нажми ПРОДОЛЖИТЬ, когда будешь готов.":@"SAFE MODE is active. The phone is normal-looking and the story is paused. Tap RESUME when ready.";
 }else if([ending isEqualToString:@"good"]){
   self.status.text=ru?@"Хорошая концовка: сигнал MARA оборван.":@"Good ending: MARA's signal was disconnected.";
 }else if([ending isEqualToString:@"bad"]){
   self.status.text=ru?@"Плохая концовка: ты ответил MARA. ОТКАТ всё ещё доступен как системная функция.":@"Bad ending: you answered MARA. SAFE MODE is still available as a system function.";
 }else if(e>=540){
   self.status.text=ru?@"Финальный выбор теперь находится в PovoZka.":@"The final choice is now waiting in PovoZka.";
 }else{
   self.status.text=ru?@"История идёт в SpringBoard. ОТКАТ можно включить в любой момент без завершения сюжета.":@"The story is running in SpringBoard. SAFE MODE can be used anytime without ending the story.";
 }
}
@end
