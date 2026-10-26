#import "ChatViewController.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const NSStatePath = @"/var/mobile/Library/Preferences/com.thxrealx7.nightsignal.state.plist";
static NSString * const NSStartNotification = @"com.thxrealx7.nightsignal/start";
static NSString * const NSGoodEndingNotification = @"com.thxrealx7.nightsignal/good";
static NSString * const NSBadEndingNotification = @"com.thxrealx7.nightsignal/bad";

@interface ChatViewController ()
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UILabel *typing;
@property (nonatomic, strong) UIButton *reply;
@property (nonatomic, strong) UIButton *goodButton;
@property (nonatomic, strong) UIButton *badButton;
@property (nonatomic, assign) NSInteger stage;
@property (nonatomic, assign) BOOL russian;
@property (nonatomic, strong) NSTimer *endingTimer;

- (UILabel *)bubbleWithText:(NSString *)text mine:(BOOL)mine;
- (void)addMessage:(NSString *)text mine:(BOOL)mine;
- (void)receiveMessage:(NSString *)text;
- (void)saveStage;
- (void)renderHistory;
- (void)nextMessage;
- (void)checkEndingChoice;
- (void)goodEnding;
- (void)badEnding;
@end

@implementation ChatViewController

static NSMutableDictionary *LoadState(void) {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:NSStatePath];
    return dictionary ? [dictionary mutableCopy] : [NSMutableDictionary dictionary];
}

static void SaveState(NSDictionary *dictionary) {
    [dictionary writeToFile:NSStatePath atomically:YES];
}

static void PostNotification(NSString *name) {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge CFStringRef)name,
        NULL,
        NULL,
        true
    );
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSDictionary *state = LoadState();
    self.russian = ![state[@"lang"] isEqualToString:@"en"];
    self.stage = [state[@"chatStage"] integerValue];

    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.045 blue:0.055 alpha:1.0];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;

    UILabel *navigationTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 190, 32)];
    navigationTitle.text = @"mara.unknown  •  offline";
    navigationTitle.textAlignment = NSTextAlignmentCenter;
    navigationTitle.textColor = UIColor.whiteColor;
    navigationTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.navigationItem.titleView = navigationTitle;

    self.scroll = [UIScrollView new];
    self.scroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.scroll.alwaysBounceVertical = YES;
    [self.view addSubview:self.scroll];

    self.stack = [UIStackView new];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.spacing = 9.0;
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scroll addSubview:self.stack];

    UIView *bottom = [UIView new];
    bottom.translatesAutoresizingMaskIntoConstraints = NO;
    bottom.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1.0];
    [self.view addSubview:bottom];

    self.typing = [UILabel new];
    self.typing.text = self.russian
        ? @"mara.unknown не в сети  •  by thxrealx7"
        : @"mara.unknown is offline  •  by thxrealx7";
    self.typing.textColor = [UIColor colorWithWhite:0.46 alpha:1.0];
    self.typing.font = [UIFont systemFontOfSize:11];
    self.typing.translatesAutoresizingMaskIntoConstraints = NO;
    [bottom addSubview:self.typing];

    self.reply = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.reply setTitle:(self.russian ? @"ОТВЕТИТЬ" : @"REPLY") forState:UIControlStateNormal];
    self.reply.backgroundColor = [UIColor colorWithRed:0.23 green:0.28 blue:0.36 alpha:1.0];
    [self.reply setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.reply.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.reply.layer.cornerRadius = 15.0;
    self.reply.translatesAutoresizingMaskIntoConstraints = NO;
    [self.reply addTarget:self action:@selector(nextMessage) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:self.reply];

    self.goodButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.goodButton setTitle:(self.russian ? @"ОБОРОТЬ СИГНАЛ" : @"DISCONNECT SIGNAL")
                     forState:UIControlStateNormal];
    self.goodButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.38 blue:0.22 alpha:1.0];
    [self.goodButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.goodButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.goodButton.layer.cornerRadius = 13.0;
    self.goodButton.hidden = YES;
    self.goodButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.goodButton addTarget:self action:@selector(goodEnding) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:self.goodButton];

    self.badButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.badButton setTitle:(self.russian ? @"ОТВЕТИТЬ: 03:33" : @"REPLY: 03:33")
                    forState:UIControlStateNormal];
    self.badButton.backgroundColor = [UIColor colorWithRed:0.55 green:0.02 blue:0.03 alpha:1.0];
    [self.badButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.badButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.badButton.layer.cornerRadius = 13.0;
    self.badButton.hidden = YES;
    self.badButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.badButton addTarget:self action:@selector(badEnding) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:self.badButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scroll.bottomAnchor constraintEqualToAnchor:bottom.topAnchor],

        [self.stack.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor constant:18.0],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor constant:14.0],
        [self.stack.trailingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.trailingAnchor constant:-14.0],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-18.0],
        [self.stack.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor constant:-28.0],

        [bottom.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bottom.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bottom.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [bottom.heightAnchor constraintEqualToConstant:158.0],

        [self.typing.topAnchor constraintEqualToAnchor:bottom.topAnchor constant:9.0],
        [self.typing.leadingAnchor constraintEqualToAnchor:bottom.leadingAnchor constant:16.0],
        [self.typing.trailingAnchor constraintEqualToAnchor:bottom.trailingAnchor constant:-16.0],

        [self.reply.topAnchor constraintEqualToAnchor:self.typing.bottomAnchor constant:8.0],
        [self.reply.leadingAnchor constraintEqualToAnchor:bottom.leadingAnchor constant:14.0],
        [self.reply.trailingAnchor constraintEqualToAnchor:bottom.trailingAnchor constant:-14.0],
        [self.reply.heightAnchor constraintEqualToConstant:46.0],

        [self.goodButton.topAnchor constraintEqualToAnchor:self.reply.bottomAnchor constant:7.0],
        [self.goodButton.leadingAnchor constraintEqualToAnchor:bottom.leadingAnchor constant:14.0],
        [self.goodButton.widthAnchor constraintEqualToAnchor:bottom.widthAnchor multiplier:0.46],
        [self.goodButton.heightAnchor constraintEqualToConstant:40.0],

        [self.badButton.topAnchor constraintEqualToAnchor:self.reply.bottomAnchor constant:7.0],
        [self.badButton.trailingAnchor constraintEqualToAnchor:bottom.trailingAnchor constant:-14.0],
        [self.badButton.widthAnchor constraintEqualToAnchor:bottom.widthAnchor multiplier:0.46],
        [self.badButton.heightAnchor constraintEqualToConstant:40.0]
    ]];

    [self renderHistory];

    if (self.stage >= 4) {
        [self.reply setTitle:(self.russian ? @"ИСТОРИЯ ЗАПУЩЕНА" : @"STORY STARTED")
                    forState:UIControlStateNormal];
        self.reply.enabled = NO;
    }

    self.endingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(checkEndingChoice)
                                                     userInfo:nil
                                                      repeats:YES];
    [self checkEndingChoice];

    if (self.stage == 0) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                [self receiveMessage:(self.russian
                    ? @"Ты видишь это сообщение?"
                    : @"Can you see this message?")];
                self.stage = 1;
                [self saveStage];
            }
        );
    }
}

- (void)dealloc {
    [self.endingTimer invalidate];
}

- (UILabel *)bubbleWithText:(NSString *)text mine:(BOOL)mine {
    UILabel *label = [UILabel new];
    label.text = text;
    label.numberOfLines = 0;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15];
    label.backgroundColor = mine
        ? [UIColor colorWithRed:0.15 green:0.38 blue:0.68 alpha:1.0]
        : [UIColor colorWithWhite:0.13 alpha:1.0];
    label.layer.cornerRadius = 16.0;
    label.clipsToBounds = YES;
    label.textAlignment = NSTextAlignmentLeft;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
    return label;
}

- (void)addMessage:(NSString *)text mine:(BOOL)mine {
    UIView *row = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *label = [self bubbleWithText:[NSString stringWithFormat:@"  %@  ", text] mine:mine];
    [row addSubview:label];

    NSLayoutConstraint *sideConstraint = mine
        ? [label.trailingAnchor constraintEqualToAnchor:row.trailingAnchor]
        : [label.leadingAnchor constraintEqualToAnchor:row.leadingAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:row.topAnchor],
        [label.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],
        [label.widthAnchor constraintLessThanOrEqualToAnchor:row.widthAnchor multiplier:0.82],
        sideConstraint
    ]];

    [self.stack addArrangedSubview:row];
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:46.0].active = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        CGFloat y = MAX(0.0, self.scroll.contentSize.height - self.scroll.bounds.size.height);
        [self.scroll setContentOffset:CGPointMake(0, y) animated:YES];
    });
}

- (void)receiveMessage:(NSString *)text {
    self.typing.text = self.russian
        ? @"mara.unknown печатает…"
        : @"mara.unknown is typing…";

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            [self addMessage:text mine:NO];
            self.typing.text = self.russian
                ? @"mara.unknown не в сети  •  by thxrealx7"
                : @"mara.unknown is offline  •  by thxrealx7";
        }
    );
}

- (void)saveStage {
    NSMutableDictionary *state = LoadState();
    state[@"chatStage"] = @(self.stage);
    SaveState(state);
}

- (void)renderHistory {
    if (self.stage >= 1) {
        [self addMessage:(self.russian ? @"Ты видишь это сообщение?" : @"Can you see this message?") mine:NO];
    }
    if (self.stage >= 2) {
        [self addMessage:(self.russian ? @"Кто ты?" : @"Who are you?") mine:YES];
        [self addMessage:(self.russian ? @"Пока никто. Не закрывай чат." : @"No one yet. Don't close the chat.") mine:NO];
    }
    if (self.stage >= 3) {
        [self addMessage:(self.russian ? @"Что значит «пока»?" : @"What does “yet” mean?") mine:YES];
        [self addMessage:(self.russian ? @"Через несколько секунд Safari сменит имя." : @"In a few seconds Safari will change its name.") mine:NO];
    }
    if (self.stage >= 4) {
        [self addMessage:(self.russian ? @"Это невозможно." : @"That's impossible.") mine:YES];
        [self addMessage:@"MARA // 03:33" mine:NO];
    }
}

- (void)nextMessage {
    if (self.stage < 1) {
        return;
    }

    if (self.stage == 1) {
        [self addMessage:(self.russian ? @"Кто ты?" : @"Who are you?") mine:YES];
        [self receiveMessage:(self.russian ? @"Пока никто. Не закрывай чат." : @"No one yet. Don't close the chat.")];
        self.stage = 2;
    } else if (self.stage == 2) {
        [self addMessage:(self.russian ? @"Что значит «пока»?" : @"What does “yet” mean?") mine:YES];
        [self receiveMessage:(self.russian
            ? @"Через несколько секунд Safari сменит имя."
            : @"In a few seconds Safari will change its name.")];
        self.stage = 3;
    } else if (self.stage == 3) {
        [self addMessage:(self.russian ? @"Это невозможно." : @"That's impossible.") mine:YES];
        [self receiveMessage:@"MARA // 03:33"];
        self.stage = 4;

        NSMutableDictionary *state = LoadState();
        state[@"active"] = @YES;
        state[@"suppressed"] = @NO;
        state[@"pauseStart"] = @0;
        state[@"ending"] = @"";
        state[@"startTime"] = @([[NSDate date] timeIntervalSince1970]);
        state[@"lastEvent"] = @(-1);
        state[@"chatStage"] = @(self.stage);
        SaveState(state);

        PostNotification(NSStartNotification);

        [self.reply setTitle:(self.russian ? @"ИСТОРИЯ ЗАПУЩЕНА" : @"STORY STARTED")
                    forState:UIControlStateNormal];
        self.reply.enabled = NO;
    }

    [self saveStage];
}

- (void)checkEndingChoice {
    NSDictionary *state = LoadState();

    if (![state[@"active"] boolValue] || [state[@"suppressed"] boolValue]) {
        self.goodButton.hidden = YES;
        self.badButton.hidden = YES;
        return;
    }

    NSString *ending = state[@"ending"] ?: @"";
    if (ending.length > 0) {
        self.goodButton.hidden = YES;
        self.badButton.hidden = YES;
        return;
    }

    NSTimeInterval startTime = [state[@"startTime"] doubleValue];
    if (startTime <= 0) {
        return;
    }

    NSTimeInterval elapsed = [[NSDate date] timeIntervalSince1970] - startTime;
    if (elapsed >= 540.0) {
        self.reply.hidden = YES;
        self.goodButton.hidden = NO;
        self.badButton.hidden = NO;
        self.typing.text = self.russian
            ? @"mara.unknown ждёт твоего решения"
            : @"mara.unknown is waiting for your choice";
    }
}

- (void)goodEnding {
    NSMutableDictionary *state = LoadState();
    state[@"ending"] = @"good";
    state[@"active"] = @YES;
    SaveState(state);

    [self addMessage:(self.russian
        ? @"Я отключаю сигнал. Больше не пиши."
        : @"I'm cutting the signal. Don't write again.") mine:YES];
    [self receiveMessage:(self.russian ? @"...связь потеряна" : @"...connection lost")];

    self.goodButton.hidden = YES;
    self.badButton.hidden = YES;
    PostNotification(NSGoodEndingNotification);
}

- (void)badEnding {
    NSMutableDictionary *state = LoadState();
    state[@"ending"] = @"bad";
    state[@"active"] = @YES;
    SaveState(state);

    [self addMessage:@"03:33" mine:YES];
    [self receiveMessage:(self.russian ? @"теперь ты слышишь меня" : @"now you can hear me")];

    self.goodButton.hidden = YES;
    self.badButton.hidden = YES;
    PostNotification(NSBadEndingNotification);
}

@end
