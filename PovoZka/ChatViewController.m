#import "ChatViewController.h"
#import <QuartzCore/QuartzCore.h>
static NSString * const P=@"/var/mobile/Library/Preferences/com.thxrealx7.nightsignal.state.plist";
static NSString * const START=@"com.thxrealx7.nightsignal/start";
static NSString * const GOOD=@"com.thxrealx7.nightsignal/good";
static NSString * const BAD=@"com.thxrealx7.nightsignal/bad";
@interface ChatViewController()
@property UIStackView *stack;@property UIScrollView *scroll;@property UILabel *typing;@property UIButton *reply;@property UIButton *goodButton;@property UIButton *badButton;@property NSInteger stage;@property BOOL ru;@property NSTimer *endingTimer;

- (void)checkEndingChoice{
 NSDictionary*s=L();
 if(![s[@"active"] boolValue] || [s[@"suppressed"] boolValue])return;
 if([s[@"ending"] length]>0){
   self.goodButton.hidden=YES;self.badButton.hidden=YES;return;
 }
 NSTimeInterval st=[s[@"startTime"] doubleValue];
 if(st<=0)return;
 NSTimeInterval e=[[NSDate date]timeIntervalSince1970]-st;
 if(e>=540){
   self.reply.hidden=YES;
   self.goodButton.hidden=NO;
   self.badButton.hidden=NO;
   self.typing.text=self.ru?@"mara.unknown ждёт твоего решения":@"mara.unknown is waiting for your choice";
 }
}
- (void)goodEnding{
 NSMutableDictionary*s=L();s[@"ending"]=@"good";s[@"active"]=@YES;S(s);
 [self add:self.ru?@"Я отключаю сигнал. Больше не пиши.":@"I'm cutting the signal. Don't write again." mine:YES];
 [self receive:self.ru?@"...связь потеряна":@"...connection lost"];
 self.goodButton.hidden=YES;self.badButton.hidden=YES;
 Post(GOOD);
}
- (void)badEnding{
 NSMutableDictionary*s=L();s[@"ending"]=@"bad";s[@"active"]=@YES;S(s);
 [self add:@"03:33" mine:YES];
 [self receive:self.ru?@"теперь ты слышишь меня":@"now you can hear me"];
 self.goodButton.hidden=YES;self.badButton.hidden=YES;
 Post(BAD);
}

@end
@implementation ChatViewController
static NSMutableDictionary *L(void){NSDictionary*d=[NSDictionary dictionaryWithContentsOfFile:P];return d?[d mutableCopy]:[NSMutableDictionary dictionary];}
static void S(NSDictionary*d){[d writeToFile:P atomically:YES];}
static void Post(NSString*n){CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)n,NULL,NULL,true);}
- (void)viewDidLoad{
 [super viewDidLoad];NSDictionary*s=L();self.ru=![s[@"lang"] isEqualToString:@"en"];self.stage=[s[@"chatStage"] integerValue];
 self.view.backgroundColor=[UIColor colorWithRed:.04 green:.045 blue:.055 alpha:1];
 self.navigationItem.title=@"mara.unknown";
 self.navigationController.navigationBar.barStyle=UIBarStyleBlack;self.navigationController.navigationBar.tintColor=UIColor.whiteColor;
 UILabel*sub=[[UILabel alloc]initWithFrame:CGRectMake(0,0,180,30)];sub.text=@"mara.unknown  •  offline";sub.textAlignment=NSTextAlignmentCenter;sub.textColor=UIColor.whiteColor;sub.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];self.navigationItem.titleView=sub;
 self.scroll=[UIScrollView new];self.scroll.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:self.scroll];
 self.stack=[[UIStackView alloc]init];self.stack.axis=UILayoutConstraintAxisVertical;self.stack.spacing=9;self.stack.translatesAutoresizingMaskIntoConstraints=NO;[self.scroll addSubview:self.stack];
 UIView*bottom=[UIView new];bottom.translatesAutoresizingMaskIntoConstraints=NO;bottom.backgroundColor=[UIColor colorWithWhite:.07 alpha:1];[self.view addSubview:bottom];
 self.typing=[UILabel new];self.typing.text=self.ru?@"mara.unknown не в сети  •  by thxrealx7":@"mara.unknown is offline  •  by thxrealx7";self.typing.textColor=[UIColor colorWithWhite:.46 alpha:1];self.typing.font=[UIFont systemFontOfSize:11];self.typing.translatesAutoresizingMaskIntoConstraints=NO;[bottom addSubview:self.typing];
 self.reply=[UIButton buttonWithType:UIButtonTypeSystem];[self.reply setTitle:self.ru?@"ОТВЕТИТЬ":@"REPLY" forState:UIControlStateNormal];self.reply.backgroundColor=[UIColor colorWithRed:.23 green:.28 blue:.36 alpha:1];[self.reply setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];self.reply.titleLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightBold];self.reply.layer.cornerRadius=15;self.reply.translatesAutoresizingMaskIntoConstraints=NO;[self.reply addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];[bottom addSubview:self.reply];
 self.goodButton=[UIButton buttonWithType:UIButtonTypeSystem];
 [self.goodButton setTitle:self.ru?@"ОБОРОТЬ СИГНАЛ":@"DISCONNECT SIGNAL" forState:UIControlStateNormal];
 self.goodButton.backgroundColor=[UIColor colorWithRed:.10 green:.38 blue:.22 alpha:1];
 [self.goodButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
 self.goodButton.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightBold];
 self.goodButton.layer.cornerRadius=13;
 self.goodButton.hidden=YES;
 self.goodButton.translatesAutoresizingMaskIntoConstraints=NO;
 [self.goodButton addTarget:self action:@selector(goodEnding) forControlEvents:UIControlEventTouchUpInside];
 [bottom addSubview:self.goodButton];

 self.badButton=[UIButton buttonWithType:UIButtonTypeSystem];
 [self.badButton setTitle:@"ОТВЕТИТЬ: 03:33" forState:UIControlStateNormal];
 self.badButton.backgroundColor=[UIColor colorWithRed:.55 green:.02 blue:.03 alpha:1];
 [self.badButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
 self.badButton.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightBold];
 self.badButton.layer.cornerRadius=13;
 self.badButton.hidden=YES;
 self.badButton.translatesAutoresizingMaskIntoConstraints=NO;
 [self.badButton addTarget:self action:@selector(badEnding) forControlEvents:UIControlEventTouchUpInside];
 [bottom addSubview:self.badButton];

 [NSLayoutConstraint activateConstraints:@[
 [self.scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],[self.scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[self.scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[self.scroll.bottomAnchor constraintEqualToAnchor:bottom.topAnchor],
 [self.stack.topAnchor constraintEqualToAnchor:self.scroll.topAnchor constant:18],[self.stack.leadingAnchor constraintEqualToAnchor:self.scroll.leadingAnchor constant:14],[self.stack.trailingAnchor constraintEqualToAnchor:self.scroll.trailingAnchor constant:-14],[self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.bottomAnchor constant:-18],[self.stack.widthAnchor constraintEqualToAnchor:self.scroll.widthAnchor constant:-28],
 [bottom.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[bottom.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[bottom.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[bottom.heightAnchor constraintEqualToConstant:158],
 [self.typing.topAnchor constraintEqualToAnchor:bottom.topAnchor constant:9],[self.typing.leadingAnchor constraintEqualToAnchor:bottom.leadingAnchor constant:16],
 [self.reply.topAnchor constraintEqualToAnchor:self.typing.bottomAnchor constant:8],[self.reply.leadingAnchor constraintEqualToAnchor:bottom.leadingAnchor constant:14],[self.reply.trailingAnchor constraintEqualToAnchor:bottom.trailingAnchor constant:-14],[self.reply.heightAnchor constraintEqualToConstant:46],
 [self.goodButton.topAnchor constraintEqualToAnchor:self.reply.bottomAnchor constant:7],[self.goodButton.leadingAnchor constraintEqualToAnchor:bottom.leadingAnchor constant:14],[self.goodButton.widthAnchor constraintEqualToAnchor:bottom.widthAnchor multiplier:.46],[self.goodButton.heightAnchor constraintEqualToConstant:40],
 [self.badButton.topAnchor constraintEqualToAnchor:self.reply.bottomAnchor constant:7],[self.badButton.trailingAnchor constraintEqualToAnchor:bottom.trailingAnchor constant:-14],[self.badButton.widthAnchor constraintEqualToAnchor:bottom.widthAnchor multiplier:.46],[self.badButton.heightAnchor constraintEqualToConstant:40]
 ]];
 [self renderHistory];
 self.endingTimer=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkEndingChoice) userInfo:nil repeats:YES];
 [self checkEndingChoice];
 if(self.stage==0)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.6*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[self receive:self.ru?@"Ты видишь это сообщение?":@"Can you see this message?"];self.stage=1;[self save];});
}
- (UILabel*)bubble:(NSString*)text mine:(BOOL)mine{
 UILabel*l=[UILabel new];l.text=text;l.numberOfLines=0;l.textColor=UIColor.whiteColor;l.font=[UIFont systemFontOfSize:15];
 l.backgroundColor=mine?[UIColor colorWithRed:.15 green:.38 blue:.68 alpha:1]:[UIColor colorWithWhite:.13 alpha:1];
 l.layer.cornerRadius=16;l.clipsToBounds=YES;l.layoutMargins=UIEdgeInsetsMake(10,12,10,12);
 l.translatesAutoresizingMaskIntoConstraints=NO;[l.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
 return l;
}
- (void)add:(NSString*)text mine:(BOOL)mine{
 UIView*row=[UIView new];row.translatesAutoresizingMaskIntoConstraints=NO;UILabel*l=[self bubble:text mine:mine];[row addSubview:l];
 [NSLayoutConstraint activateConstraints:@[[l.topAnchor constraintEqualToAnchor:row.topAnchor],[l.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],[l.widthAnchor constraintLessThanOrEqualToAnchor:row.widthAnchor multiplier:.82], mine?[l.trailingAnchor constraintEqualToAnchor:row.trailingAnchor]:[l.leadingAnchor constraintEqualToAnchor:row.leadingAnchor]]];
 [self.stack addArrangedSubview:row];[row.heightAnchor constraintGreaterThanOrEqualToConstant:46].active=YES;
 dispatch_async(dispatch_get_main_queue(),^{CGPoint p=CGPointMake(0,MAX(0,self.scroll.contentSize.height-self.scroll.bounds.size.height));[self.scroll setContentOffset:p animated:YES];});
}
- (void)receive:(NSString*)t{self.typing.text=self.ru?@"mara.unknown печатает…":@"mara.unknown is typing…";dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.8*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[self add:t mine:NO];self.typing.text=self.ru?@"mara.unknown не в сети  •  by thxrealx7":@"mara.unknown is offline  •  by thxrealx7";});}
- (void)save{NSMutableDictionary*s=L();s[@"chatStage"]=@(self.stage);S(s);}
- (void)renderHistory{
 if(self.stage>=1)[self add:self.ru?@"Ты видишь это сообщение?":@"Can you see this message?" mine:NO];
 if(self.stage>=2){[self add:self.ru?@"Кто ты?":@"Who are you?" mine:YES];[self add:self.ru?@"Пока никто. Не закрывай чат.":@"No one yet. Don't close the chat." mine:NO];}
 if(self.stage>=3){[self add:self.ru?@"Что значит «пока»?":@"What does “yet” mean?" mine:YES];[self add:self.ru?@"Через несколько секунд Safari сменит имя.":@"In a few seconds Safari will change its name." mine:NO];}
 if(self.stage>=4){[self add:self.ru?@"Это невозможно.":@"That's impossible." mine:YES];[self add:@"MARA // 03:33" mine:NO];}
}
- (void)next{
 if(self.stage<1)return;
 if(self.stage==1){[self add:self.ru?@"Кто ты?":@"Who are you?" mine:YES];[self receive:self.ru?@"Пока никто. Не закрывай чат.":@"No one yet. Don't close the chat."];self.stage=2;}
 else if(self.stage==2){[self add:self.ru?@"Что значит «пока»?":@"What does “yet” mean?" mine:YES];[self receive:self.ru?@"Через несколько секунд Safari сменит имя.":@"In a few seconds Safari will change its name."];self.stage=3;}
 else if(self.stage==3){[self add:self.ru?@"Это невозможно.":@"That's impossible." mine:YES];[self receive:@"MARA // 03:33"];self.stage=4;NSMutableDictionary*s=L();s[@"active"]=@YES;s[@"suppressed"]=@NO;s[@"pauseStart"]=@0;s[@"ending"]=@"";s[@"startTime"]=@([[NSDate date]timeIntervalSince1970]);s[@"lastEvent"]=@(-1);s[@"chatStage"]=@(self.stage);S(s);Post(START);[self.reply setTitle:self.ru?@"ИСТОРИЯ ЗАПУЩЕНА":@"STORY STARTED" forState:UIControlStateNormal];self.reply.enabled=NO;}
 [self save];
}

- (void)checkEndingChoice{
 NSDictionary*s=L();
 if(![s[@"active"] boolValue] || [s[@"suppressed"] boolValue])return;
 if([s[@"ending"] length]>0){
   self.goodButton.hidden=YES;self.badButton.hidden=YES;return;
 }
 NSTimeInterval st=[s[@"startTime"] doubleValue];
 if(st<=0)return;
 NSTimeInterval e=[[NSDate date]timeIntervalSince1970]-st;
 if(e>=540){
   self.reply.hidden=YES;
   self.goodButton.hidden=NO;
   self.badButton.hidden=NO;
   self.typing.text=self.ru?@"mara.unknown ждёт твоего решения":@"mara.unknown is waiting for your choice";
 }
}
- (void)goodEnding{
 NSMutableDictionary*s=L();s[@"ending"]=@"good";s[@"active"]=@YES;S(s);
 [self add:self.ru?@"Я отключаю сигнал. Больше не пиши.":@"I'm cutting the signal. Don't write again." mine:YES];
 [self receive:self.ru?@"...связь потеряна":@"...connection lost"];
 self.goodButton.hidden=YES;self.badButton.hidden=YES;
 Post(GOOD);
}
- (void)badEnding{
 NSMutableDictionary*s=L();s[@"ending"]=@"bad";s[@"active"]=@YES;S(s);
 [self add:@"03:33" mine:YES];
 [self receive:self.ru?@"теперь ты слышишь меня":@"now you can hear me"];
 self.goodButton.hidden=YES;self.badButton.hidden=YES;
 Post(BAD);
}

@end
