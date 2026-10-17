//
//  RootViewController.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>

#import "HUDHelper.h"
#import "MainApplication.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"
#import "../esp/drawing_view/obfusheader.h"

static const CGFloat _gAuthorLabelBottomConstraintConstantCompact = -20.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantRegular = -80.f;

@implementation RootViewController {
    UIButton *mainButton;
    UILabel *authorLabel;
    UILabel *poweredByLabel;
    NSLayoutConstraint *authorLabelBottomConstraint;
    NSLayoutConstraint *mainButtonCenterYConstraint;
    BOOL isRemoteHUDActive;
}

- (BOOL)isHUDEnabled
{
    return IsHUDEnabled();
}

- (void)setHUDEnabled:(BOOL)enabled
{
    SetHUDEnabled(enabled);
}

- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor blackColor];

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.backgroundView];

    // ── Анимированный фон — неоновые линии ──────────────────────────────
    UIView *animBg = [[UIView alloc] initWithFrame:bounds];
    animBg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    animBg.backgroundColor = [UIColor clearColor];
    animBg.clipsToBounds = YES;
    animBg.tag = 9001;
    [self.backgroundView addSubview:animBg];
    [self startNeonAnimation:animBg];

    // ── Версия iOS — белый прямоугольник, чёрный текст ──────────────────
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"  iOS %@  ", [[UIDevice currentDevice] systemVersion]];
    versionLabel.textColor = [UIColor colorWithRed:0.85 green:0.15 blue:0.15 alpha:1.0];
    versionLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    versionLabel.layer.cornerRadius = 8.0f;
    versionLabel.layer.masksToBounds = YES;
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:versionLabel];

    // ── Кнопка RUN Inject ────────────────────────────────────────────────
    mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mainButton.translatesAutoresizingMaskIntoConstraints = NO;
    mainButton.layer.cornerRadius = 16.0f;
    mainButton.layer.masksToBounds = NO;
    mainButton.layer.shadowColor = [UIColor colorWithRed:0.8 green:0.0 blue:1.0 alpha:1.0].CGColor;
    mainButton.layer.shadowOffset = CGSizeZero;
    mainButton.layer.shadowRadius = 12.0f;
    mainButton.layer.shadowOpacity = 0.8f;

    // Кнопка: тёмно-серая заливка, красная обводка, белый текст
    mainButton.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];
    mainButton.layer.borderWidth = 0.0f;
    mainButton.layer.shadowColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0].CGColor;
    mainButton.layer.shadowOffset = CGSizeZero;
    mainButton.layer.shadowRadius = 10.0f;
    mainButton.layer.shadowOpacity = 0.5f;

    [mainButton setAttributedTitle:nil forState:UIControlStateNormal];
    [mainButton setTitle:@"RUN Inject" forState:UIControlStateNormal];
    [mainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    mainButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    [mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    [mainButton addTarget:self action:@selector(btnTouchDown:) forControlEvents:UIControlEventTouchDown];
    [mainButton addTarget:self action:@selector(btnTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.backgroundView addSubview:mainButton];

    // ── Кнопка EXIT ──────────────────────────────────────────────────────
    UIButton *exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    exitButton.translatesAutoresizingMaskIntoConstraints = NO;
    exitButton.layer.cornerRadius = 10.0f;
    exitButton.layer.borderWidth = 1.5f;
    exitButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    [exitButton setTitle:@"EXIT" forState:UIControlStateNormal];
    [exitButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.6] forState:UIControlStateNormal];
    exitButton.titleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    [exitButton addTarget:self action:@selector(tapExitButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundView addSubview:exitButton];

    // ── WXR label ────────────────────────────────────────────────────────
    UILabel *linkLabel = [[UILabel alloc] init];
    linkLabel.text = @"WXR | IOS";
    linkLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    linkLabel.font = [UIFont systemFontOfSize:12.0f];
    linkLabel.textAlignment = NSTextAlignmentCenter;
    linkLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:linkLabel];

    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;

    mainButtonCenterYConstraint = [mainButton.centerYAnchor constraintEqualToAnchor:self.backgroundView.centerYAnchor constant:-20.0f];
    [NSLayoutConstraint activateConstraints:@[
        mainButtonCenterYConstraint,
        [mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [mainButton.widthAnchor constraintEqualToConstant:220.0f],
        [mainButton.heightAnchor constraintEqualToConstant:64.0f],

        [versionLabel.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:16.0f],
        [versionLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],

        [exitButton.topAnchor constraintEqualToAnchor:mainButton.bottomAnchor constant:20.0f],
        [exitButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [exitButton.widthAnchor constraintEqualToConstant:100.0f],
        [exitButton.heightAnchor constraintEqualToConstant:36.0f],

        [linkLabel.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-16.0f],
        [linkLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
    ]];

    [self verticalSizeClassUpdated];
    [self reloadMainButtonState];
}

- (void)btnTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.93f, 0.93f);
        sender.layer.shadowOpacity = 0.3f;
    }];
}

- (void)btnTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.15 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:6 options:0 animations:^{
        sender.transform = CGAffineTransformIdentity;
        sender.layer.shadowOpacity = 0.8f;
    } completion:nil];
}

- (void)tapExitButton:(UIButton *)sender {
    exit(0);
}

- (void)startNeonAnimation:(UIView *)container {
    // Запускаем таймер для периодического добавления линий
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.4 repeats:YES block:^(NSTimer *t) {
        if (!container.window) { [t invalidate]; return; }
        [self addNeonLine:container];
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    // Сразу добавим несколько линий
    for (int i = 0; i < 5; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addNeonLine:container];
        });
    }
}

- (void)addNeonLine:(UIView *)container {
    CGFloat W = container.bounds.size.width;
    CGFloat H = container.bounds.size.height;
    if (W == 0 || H == 0) {
        W = UIScreen.mainScreen.bounds.size.width;
        H = UIScreen.mainScreen.bounds.size.height;
    }

    // Толщина линии (жирная)
    CGFloat thickness = 14.0f + (arc4random_uniform(20));

    // Случайная Y-позиция — линия вертикальная, длина = высота экрана
    // Стартует за левым краем, движется вправо-вверх
    CGFloat startY = H * 0.3f + (arc4random_uniform(100) / 100.0f) * H * 0.7f;
    CGPoint startPt = CGPointMake(-thickness, startY);
    CGPoint endPt   = CGPointMake(W + thickness, startY - H * 0.6f);

    // Длина линии = высота экрана
    CGFloat lineLen = H;

    // Создаём градиентный слой — вертикальная линия
    CAGradientLayer *line = [CAGradientLayer layer];
    line.frame = CGRectMake(0, 0, thickness, lineLen);

    // Градиент по длине линии: красный → серый
    line.colors = @[
        (id)[UIColor colorWithRed:0.6 green:0.0 blue:0.0 alpha:0.0].CGColor,
        (id)[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:0.75].CGColor,
        (id)[UIColor colorWithRed:0.5 green:0.1 blue:0.1 alpha:0.75].CGColor,
        (id)[UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:0.75].CGColor,
        (id)[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.0].CGColor,
    ];
    line.startPoint = CGPointMake(0.5, 0);
    line.endPoint   = CGPointMake(0.5, 1);
    line.cornerRadius = thickness / 2.0f;

    // Позиционируем: центр линии в startPt
    line.position = CGPointMake(startPt.x, startPt.y - lineLen / 2.0f);
    line.anchorPoint = CGPointMake(0.5, 0);

    [container.layer addSublayer:line];

    // Анимация движения слева-снизу в правый-верхний угол
    CGFloat duration = 4.5f + (arc4random_uniform(100) / 100.0f) * 3.0f;

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithCGPoint:CGPointMake(startPt.x, startPt.y - lineLen / 2.0f)];
    anim.toValue   = [NSValue valueWithCGPoint:CGPointMake(endPt.x,   endPt.y   - lineLen / 2.0f)];
    anim.duration  = duration;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.fillMode  = kCAFillModeForwards;
    anim.removedOnCompletion = NO;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[anim];
    group.duration   = duration;
    group.fillMode   = kCAFillModeForwards;
    group.removedOnCompletion = NO;

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{ [line removeFromSuperlayer]; }];
    [line addAnimation:group forKey:@"move"];
    [CATransaction commit];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *urlStr = @(OBF("https://t.me/evnbankoolo"));
        NSURL *url = [NSURL URLWithString:urlStr];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    });
}

- (void)reloadMainButtonState
{
    isRemoteHUDActive = [self isHUDEnabled];
    [mainButton setTitle:(isRemoteHUDActive ? @"STOP" : @"RUN Inject") forState:UIControlStateNormal];
}

- (void)tapAuthorLabel:(UITapGestureRecognizer *)sender
{
    
}

- (void)tapMainButton:(UIButton *)sender
{
    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled;

    if (isNowEnabled)
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadMainButtonState];
                [self.backgroundView setUserInteractionEnabled:YES];
            });
        });
    }
    else
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    }
}

- (void)verticalSizeClassUpdated
{
    UIUserInterfaceSizeClass verticalClass = self.traitCollection.verticalSizeClass;
    if (verticalClass == UIUserInterfaceSizeClassCompact) {
        [mainButtonCenterYConstraint setConstant:-20.0f];
    } else {
        [mainButtonCenterYConstraint setConstant:-40.0f];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self verticalSizeClassUpdated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end