#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const NSStatePath = @"/var/mobile/Library/Preferences/com.thxrealx7.nightsignal.state.plist";
static NSString * const NSRollbackNotification = @"com.thxrealx7.nightsignal/rollback";
static NSString * const NSTestNotification = @"com.thxrealx7.nightsignal/test";
static NSString * const NSResumeNotification = @"com.thxrealx7.nightsignal/resume";

@interface RootViewController ()
@property (nonatomic, strong) UILabel *chapter;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) UILabel *clock;
@property (nonatomic, strong) UILabel *langLabel;
@property (nonatomic, strong) UIProgressView *bar;
@property (nonatomic, strong) NSTimer *timer;

- (UIButton *)makeButton:(NSString *)title color:(UIColor *)color selector:(SEL)selector;
- (void)selectRussian;
- (void)selectEnglish;
- (void)testScare;
- (void)enableSafeMode;
- (void)resumeStory;
- (NSString *)chapterForElapsed:(NSTimeInterval)elapsed russian:(BOOL)russian;
- (void)refresh;
@end

@implementation RootViewController

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

- (UIButton *)makeButton:(NSString *)title color:(UIColor *)color selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    button.backgroundColor = color;
    button.layer.cornerRadius = 15.0;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.heightAnchor constraintEqualToConstant:50.0].active = YES;
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.025 green:0.025 blue:0.03 alpha:1.0];

    UILabel *title = [UILabel new];
    title.text = @"NIGHT SIGNAL";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBlack];

    UILabel *subtitle = [UILabel new];
    subtitle.text = @"MARA // 03:33";
    subtitle.textColor = UIColor.systemRedColor;
    subtitle.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightBold];

    self.chapter = [UILabel new];
    self.chapter.textColor = UIColor.whiteColor;
    self.chapter.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.chapter.numberOfLines = 0;

    self.status = [UILabel new];
    self.status.textColor = [UIColor colorWithWhite:0.67 alpha:1.0];
    self.status.font = [UIFont systemFontOfSize:14];
    self.status.numberOfLines = 0;

    self.bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.bar.progressTintColor = UIColor.systemRedColor;
    self.bar.trackTintColor = [UIColor colorWithWhite:0.17 alpha:1.0];

    self.clock = [UILabel new];
    self.clock.textColor = [UIColor colorWithWhite:0.56 alpha:1.0];
    self.clock.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];

    self.langLabel = [UILabel new];
    self.langLabel.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
    self.langLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];

    UIButton *ruButton = [self makeButton:@"RU"
                                    color:[UIColor colorWithWhite:0.16 alpha:1.0]
                                 selector:@selector(selectRussian)];
    UIButton *enButton = [self makeButton:@"EN"
                                    color:[UIColor colorWithWhite:0.16 alpha:1.0]
                                 selector:@selector(selectEnglish)];

    UIStackView *languages = [[UIStackView alloc] initWithArrangedSubviews:@[ruButton, enButton]];
    languages.axis = UILayoutConstraintAxisHorizontal;
    languages.spacing = 10.0;
    languages.distribution = UIStackViewDistributionFillEqually;

    UIButton *testButton = [self makeButton:@"TEST SCREAMER"
                                      color:[UIColor colorWithWhite:0.17 alpha:1.0]
                                   selector:@selector(testScare)];

    UIButton *safeModeButton = [self makeButton:@"ОТКАТ / SAFE MODE"
                                          color:UIColor.whiteColor
                                       selector:@selector(enableSafeMode)];
    [safeModeButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];

    UIButton *resumeButton = [self makeButton:@"ПРОДОЛЖИТЬ / RESUME STORY"
                                        color:[UIColor colorWithRed:0.19 green:0.34 blue:0.22 alpha:1.0]
                                     selector:@selector(resumeStory)];

    UILabel *warning = [UILabel new];
    warning.text = @"⚠ Story resprings can close foreground apps. Unsaved data may be lost / Несохранённые данные в открытых приложениях могут не сохраниться.";
    warning.textColor = [UIColor colorWithRed:1.0 green:0.65 blue:0.25 alpha:1.0];
    warning.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    warning.numberOfLines = 0;

    UILabel *snowboard = [UILabel new];
    snowboard.text = @"Best experience: keep icon labels visible in SnowBoard. SAFE MODE pauses the story and temporarily restores a normal-looking phone.";
    snowboard.textColor = [UIColor colorWithWhite:0.46 alpha:1.0];
    snowboard.font = [UIFont systemFontOfSize:12];
    snowboard.numberOfLines = 0;

    UILabel *developer = [UILabel new];
    developer.text = @"Разработчик: thxrealx7  •  TikTok: @thxrealx7  •  v1.0";
    developer.textColor = [UIColor colorWithWhite:0.38 alpha:1.0];
    developer.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    developer.textAlignment = NSTextAlignmentCenter;
    developer.numberOfLines = 0;

    NSArray<UIView *> *views = @[
        title,
        subtitle,
        self.chapter,
        self.status,
        self.bar,
        self.clock,
        self.langLabel,
        languages,
        testButton,
        safeModeButton,
        resumeButton,
        warning,
        snowboard,
        developer
    ];

    for (UIView *view in views) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:view];
    }

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4.0],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [self.chapter.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:28.0],
        [self.chapter.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.chapter.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [self.status.topAnchor constraintEqualToAnchor:self.chapter.bottomAnchor constant:8.0],
        [self.status.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.status.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [self.bar.topAnchor constraintEqualToAnchor:self.status.bottomAnchor constant:18.0],
        [self.bar.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [self.clock.topAnchor constraintEqualToAnchor:self.bar.bottomAnchor constant:8.0],
        [self.clock.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [self.langLabel.topAnchor constraintEqualToAnchor:self.clock.bottomAnchor constant:20.0],
        [self.langLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [languages.topAnchor constraintEqualToAnchor:self.langLabel.bottomAnchor constant:8.0],
        [languages.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [languages.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [testButton.topAnchor constraintEqualToAnchor:languages.bottomAnchor constant:18.0],
        [testButton.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [testButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [safeModeButton.topAnchor constraintEqualToAnchor:testButton.bottomAnchor constant:10.0],
        [safeModeButton.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [safeModeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [resumeButton.topAnchor constraintEqualToAnchor:safeModeButton.bottomAnchor constant:10.0],
        [resumeButton.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [resumeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [warning.topAnchor constraintEqualToAnchor:resumeButton.bottomAnchor constant:14.0],
        [warning.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [warning.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [snowboard.topAnchor constraintEqualToAnchor:warning.bottomAnchor constant:10.0],
        [snowboard.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [snowboard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [developer.topAnchor constraintEqualToAnchor:snowboard.bottomAnchor constant:12.0],
        [developer.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [developer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [developer.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10.0]
    ]];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(refresh)
                                                userInfo:nil
                                                 repeats:YES];
    [self refresh];
}

- (void)dealloc {
    [self.timer invalidate];
}

- (void)selectRussian {
    NSMutableDictionary *state = LoadState();
    state[@"lang"] = @"ru";
    SaveState(state);
    [self refresh];
}

- (void)selectEnglish {
    NSMutableDictionary *state = LoadState();
    state[@"lang"] = @"en";
    SaveState(state);
    [self refresh];
}

- (void)testScare {
    PostNotification(NSTestNotification);
}

- (void)enableSafeMode {
    NSMutableDictionary *state = LoadState();

    if (![state[@"active"] boolValue]) {
        self.status.text = @"Story is not active.";
        return;
    }

    if ([state[@"suppressed"] boolValue]) {
        self.status.text = @"SAFE MODE is already active.";
        return;
    }

    state[@"suppressed"] = @YES;
    state[@"pauseStart"] = @([[NSDate date] timeIntervalSince1970]);
    SaveState(state);

    self.status.text = @"SAFE MODE enabled. Story paused. Respringing to normal appearance…";
    PostNotification(NSRollbackNotification);
}

- (void)resumeStory {
    NSMutableDictionary *state = LoadState();

    if (![state[@"active"] boolValue] || ![state[@"suppressed"] boolValue]) {
        self.status.text = @"Nothing to resume.";
        return;
    }

    NSTimeInterval pauseStart = [state[@"pauseStart"] doubleValue];
    NSTimeInterval storyStart = [state[@"startTime"] doubleValue];

    if (pauseStart > 0 && storyStart > 0) {
        NSTimeInterval pausedFor = MAX(0, [[NSDate date] timeIntervalSince1970] - pauseStart);
        state[@"startTime"] = @(storyStart + pausedFor);
    }

    state[@"suppressed"] = @NO;
    state[@"pauseStart"] = @0;
    SaveState(state);

    self.status.text = @"Story resumed. Respringing back into Night Signal…";
    PostNotification(NSResumeNotification);
}

- (NSString *)chapterForElapsed:(NSTimeInterval)elapsed russian:(BOOL)russian {
    if (elapsed < 60) {
        return russian ? @"Глава 1 — Сообщение" : @"Chapter 1 — The message";
    }
    if (elapsed < 120) {
        return russian ? @"Глава 2 — Голос" : @"Chapter 2 — The voice";
    }
    if (elapsed < 180) {
        return russian ? @"Глава 3 — Иконки" : @"Chapter 3 — The icons";
    }
    if (elapsed < 240) {
        return russian ? @"Глава 4 — После respring" : @"Chapter 4 — After respring";
    }
    if (elapsed < 330) {
        return russian ? @"Глава 5 — MARA" : @"Chapter 5 — MARA";
    }
    if (elapsed < 420) {
        return russian ? @"Глава 6 — Галерея" : @"Chapter 6 — The gallery";
    }
    if (elapsed < 480) {
        return russian ? @"Глава 7 — Второй respring" : @"Chapter 7 — Second respring";
    }
    if (elapsed < 565) {
        return russian ? @"Глава 8 — Unknown" : @"Chapter 8 — Unknown";
    }
    return russian ? @"Глава 9 — Выбор" : @"Chapter 9 — The choice";
}

- (void)refresh {
    NSDictionary *state = LoadState();
    BOOL russian = ![state[@"lang"] isEqualToString:@"en"];
    BOOL active = [state[@"active"] boolValue];
    BOOL suppressed = [state[@"suppressed"] boolValue];
    NSString *ending = state[@"ending"] ?: @"";

    NSTimeInterval startTime = [state[@"startTime"] doubleValue];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

    if (suppressed) {
        NSTimeInterval pauseStart = [state[@"pauseStart"] doubleValue];
        if (pauseStart > 0) {
            now = pauseStart;
        }
    }

    NSTimeInterval elapsed = (active && startTime > 0) ? MAX(0, now - startTime) : 0;
    elapsed = MIN(elapsed, 600.0);

    NSInteger seconds = (NSInteger)elapsed;
    self.clock.text = [NSString stringWithFormat:@"%02ld:%02ld / 10:00",
                       (long)(seconds / 60),
                       (long)(seconds % 60)];
    self.bar.progress = (float)(elapsed / 600.0);
    self.chapter.text = [self chapterForElapsed:elapsed russian:russian];
    self.langLabel.text = russian ? @"Язык истории: Русский" : @"Story language: English";

    if (!active) {
        self.status.text = russian
            ? @"История запускается из PovoZka. Открой чат mara.unknown."
            : @"The story starts in PovoZka. Open the mara.unknown chat.";
    } else if (suppressed) {
        self.status.text = russian
            ? @"ОТКАТ включён. Телефон в безопасном режиме, сюжет на паузе. Нажми ПРОДОЛЖИТЬ, когда будешь готов."
            : @"SAFE MODE is active. The phone is normal-looking and the story is paused. Tap RESUME when ready.";
    } else if ([ending isEqualToString:@"good"]) {
        self.status.text = russian
            ? @"Хорошая концовка: сигнал MARA оборван."
            : @"Good ending: MARA's signal was disconnected.";
    } else if ([ending isEqualToString:@"bad"]) {
        self.status.text = russian
            ? @"Плохая концовка: ты ответил MARA. ОТКАТ всё ещё доступен как системная функция."
            : @"Bad ending: you answered MARA. SAFE MODE is still available as a system function.";
    } else if (elapsed >= 540) {
        self.status.text = russian
            ? @"Финальный выбор теперь находится в PovoZka."
            : @"The final choice is now waiting in PovoZka.";
    } else {
        self.status.text = russian
            ? @"История идёт в SpringBoard. ОТКАТ можно включить в любой момент без завершения сюжета."
            : @"The story is running in SpringBoard. SAFE MODE can be used anytime without ending the story.";
    }
}

@end
