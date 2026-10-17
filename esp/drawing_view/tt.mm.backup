#import "esp.h"
#import "cfg.h"
#include "obfusheader.h"
#import "tt.h"
#include <string>
#include <vector>
#include <map>
#import "../../sources/UIView+SecureView.h"
#import <objc/runtime.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

extern volatile bool esp_screenshot_safe;

float g_menuR = 0.0f, g_menuG = 0.0f, g_menuB = 0.0f;
float g_textR = 1.0f, g_textG = 1.0f, g_textB = 1.0f;
BOOL  g_rainbowMenu = NO;
volatile int esp_menu_effect = 1; // По умолчанию снег
volatile bool esp_preview_window = false;
volatile int esp_update_rate = 60; // ESP Update Rate (fps)

typedef void (^ColorPickCallback)(CGFloat r, CGFloat g, CGFloat b);

// ─── ColorPickerView ────────────────────────────────────────────────────────
@interface ColorPickerView : UIView
@property (nonatomic, copy) ColorPickCallback onChange;
- (instancetype)initWithFrame:(CGRect)frame initialR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b;
@end

@implementation ColorPickerView {
    UIView        *_sbView;      // saturation/brightness square
    CAGradientLayer *_hueLayer;
    CAGradientLayer *_sbWhiteLayer;
    CAGradientLayer *_sbBlackLayer;
    UIView        *_sbThumb;
    UIView        *_hueSliderTrack;
    UIView        *_hueThumb;
    UIView        *_alphaSliderTrack;
    UIView        *_alphaThumb;
    UIView        *_previewSwatch;
    UITextField   *_hexField;
    CGFloat        _hue, _sat, _bri, _alpha;
}

- (instancetype)initWithFrame:(CGRect)frame initialR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _alpha = 1.0;
    [self rgbToHSB:r g:g b:b];
    [self buildUI];
    return self;
}

- (void)rgbToHSB:(CGFloat)r g:(CGFloat)g b:(CGFloat)b {
    CGFloat h, s, v;
    UIColor *c = [UIColor colorWithRed:r green:g blue:b alpha:1];
    [c getHue:&h saturation:&s brightness:&v alpha:nil];
    _hue = h; _sat = s; _bri = v;
}

- (void)buildUI {
    CGFloat W = self.bounds.size.width;
    CGFloat pad = 8;
    CGFloat sbH = W * 0.55;
    CGFloat slH = 18;
    CGFloat y = pad;

    // SB square
    _sbView = [[UIView alloc] initWithFrame:CGRectMake(pad, y, W - pad*2, sbH)];
    _sbView.clipsToBounds = YES;
    _sbView.layer.cornerRadius = 6;
    [self addSubview:_sbView];

    // hue base layer (solid hue color)
    CAGradientLayer *hueBase = [CAGradientLayer layer];
    hueBase.frame = _sbView.bounds;
    hueBase.colors = @[(id)[UIColor colorWithHue:_hue saturation:1 brightness:1 alpha:1].CGColor,
                       (id)[UIColor colorWithHue:_hue saturation:1 brightness:1 alpha:1].CGColor];
    hueBase.name = @"hueBase";
    [_sbView.layer addSublayer:hueBase];
    _hueLayer = hueBase;

    // white gradient left→right
    _sbWhiteLayer = [CAGradientLayer layer];
    _sbWhiteLayer.frame = _sbView.bounds;
    _sbWhiteLayer.startPoint = CGPointMake(0, 0.5);
    _sbWhiteLayer.endPoint   = CGPointMake(1, 0.5);
    _sbWhiteLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor];
    [_sbView.layer addSublayer:_sbWhiteLayer];

    // black gradient top→bottom
    _sbBlackLayer = [CAGradientLayer layer];
    _sbBlackLayer.frame = _sbView.bounds;
    _sbBlackLayer.startPoint = CGPointMake(0.5, 0);
    _sbBlackLayer.endPoint   = CGPointMake(0.5, 1);
    _sbBlackLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor];
    [_sbView.layer addSublayer:_sbBlackLayer];

    // SB thumb
    _sbThumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    _sbThumb.layer.cornerRadius = 8;
    _sbThumb.layer.borderWidth = 2;
    _sbThumb.layer.borderColor = [UIColor whiteColor].CGColor;
    _sbThumb.layer.shadowColor = [UIColor blackColor].CGColor;
    _sbThumb.layer.shadowRadius = 2;
    _sbThumb.layer.shadowOpacity = 0.6;
    _sbThumb.layer.shadowOffset = CGSizeZero;
    _sbThumb.userInteractionEnabled = NO;
    [_sbView addSubview:_sbThumb];
    [self updateSBThumb];

    UIPanGestureRecognizer *sbPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSBPan:)];
    UITapGestureRecognizer *sbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSBTap:)];
    [_sbView addGestureRecognizer:sbPan];
    [_sbView addGestureRecognizer:sbTap];

    y += sbH + 10;

    // Hue slider
    UIView *hueTrack = [[UIView alloc] initWithFrame:CGRectMake(pad, y, W - pad*2, slH)];
    hueTrack.layer.cornerRadius = slH/2;
    hueTrack.clipsToBounds = YES;
    CAGradientLayer *hueGrad = [CAGradientLayer layer];
    hueGrad.frame = hueTrack.bounds;
    hueGrad.startPoint = CGPointMake(0, 0.5);
    hueGrad.endPoint   = CGPointMake(1, 0.5);
    NSMutableArray *hueColors = [NSMutableArray new];
    for (int i = 0; i <= 12; i++) {
        [hueColors addObject:(id)[UIColor colorWithHue:i/12.0 saturation:1 brightness:1 alpha:1].CGColor];
    }
    hueGrad.colors = hueColors;
    [hueTrack.layer addSublayer:hueGrad];
    [self addSubview:hueTrack];
    _hueSliderTrack = hueTrack;

    _hueThumb = [self makeThumb];
    [self addSubview:_hueThumb];
    [self updateHueThumb];

    UIPanGestureRecognizer *huePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHuePan:)];
    UITapGestureRecognizer *hueTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHueTap:)];
    [hueTrack addGestureRecognizer:huePan];
    [hueTrack addGestureRecognizer:hueTap];

    y += slH + 8;

    // Alpha slider
    UIView *alphaTrack = [[UIView alloc] initWithFrame:CGRectMake(pad, y, W - pad*2, slH)];
    alphaTrack.layer.cornerRadius = slH/2;
    alphaTrack.clipsToBounds = YES;
    // checkerboard bg
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16,16), NO, 0);
    [[UIColor colorWithWhite:0.7 alpha:1] setFill]; UIRectFill(CGRectMake(0,0,8,8)); UIRectFill(CGRectMake(8,8,8,8));
    [[UIColor colorWithWhite:0.4 alpha:1] setFill]; UIRectFill(CGRectMake(8,0,8,8)); UIRectFill(CGRectMake(0,8,8,8));
    UIImage *checker = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    alphaTrack.backgroundColor = [UIColor colorWithPatternImage:checker];
    CAGradientLayer *alphaGrad = [CAGradientLayer layer];
    alphaGrad.frame = alphaTrack.bounds;
    alphaGrad.startPoint = CGPointMake(0, 0.5);
    alphaGrad.endPoint   = CGPointMake(1, 0.5);
    alphaGrad.name = @"alphaGrad";
    [alphaTrack.layer addSublayer:alphaGrad];
    [self addSubview:alphaTrack];
    _alphaSliderTrack = alphaTrack;
    [self updateAlphaGrad];

    _alphaThumb = [self makeThumb];
    [self addSubview:_alphaThumb];
    [self updateAlphaThumb];

    UIPanGestureRecognizer *aPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleAlphaPan:)];
    UITapGestureRecognizer *aTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAlphaTap:)];
    [alphaTrack addGestureRecognizer:aPan];
    [alphaTrack addGestureRecognizer:aTap];

    y += slH + 10;

    // Preview swatch + hex field
    CGFloat swatchSize = 36;
    _previewSwatch = [[UIView alloc] initWithFrame:CGRectMake(pad, y, swatchSize, swatchSize)];
    _previewSwatch.layer.cornerRadius = 8;
    _previewSwatch.layer.borderWidth = 1;
    _previewSwatch.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    [self addSubview:_previewSwatch];

    UILabel *hashLbl = [[UILabel alloc] initWithFrame:CGRectMake(pad + swatchSize + 8, y + 8, 14, 20)];
    hashLbl.text = @"#";
    hashLbl.textColor = [UIColor colorWithWhite:0.7 alpha:1];
    hashLbl.font = [UIFont systemFontOfSize:14];
    [self addSubview:hashLbl];

    _hexField = [[UITextField alloc] initWithFrame:CGRectMake(pad + swatchSize + 24, y + 4, W - pad*2 - swatchSize - 28, 28)];
    _hexField.textColor = [UIColor whiteColor];
    _hexField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    _hexField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    _hexField.layer.cornerRadius = 6;
    _hexField.autocorrectionType = UITextAutocorrectionTypeNo;
    _hexField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    _hexField.returnKeyType = UIReturnKeyDone;
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0,0,8,0)];
    _hexField.leftView = leftPad;
    _hexField.leftViewMode = UITextFieldViewModeAlways;
    [_hexField addTarget:self action:@selector(hexFieldDone) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self addSubview:_hexField];

    [self updatePreview];
}

- (UIView *)makeThumb {
    UIView *t = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    t.layer.cornerRadius = 10;
    t.layer.borderWidth = 2;
    t.layer.borderColor = [UIColor whiteColor].CGColor;
    t.layer.shadowColor = [UIColor blackColor].CGColor;
    t.layer.shadowRadius = 3;
    t.layer.shadowOpacity = 0.7;
    t.layer.shadowOffset = CGSizeZero;
    t.backgroundColor = [UIColor clearColor];
    t.userInteractionEnabled = NO;
    return t;
}

- (void)handleSBPan:(UIPanGestureRecognizer *)g { [self updateSBFromPoint:[g locationInView:_sbView]]; }
- (void)handleSBTap:(UITapGestureRecognizer *)g { [self updateSBFromPoint:[g locationInView:_sbView]]; }
- (void)handleHuePan:(UIPanGestureRecognizer *)g { [self updateHueFromPoint:[g locationInView:_hueSliderTrack]]; }
- (void)handleHueTap:(UITapGestureRecognizer *)g { [self updateHueFromPoint:[g locationInView:_hueSliderTrack]]; }
- (void)handleAlphaPan:(UIPanGestureRecognizer *)g { [self updateAlphaFromPoint:[g locationInView:_alphaSliderTrack]]; }
- (void)handleAlphaTap:(UITapGestureRecognizer *)g { [self updateAlphaFromPoint:[g locationInView:_alphaSliderTrack]]; }

- (void)updateSBFromPoint:(CGPoint)pt {
    CGFloat w = _sbView.bounds.size.width, h = _sbView.bounds.size.height;
    _sat = MAX(0, MIN(1, pt.x / w));
    _bri = MAX(0, MIN(1, 1.0 - pt.y / h));
    [self updateSBThumb];
    [self updateAlphaGrad];
    [self updatePreview];
    [self fireCallback];
}

- (void)updateHueFromPoint:(CGPoint)pt {
    _hue = MAX(0, MIN(0.9999, pt.x / _hueSliderTrack.bounds.size.width));
    _hueLayer.colors = @[(id)[UIColor colorWithHue:_hue saturation:1 brightness:1 alpha:1].CGColor,
                         (id)[UIColor colorWithHue:_hue saturation:1 brightness:1 alpha:1].CGColor];
    [self updateHueThumb];
    [self updateAlphaGrad];
    [self updatePreview];
    [self fireCallback];
}

- (void)updateAlphaFromPoint:(CGPoint)pt {
    _alpha = MAX(0, MIN(1, pt.x / _alphaSliderTrack.bounds.size.width));
    [self updateAlphaThumb];
    [self updatePreview];
    [self fireCallback];
}

- (void)updateSBThumb {
    CGFloat w = _sbView.bounds.size.width, h = _sbView.bounds.size.height;
    _sbThumb.center = CGPointMake(_sat * w, (1.0 - _bri) * h);
}

- (void)updateHueThumb {
    CGRect tr = _hueSliderTrack.frame;
    _hueThumb.center = CGPointMake(tr.origin.x + _hue * tr.size.width, tr.origin.y + tr.size.height / 2);
}

- (void)updateAlphaThumb {
    CGRect tr = _alphaSliderTrack.frame;
    _alphaThumb.center = CGPointMake(tr.origin.x + _alpha * tr.size.width, tr.origin.y + tr.size.height / 2);
}

- (void)updateAlphaGrad {
    UIColor *solid = [UIColor colorWithHue:_hue saturation:_sat brightness:_bri alpha:1];
    for (CALayer *l in _alphaSliderTrack.layer.sublayers) {
        if ([l.name isEqualToString:@"alphaGrad"]) {
            ((CAGradientLayer *)l).colors = @[(id)[solid colorWithAlphaComponent:0].CGColor,
                                              (id)solid.CGColor];
        }
    }
}

- (void)updatePreview {
    UIColor *c = [UIColor colorWithHue:_hue saturation:_sat brightness:_bri alpha:_alpha];
    _previewSwatch.backgroundColor = c;
    CGFloat r, g, b, a;
    [c getRed:&r green:&g blue:&b alpha:&a];
    unsigned int ri = (unsigned int)(r * 255);
    unsigned int gi = (unsigned int)(g * 255);
    unsigned int bi = (unsigned int)(b * 255);
    unsigned int ai = (unsigned int)(a * 255);
    _hexField.text = [NSString stringWithFormat:@"%02X%02X%02X%02X", ri, gi, bi, ai];
}

- (void)hexFieldDone {
    NSString *hex = [_hexField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (hex.length == 6) hex = [hex stringByAppendingString:@"FF"];
    if (hex.length != 8) return;
    unsigned int val = 0;
    [[NSScanner scannerWithString:hex] scanHexInt:&val];
    CGFloat r = ((val >> 24) & 0xFF) / 255.0;
    CGFloat g = ((val >> 16) & 0xFF) / 255.0;
    CGFloat b = ((val >>  8) & 0xFF) / 255.0;
    CGFloat a = ((val >>  0) & 0xFF) / 255.0;
    _alpha = a;
    [self rgbToHSB:r g:g b:b];
    _hueLayer.colors = @[(id)[UIColor colorWithHue:_hue saturation:1 brightness:1 alpha:1].CGColor,
                         (id)[UIColor colorWithHue:_hue saturation:1 brightness:1 alpha:1].CGColor];
    [self updateSBThumb];
    [self updateHueThumb];
    [self updateAlphaThumb];
    [self updateAlphaGrad];
    [self updatePreview];
    [self fireCallback];
}

- (void)fireCallback {
    if (!self.onChange) return;
    CGFloat r, g, b, a;
    [[UIColor colorWithHue:_hue saturation:_sat brightness:_bri alpha:_alpha] getRed:&r green:&g blue:&b alpha:&a];
    self.onChange(r, g, b);
}

@end
// ────────────────────────────────────────────────────────────────────────────

@interface CustomSliderView : UIView
@property (nonatomic, assign) float value;
@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, copy) void (^valueChanged)(float newValue);

- (instancetype)initWithFrame:(CGRect)frame min:(float)min max:(float)max current:(float)current;
@end

@implementation CustomSliderView {
    UIView *_track;
    UIView *_thumb;
    UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame min:(float)min max:(float)max current:(float)current {
    self = [super initWithFrame:frame];
    if (self) {
        _minValue = min;
        _maxValue = max;
        _value = current;

        _track = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height/2 - 1, frame.size.width, 2)];
        _track.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];

        _thumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        _thumb.backgroundColor = [UIColor whiteColor];
        _thumb.layer.cornerRadius = 6;
        _thumb.userInteractionEnabled = NO;
        [self addSubview:_thumb];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        [self updateThumbPosition];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self];
    [self updateValueWithX:pt.x];
}

- (void)handleTap:(UITapGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self];
    [self updateValueWithX:pt.x];
}

- (void)updateValueWithX:(CGFloat)x {
    float percent = x / self.frame.size.width;
    if (percent < 0) percent = 0;
    if (percent > 1) percent = 1;

    _value = _minValue + (_maxValue - _minValue) * percent;
    [self updateThumbPosition];
    if (self.valueChanged) self.valueChanged(_value);
}

- (void)updateThumbPosition {
    float percent = (_value - _minValue) / (_maxValue - _minValue);
    _thumb.center = CGPointMake(self.frame.size.width * percent, self.frame.size.height/2);
}

- (void)setValue:(float)value {
    _value = value;
    [self updateThumbPosition];
}
@end

@interface CustomSegmentedControl : UIView
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) void (^valueChanged)(NSInteger newIndex);
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items current:(NSInteger)current;
- (void)reloadUI:(NSInteger)idx;
@end

@implementation CustomSegmentedControl {
    NSArray *_items;
    NSMutableArray *_labels;
}
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items current:(NSInteger)current {
    self = [super initWithFrame:frame];
    if (self) {
        _items = items;
        _selectedIndex = current;
        _labels = [NSMutableArray new];
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
        self.layer.cornerRadius = 6;
        self.clipsToBounds = YES;
        
        CGFloat bw = frame.size.width / items.count;
        for (int i = 0; i < items.count; i++) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(i * bw, 0, bw, frame.size.height)];
            l.text = items[i];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont systemFontOfSize:10 weight:(i == current ? UIFontWeightBold : UIFontWeightRegular)];
            l.textColor = (i == current ? [UIColor blackColor] : [UIColor colorWithWhite:0.7 alpha:1]);
            l.backgroundColor = (i == current ? [UIColor whiteColor] : [UIColor clearColor]);
            [self addSubview:l];
            [_labels addObject:l];
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)reloadUI:(NSInteger)idx {
    if (idx < 0) idx = 0;
    if (idx >= _items.count) idx = _items.count - 1;
    _selectedIndex = idx;
    for (int i = 0; i < _labels.count; i++) {
        UILabel *l = _labels[i];
        BOOL sel = (i == idx);
        l.textColor = sel ? [UIColor blackColor] : [UIColor colorWithWhite:0.7 alpha:1];
        l.backgroundColor = sel ? [UIColor whiteColor] : [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:10 weight:(sel ? UIFontWeightBold : UIFontWeightRegular)];
    }
}
- (void)handleTap:(UITapGestureRecognizer *)g {
    CGPoint p = [g locationInView:self];
    NSInteger idx = p.x / (self.frame.size.width / _items.count);
    if (idx < 0) idx = 0;
    if (idx >= _items.count) idx = _items.count - 1;
    
    _selectedIndex = idx;
    for (int i = 0; i < _labels.count; i++) {
        UILabel *l = _labels[i];
        BOOL sel = (i == idx);
        l.textColor = sel ? [UIColor blackColor] : [UIColor colorWithWhite:0.7 alpha:1];
        l.backgroundColor = sel ? [UIColor whiteColor] : [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:10 weight:(sel ? UIFontWeightBold : UIFontWeightRegular)];
    }
    if (self.valueChanged) self.valueChanged(idx);
}
@end

@interface VerticalOnlyPanGestureRecognizer : UIPanGestureRecognizer
@end
@implementation VerticalOnlyPanGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    UIView *v = touch.view;
    while (v) {
        if ([v isKindOfClass:[CustomSegmentedControl class]] || 
            [v isKindOfClass:[CustomSliderView class]]) {
            self.state = UIGestureRecognizerStateFailed;
            return;
        }
        v = v.superview;
    }
    [super touchesBegan:touches withEvent:event];
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateBegan) {
        CGPoint vel = [self velocityInView:self.view];
        if (fabs(vel.x) > fabs(vel.y)) {
            self.state = UIGestureRecognizerStateFailed;
        }
    }
}
@end

@interface MenuView () <UIGestureRecognizerDelegate, UIDocumentPickerDelegate>
// Internal methods — forward declared to suppress compiler errors
- (void)addSectionHeader:(NSString *)title atY:(CGFloat)y;
- (void)addSectionHeader:(NSString *)title atX:(CGFloat)x y:(CGFloat)y width:(CGFloat)w;
- (CAShapeLayer *)addToggle:(NSString *)name atY:(CGFloat)y action:(SEL)action enabled:(BOOL)enabled;
- (CAShapeLayer *)addToggle:(NSString *)name atY:(CGFloat)y action:(SEL)action enabled:(BOOL)enabled colorR:(volatile float *)rPtr g:(volatile float *)gPtr b:(volatile float *)bPtr show:(BOOL)showSwatch;
- (void)addColorRow:(NSString *)name atY:(CGFloat)y inView:(UIView *)container rPtr:(volatile float *)rPtr gPtr:(volatile float *)gPtr bPtr:(volatile float *)bPtr onChange:(ColorPickCallback)onChange;
- (void)addSmoothSliderAtY:(CGFloat)y;
- (void)addFovSliderAtY:(CGFloat)y;
- (void)addTriggerDelaySliderAtY:(CGFloat)y;
- (void)addBoneSelectorAtY:(CGFloat)y;
- (void)addBhopSliderAtY:(CGFloat)y;
- (void)addRCSHSliderAtY:(CGFloat)y;
- (void)addRCSVSliderAtY:(CGFloat)y;
- (void)addViewmodelXSliderAtY:(CGFloat)y;
- (void)addViewmodelYSliderAtY:(CGFloat)y;
- (void)addViewmodelZSliderAtY:(CGFloat)y;
- (void)addSliderAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)w title:(NSString *)title min:(float)mn max:(float)mx current:(float)cur fmt:(NSString *)fmt valueChanged:(void(^)(float))cb valueLabel:(__strong UILabel **)outLabel slider:(__strong CustomSliderView **)outSlider;
- (void)refreshSkinList;
- (void)refreshConfigList;
- (void)applyMenuColor;
- (void)applyTextColor;
- (void)setColorSwatch:(CAShapeLayer *)checkmark visible:(BOOL)visible;
- (void)showViewForCapture;
- (void)swatchTapped:(UITapGestureRecognizer *)g;
- (void)colorRowSwatchTapped:(UITapGestureRecognizer *)g;
- (void)hitSoundTapped;
- (void)previewWindowTapped;
- (void)rainbowTapped;
- (void)rainbowMenuTapped;
- (void)rainbowMenuTick;
- (void)arrowsTapped;
- (void)arrowsOutlineTapped;
- (void)skeletonTapped;
- (void)skeletonHeadTapped;
- (void)drawPreviewESP:(UIView *)container;
- (void)showPreviewWindow;
- (void)hidePreviewWindow;
- (void)refreshPreviewWindow;
- (void)rebuildVisualContent;
- (void)shareConfigFlow;
- (void)importConfigFlow;
@end

@interface UIView (ColorPopupDismiss)
- (void)handleDismissTap:(UITapGestureRecognizer *)g;
@end
@implementation UIView (ColorPopupDismiss)
- (void)handleDismissTap:(UITapGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self];
    for (UIView *sub in self.subviews) {
        if (CGRectContainsPoint(sub.frame, pt)) return;
    }
    void (^block)(void) = objc_getAssociatedObject(self, "dismissBlock");
    if (block) block();
}
@end

@interface UIView (PopupDrag)
- (void)handlePopupDrag:(UIPanGestureRecognizer *)g;
@end
@implementation UIView (PopupDrag)
- (void)handlePopupDrag:(UIPanGestureRecognizer *)g {
    CGPoint delta = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + delta.x, self.center.y + delta.y);
    [g setTranslation:CGPointZero inView:self.superview];
}
@end

@implementation MenuView {
    UIVisualEffectView *_blurView;
    UIView *_headerView;
    UILabel *_headerLabel;

    UIView *_contentView;
    UIView *_leftBarView;
    UIView *_aimContainer;
    UIView *_visualContainer;
    UIView *_playerContainer;
    UIView *_configContainer;
    UIView *_skinContainer;
    UIView *_otherContainer;
    UIView *_innerContent;
    NSMutableArray<UILabel *> *_tabLabels;

    CGPoint _initialTouchPoint;
    BOOL _collapsed;
    CAShapeLayer *_arrowLayer;

    CAShapeLayer *_boxCheckmark;
    CAShapeLayer *_boxOutlineCheckmark;
    CAShapeLayer *_boxFillCheckmark;
    CAShapeLayer *_boxCornerCheckmark;
    CAShapeLayer *_box3DCheckmark;
    CAShapeLayer *_lineCheckmark;
    CAShapeLayer *_lineOutlineCheckmark;
    CAShapeLayer *_teamCheckmark;
    CAShapeLayer *_nameCheckmark;
    CAShapeLayer *_nameOutlineCheckmark;
    CAShapeLayer *_invisibleCheckmark;
    CAShapeLayer *_addscoreCheckmark;
    CAShapeLayer *_infAmmoCheckmark;
    CAShapeLayer *_noSpreadCheckmark;
    CAShapeLayer *_airJumpCheckmark;
    CAShapeLayer *_fastKnifeCheckmark;
    CAShapeLayer *_bunnyHopCheckmark;
    CAShapeLayer *_wallshotCheckmark;
    CAShapeLayer *_fireRateCheckmark;
    CAShapeLayer *_healthCheckmark;
    CAShapeLayer *_healthBarCheckmark;
    CAShapeLayer *_healthBarOutlineCheckmark;
    CAShapeLayer *_weaponCheckmark;
    CAShapeLayer *_weaponIconCheckmark;
    CAShapeLayer *_platformCheckmark;
    CAShapeLayer *_avatarCheckmark;
    CAShapeLayer *_skeletonCheckmark;
    CAShapeLayer *_skeletonHeadCheckmark;
    CAShapeLayer     *_arrowsCheckmark;
    CAShapeLayer     *_arrowsOutlineCheckmark;
    CustomSliderView *_arrowsMarginSlider;
    UILabel          *_arrowsMarginValueLabel;
    CustomSliderView *_arrowsSizeSlider;
    UILabel          *_arrowsSizeValueLabel;
    CustomSliderView *_boxThicknessSlider;
    UILabel          *_boxThicknessValueLabel;
    CustomSliderView *_box3dThicknessSlider;
    UILabel          *_box3dThicknessValueLabel;
    CustomSliderView *_skelThicknessSlider;
    UILabel          *_skelThicknessValueLabel;

    CAShapeLayer *_screenshotSafeCheckmark;
    CAShapeLayer *_hitSoundCheckmark;
    CAShapeLayer *_previewWindowCheckmark;
    CAShapeLayer *_rainbowCheckmark;
    CAShapeLayer *_rainbowMenuCheckmark;
    NSTimer      *_rainbowMenuTimer;
    CGFloat       _rainbowMenuHue;

    UIView *_aimContent;
    UIView *_visualContent;
    UIView *_playerContent;
    UIView *_configContent;
    UIView *_skinContent;
    UIView *_otherContent;

    CAShapeLayer *_aimbotCheckmark;
    CAShapeLayer *_triggerbotCheckmark;
    CAShapeLayer *_aimbotFovVisibleCheckmark;
    CAShapeLayer *_visibleCheckCheckmark;
    CAShapeLayer *_shootingCheckCheckmark;
    CAShapeLayer *_knifeBotCheckmark;
    CAShapeLayer *_aimbotTeamCheckmark;
    CAShapeLayer *_rcsCheckmark;
    CustomSegmentedControl *_boneSelector;
    CustomSegmentedControl *_lineModeSelector;
    UILabel *_fovValueLabel;
    UILabel *_smoothValueLabel;
    UILabel *_rcsHValueLabel;
    UILabel *_rcsVValueLabel;
    UILabel *_bhopValueLabel;
    UILabel *_triggerDelayValueLabel;

    CustomSliderView *_fovSlider;
    CustomSliderView *_smoothSlider;
    CustomSliderView *_rcsHSlider;
    CustomSliderView *_rcsVSlider;
    CustomSliderView *_bhopSlider;
    CustomSliderView *_triggerDelaySlider;

    NSMutableArray<UILabel *> *_toggleLabels;
    NSMutableArray<UILabel *> *_sectionHeaders;
    NSMutableArray<UIView *>  *_rowViews;
    // Color popup overlay
    UIView *_colorPopupOverlay;
    CGFloat _toggleColX;
    CGFloat _toggleColWidth;
    
    CAShapeLayer *_viewmodelCheckmark;
    CustomSliderView *_viewmodelXSlider;
    UILabel *_viewmodelXValueLabel;
    CustomSliderView *_viewmodelYSlider;
    UILabel *_viewmodelYValueLabel;
    CustomSliderView *_viewmodelZSlider;
    UILabel *_viewmodelZValueLabel;
    CGFloat _configListStartY;
    CGFloat _skinListStartY;
    NSTimer *_skinTimer;
    NSArray *_cachedSkins;
    std::map<int, std::string> _allSkinsMap;
    std::vector<std::pair<int, uintptr_t>> _ownedSkinsInfo;
    int _selectedOwnedIdx;
    int _selectedReplaceIdx;
    std::vector<std::pair<int, std::string>> _allSkinsList;
    
    UIView *_previewWindow; // Отдельное окно preview
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 12.0;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;

        // Темно-синий фон как в FxL Premium (RGB: 40, 40, 66)
        UIView *solidBg = [[UIView alloc] initWithFrame:self.bounds];
        solidBg.backgroundColor = [UIColor colorWithRed:0.156 green:0.158 blue:0.258 alpha:1.0];
        solidBg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:solidBg];

        CGFloat headerHeight = 50.0;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, headerHeight)];
        _headerView.backgroundColor = [UIColor colorWithRed:0.156 green:0.158 blue:0.258 alpha:1.0];
        _headerView.userInteractionEnabled = YES;
        [self addSubview:_headerView];

        // Заголовок "WXR | IOS"
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 8, frame.size.width - 80, 28)];
        _headerLabel.text = @"WXR | IOS";
        _headerLabel.textAlignment = NSTextAlignmentLeft;
        _headerLabel.textColor = [UIColor whiteColor];
        _headerLabel.font = [UIFont boldSystemFontOfSize:20];
        [_headerView addSubview:_headerLabel];

        // Иконка  справа
        UILabel *cloudIcon = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 50, 8, 30, 28)];
        cloudIcon.text = @"\uF8FF";
        cloudIcon.font = [UIFont systemFontOfSize:24];
        cloudIcon.textAlignment = NSTextAlignmentCenter;
        cloudIcon.userInteractionEnabled = NO;
        [_headerView addSubview:cloudIcon];
        
        // Фиолетовый прогресс-бар под заголовком
        UIView *progressBg = [[UIView alloc] initWithFrame:CGRectMake(15, headerHeight - 6, frame.size.width - 30, 3)];
        progressBg.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        progressBg.layer.cornerRadius = 1.5;
        [_headerView addSubview:progressBg];
        
        UIView *progressFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, progressBg.frame.size.width, 3)];
        progressFill.backgroundColor = [UIColor colorWithRed:0.565 green:0.481 blue:1.0 alpha:1.0];
        progressFill.layer.cornerRadius = 1.5;
        [progressBg addSubview:progressFill];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.cancelsTouchesInView = NO;
        [_headerView addGestureRecognizer:panGesture];

        CGFloat leftBarWidth = 50.0;
        
        _leftBarView = [[UIView alloc] initWithFrame:CGRectMake(0, headerHeight, leftBarWidth, frame.size.height - headerHeight)];
        _leftBarView.backgroundColor = [UIColor colorWithRed:0.156 green:0.158 blue:0.258 alpha:1.0];
        _leftBarView.userInteractionEnabled = YES;
        [self addSubview:_leftBarView];
        
        NSArray *tabs = @[@(OBF("VISUAL")), @(OBF("AIM")), @(OBF("PLAYER")), @(OBF("OTHER"))];
        _tabLabels = [NSMutableArray new];
        _toggleLabels = [NSMutableArray new];
        _sectionHeaders = [NSMutableArray new];
        _rowViews = [NSMutableArray new];
        
        for (int i=0; i<4; i++) {
            // Синяя кнопка (меньше)
            UIView *btn = [[UIView alloc] initWithFrame:CGRectMake(7, 8 + i * 45, 36, 36)];
            btn.backgroundColor = [UIColor colorWithRed:0.020 green:0.356 blue:0.568 alpha:1.0];
            btn.layer.cornerRadius = 6;
            btn.userInteractionEnabled = YES;
            btn.tag = i;
            [_leftBarView addSubview:btn];
            
            // Рисуем иконку (тоньше и меньше)
            CAShapeLayer *iconLayer = [CAShapeLayer layer];
            iconLayer.strokeColor = [UIColor whiteColor].CGColor;
            iconLayer.fillColor = [UIColor clearColor].CGColor;
            iconLayer.lineWidth = 1.5;
            iconLayer.lineCap = kCALineCapRound;
            iconLayer.lineJoin = kCALineJoinRound;
            
            UIBezierPath *iconPath = [UIBezierPath bezierPath];
            
            if (i == 0) { // VISUAL - глаз (только контур)
                // Контур глаза
                [iconPath moveToPoint:CGPointMake(9, 18)];
                [iconPath addQuadCurveToPoint:CGPointMake(27, 18) controlPoint:CGPointMake(18, 11)];
                [iconPath addQuadCurveToPoint:CGPointMake(9, 18) controlPoint:CGPointMake(18, 25)];
                // Зрачок - только контур круга
                [iconPath moveToPoint:CGPointMake(21, 18)];
                [iconPath addArcWithCenter:CGPointMake(18, 18) radius:3 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            } else if (i == 1) { // AIM - прицел
                [iconPath moveToPoint:CGPointMake(18, 10)];
                [iconPath addLineToPoint:CGPointMake(18, 14)];
                [iconPath moveToPoint:CGPointMake(18, 22)];
                [iconPath addLineToPoint:CGPointMake(18, 26)];
                [iconPath moveToPoint:CGPointMake(10, 18)];
                [iconPath addLineToPoint:CGPointMake(14, 18)];
                [iconPath moveToPoint:CGPointMake(22, 18)];
                [iconPath addLineToPoint:CGPointMake(26, 18)];
                [iconPath addArcWithCenter:CGPointMake(18, 18) radius:4 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            } else if (i == 2) { // PLAYER - человек
                [iconPath addArcWithCenter:CGPointMake(18, 13) radius:3 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
                [iconPath moveToPoint:CGPointMake(18, 16)];
                [iconPath addLineToPoint:CGPointMake(18, 23)];
                [iconPath moveToPoint:CGPointMake(13, 20)];
                [iconPath addLineToPoint:CGPointMake(23, 20)];
                [iconPath moveToPoint:CGPointMake(18, 23)];
                [iconPath addLineToPoint:CGPointMake(15, 27)];
                [iconPath moveToPoint:CGPointMake(18, 23)];
                [iconPath addLineToPoint:CGPointMake(21, 27)];
                iconLayer.fillColor = [UIColor whiteColor].CGColor;
            } else if (i == 3) { // OTHER - шестеренка (объединено с CONFIG)
                for (int j = 0; j < 6; j++) {
                    CGFloat angle = j * M_PI / 3;
                    CGFloat x1 = 18 + 7 * cos(angle);
                    CGFloat y1 = 18 + 7 * sin(angle);
                    CGFloat x2 = 18 + 5 * cos(angle);
                    CGFloat y2 = 18 + 5 * sin(angle);
                    [iconPath moveToPoint:CGPointMake(x2, y2)];
                    [iconPath addLineToPoint:CGPointMake(x1, y1)];
                }
                [iconPath addArcWithCenter:CGPointMake(18, 18) radius:2.5 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            }
            
            iconLayer.path = iconPath.CGPath;
            iconLayer.frame = btn.bounds;
            [btn.layer addSublayer:iconLayer];
            
            // Скрытый label для совместимости
            UILabel *tl = [[UILabel alloc] initWithFrame:CGRectZero];
            tl.tag = i;
            [_tabLabels addObject:tl];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabTapped:)];
            [btn addGestureRecognizer:tap];
        }

        _contentView = [[UIView alloc] initWithFrame:CGRectMake(leftBarWidth, headerHeight, frame.size.width - leftBarWidth, frame.size.height - headerHeight)];
        _contentView.clipsToBounds = YES;
        _contentView.userInteractionEnabled = YES;
        [self addSubview:_contentView];

        _visualContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _aimContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _playerContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _configContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _otherContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _skinContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        
        _aimContainer.hidden = YES;
        _playerContainer.hidden = YES;
        _configContainer.hidden = YES;
        _skinContainer.hidden = YES;
        _otherContainer.hidden = YES;

        _visualContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 600)];
        _visualContent.userInteractionEnabled = YES;
        [_visualContainer addSubview:_visualContent];

        _aimContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 480)];
        _aimContent.userInteractionEnabled = YES;
        [_aimContainer addSubview:_aimContent];

        _playerContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 450)];
        _playerContent.userInteractionEnabled = YES;
        [_playerContainer addSubview:_playerContent];

        _configContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 400)];
        _configContent.userInteractionEnabled = YES;
        [_configContainer addSubview:_configContent];

        _skinContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 2000)];
        _skinContent.userInteractionEnabled = YES;
        [_skinContainer addSubview:_skinContent];

        _otherContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 400)];
        _otherContent.userInteractionEnabled = YES;
        [_otherContainer addSubview:_otherContent];
        
        _selectedOwnedIdx = -1;
        _selectedReplaceIdx = -1;
        
        _innerContent = _skinContent;
        _toggleColX = 0; _toggleColWidth = 0;
        CGFloat yOffSkin = 4;
        [self addSectionHeader:@"SKINS" atY:yOffSkin];
        yOffSkin += 26;
        _skinListStartY = yOffSkin;
        
        _skinTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshSkinList) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_skinTimer forMode:NSRunLoopCommonModes];
        [self refreshSkinList];





        [_contentView addSubview:_aimContainer];
        [_contentView addSubview:_visualContainer];
        [_contentView addSubview:_playerContainer];
        [_contentView addSubview:_configContainer];
        [_contentView addSubview:_skinContainer];
        [_contentView addSubview:_otherContainer];

        VerticalOnlyPanGestureRecognizer *scrollPan = [[VerticalOnlyPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollPan:)];
        scrollPan.cancelsTouchesInView = YES;
        scrollPan.delaysTouchesBegan = NO;
        scrollPan.delaysTouchesEnded = NO;
        scrollPan.delegate = self;
        [_contentView addGestureRecognizer:scrollPan];

        _innerContent = _aimContent; 

        CGFloat yOffset = 4;
        CGFloat col2X = _aimContent.bounds.size.width / 2.0f + 5;
        CGFloat col2W = _aimContent.bounds.size.width / 2.0f - 10;
        _toggleColX = 0;
        _toggleColWidth = col2X - 5;

        [self addSectionHeader:@(OBF("AIMBOT")) atY:yOffset];
        yOffset += 26;
        _aimbotCheckmark = [self addToggle:@(OBF("Aimbot")) atY:yOffset action:@selector(aimbotTapped) enabled:aimbot_enabled];
        yOffset += 32;
        _triggerbotCheckmark = [self addToggle:@(OBF("Triggerbot")) atY:yOffset action:@selector(triggerbotTapped) enabled:aimbot_triggerbot];
        yOffset += 32;
        _aimbotFovVisibleCheckmark = [self addToggle:@(OBF("FOV Circle")) atY:yOffset action:@selector(aimbotFovTapped) enabled:aimbot_fov_visible colorR:&esp_fov_r g:&esp_fov_g b:&esp_fov_b show:YES];
        yOffset += 32;
        _visibleCheckCheckmark  = [self addToggle:@(OBF("Visible Check"))  atY:yOffset action:@selector(visibleCheckTapped)  enabled:aimbot_visible_check];
        yOffset += 32;
        _shootingCheckCheckmark = [self addToggle:@(OBF("Fire Check"))     atY:yOffset action:@selector(shootingCheckTapped) enabled:aimbot_shooting_check];
        yOffset += 32;
        _aimbotTeamCheckmark = [self addToggle:@(OBF("Team Check")) atY:yOffset action:@selector(aimbotTeamTapped) enabled:aimbot_team_check];
        yOffset += 32;
        _knifeBotCheckmark = [self addToggle:@(OBF("Knife Bot")) atY:yOffset action:@selector(knifeBotTapped) enabled:aimbot_knife_bot];
        yOffset += 32;

        // Right column — sliders
        CGFloat y2 = 4;
        [self addSectionHeader:@(OBF("Smooth")) atX:col2X y:y2 width:col2W]; y2 += 24;
        [self addSliderAtX:col2X y:y2 width:col2W title:nil min:0.0f max:20.0f current:aimbot_smooth fmt:@"%.1f" valueChanged:^(float v){ aimbot_smooth = v; } valueLabel:&_smoothValueLabel slider:&_smoothSlider];
        y2 += 55;

        [self addSectionHeader:@(OBF("FOV")) atX:col2X y:y2 width:col2W]; y2 += 24;
        [self addSliderAtX:col2X y:y2 width:col2W title:nil min:10.0f max:180.0f current:aimbot_fov fmt:@"%.0f" valueChanged:^(float v){ aimbot_fov = v; } valueLabel:&_fovValueLabel slider:&_fovSlider];
        y2 += 55;

        [self addSectionHeader:@(OBF("Trigger Delay")) atX:col2X y:y2 width:col2W]; y2 += 24;
        [self addSliderAtX:col2X y:y2 width:col2W title:nil min:0.01f max:1.0f current:aimbot_trigger_delay fmt:@"%.2f" valueChanged:^(float v){ aimbot_trigger_delay = v; } valueLabel:&_triggerDelayValueLabel slider:&_triggerDelaySlider];
        y2 += 55;

        [self addSectionHeader:@(OBF("Bone")) atX:col2X y:y2 width:col2W]; y2 += 24;
        NSArray *boneItems = @[@"Head", @"Neck", @"Spine", @"Hip"];
        _boneSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(col2X + 4, y2, col2W - 8, 28) items:boneItems current:aimbot_bone_index];
        _boneSelector.valueChanged = ^(NSInteger idx){ aimbot_bone_index = (int)idx; };
        [_innerContent addSubview:_boneSelector];
        y2 += 36;

        CGFloat aimH = MAX(yOffset, y2) + 10;
        CGRect aimContentFrame = _aimContent.frame;
        aimContentFrame.size.height = aimH;
        _aimContent.frame = aimContentFrame;
        _toggleColX = 0; _toggleColWidth = 0;


        _innerContent = _visualContent; // VISUALS
        yOffset = 4;
        CGFloat visCol2X = _visualContent.bounds.size.width / 2.0f + 5;
        CGFloat visCol2W = _visualContent.bounds.size.width / 2.0f - 10;
        _toggleColX = 0;
        _toggleColWidth = visCol2X - 5;

        // Left column — 9 toggles
        [self addSectionHeader:@(OBF("ESP")) atY:yOffset];
        yOffset += 26;
        _boxCheckmark = [self addToggle:@(OBF("Box 2D")) atY:yOffset action:@selector(boxTapped) enabled:esp_box_enabled colorR:&esp_box_r g:&esp_box_g b:&esp_box_b show:YES];
        yOffset += 32;
        _boxOutlineCheckmark = [self addToggle:@(OBF("Box Outline")) atY:yOffset action:@selector(boxOutlineTapped) enabled:esp_box_outline];
        yOffset += 32;
        _boxFillCheckmark = [self addToggle:@(OBF("Box Fill")) atY:yOffset action:@selector(boxFillTapped) enabled:esp_box_fill];
        yOffset += 32;
        _boxCornerCheckmark = [self addToggle:@(OBF("Box Corner")) atY:yOffset action:@selector(boxCornerTapped) enabled:esp_box_corner];
        yOffset += 32;
        _box3DCheckmark = [self addToggle:@(OBF("Box 3D")) atY:yOffset action:@selector(box3DTapped) enabled:esp_box_3d];
        yOffset += 32;
        _lineCheckmark = [self addToggle:@(OBF("Line")) atY:yOffset action:@selector(lineTapped) enabled:esp_line_enabled colorR:&esp_line_r g:&esp_line_g b:&esp_line_b show:YES];
        yOffset += 32;
        _lineOutlineCheckmark = [self addToggle:@(OBF("Line Outline")) atY:yOffset action:@selector(lineOutlineTapped) enabled:esp_line_outline];
        yOffset += 32;
        {
            CGFloat segW = _toggleColWidth > 0 ? _toggleColWidth : _visualContent.bounds.size.width;
            NSArray *lineModes = @[@"Top", @"Center", @"Bottom"];
            _lineModeSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(4, yOffset, segW - 8, 26) items:lineModes current:esp_line_mode];
            _lineModeSelector.valueChanged = ^(NSInteger idx){ esp_line_mode = (int)idx; };
            [_innerContent addSubview:_lineModeSelector];
            yOffset += 32;
        }
        _teamCheckmark = [self addToggle:@(OBF("Team Check")) atY:yOffset action:@selector(teamTapped) enabled:esp_team_check];
        yOffset += 32;
        _nameCheckmark = [self addToggle:@(OBF("Name")) atY:yOffset action:@selector(nameTapped) enabled:esp_name_enabled colorR:&esp_name_r g:&esp_name_g b:&esp_name_b show:YES];
        yOffset += 32;

        // Толщина линий + Viewmodel — левая колонка
        [self addSectionHeader:@(OBF("Thickness")) atY:yOffset]; yOffset += 24;
        [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:0.5f max:6.0f current:esp_box_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_box_thickness = v; } valueLabel:&_boxThicknessValueLabel slider:&_boxThicknessSlider];
        yOffset += 50;
        [self addSectionHeader:@(OBF("Box 3D")) atY:yOffset]; yOffset += 24;
        [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:0.5f max:6.0f current:esp_box3d_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_box3d_thickness = v; } valueLabel:&_box3dThicknessValueLabel slider:&_box3dThicknessSlider];
        yOffset += 50;

        [self addSectionHeader:@(OBF("VIEWMODEL")) atY:yOffset]; yOffset += 26;
        _viewmodelCheckmark = [self addToggle:@(OBF("Viewmodel")) atY:yOffset action:@selector(viewmodelTapped) enabled:viewmodel_enabled];
        yOffset += 34;
        [self addSectionHeader:@(OBF("View X")) atY:yOffset]; yOffset += 24;
        [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:-5.0f max:5.0f current:viewmodel_x fmt:@"%.1f" valueChanged:^(float v){ viewmodel_x = v; } valueLabel:&_viewmodelXValueLabel slider:&_viewmodelXSlider];
        yOffset += 50;
        [self addSectionHeader:@(OBF("View Y")) atY:yOffset]; yOffset += 24;
        [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:-5.0f max:5.0f current:viewmodel_y fmt:@"%.1f" valueChanged:^(float v){ viewmodel_y = v; } valueLabel:&_viewmodelYValueLabel slider:&_viewmodelYSlider];
        yOffset += 50;
        [self addSectionHeader:@(OBF("View Z")) atY:yOffset]; yOffset += 24;
        [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:-5.0f max:5.0f current:viewmodel_z fmt:@"%.1f" valueChanged:^(float v){ viewmodel_z = v; } valueLabel:&_viewmodelZValueLabel slider:&_viewmodelZSlider];
        yOffset += 50;

        // Right column — ESP toggles + Arrows
        CGFloat y2v = 4;
        _toggleColX = visCol2X; _toggleColWidth = visCol2W;
        [self addSectionHeader:@(OBF("ESP")) atY:y2v];
        y2v += 26;
        _nameOutlineCheckmark = [self addToggle:@(OBF("Name Outline")) atY:y2v action:@selector(nameOutlineTapped) enabled:esp_name_outline];
        y2v += 32;
        _healthCheckmark = [self addToggle:@(OBF("HP")) atY:y2v action:@selector(healthTapped) enabled:esp_health_enabled colorR:&esp_health_r g:&esp_health_g b:&esp_health_b show:YES];
        y2v += 32;
        _healthBarCheckmark = [self addToggle:@(OBF("Health Bar")) atY:y2v action:@selector(healthBarTapped) enabled:esp_health_bar_enabled];
        y2v += 32;
        _healthBarOutlineCheckmark = [self addToggle:@(OBF("Bar Outline")) atY:y2v action:@selector(healthBarOutlineTapped) enabled:esp_health_bar_outline];
        y2v += 32;
        _weaponCheckmark = [self addToggle:@(OBF("Weapon")) atY:y2v action:@selector(weaponTapped) enabled:esp_weapon_enabled colorR:&esp_weapon_r g:&esp_weapon_g b:&esp_weapon_b show:YES];
        y2v += 32;
        _weaponIconCheckmark = [self addToggle:@(OBF("Weapon Icon")) atY:y2v action:@selector(weaponIconTapped) enabled:esp_weapon_icon_enabled];
        y2v += 32;
        _platformCheckmark = [self addToggle:@(OBF("Platform")) atY:y2v action:@selector(platformTapped) enabled:esp_platform_enabled];
        y2v += 32;
        _avatarCheckmark = [self addToggle:@(OBF("Avatar")) atY:y2v action:@selector(avatarTapped) enabled:esp_avatar_enabled];
        y2v += 32;
        _arrowsCheckmark = [self addToggle:@(OBF("Arrows")) atY:y2v action:@selector(arrowsTapped) enabled:esp_arrows_enabled colorR:&esp_arrows_r g:&esp_arrows_g b:&esp_arrows_b show:YES];
        y2v += 32;
        _arrowsOutlineCheckmark = [self addToggle:@(OBF("Arrows Outline")) atY:y2v action:@selector(arrowsOutlineTapped) enabled:esp_arrows_outline];
        y2v += 32;
        // Margin slider
        [self addSectionHeader:@(OBF("Arrow Margin")) atY:y2v]; y2v += 24;
        [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:20.0f max:500.0f current:esp_arrows_margin fmt:@"%.0f" valueChanged:^(float v){ esp_arrows_margin = v; } valueLabel:&_arrowsMarginValueLabel slider:&_arrowsMarginSlider];
        y2v += 55;
        [self addSectionHeader:@(OBF("Arrow Size")) atY:y2v]; y2v += 24;
        [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:4.0f max:40.0f current:esp_arrows_size fmt:@"%.0f" valueChanged:^(float v){ esp_arrows_size = v; } valueLabel:&_arrowsSizeValueLabel slider:&_arrowsSizeSlider];
        y2v += 55;

        // Skeleton в правой колонке
        [self addSectionHeader:@(OBF("SKELETON")) atY:y2v]; y2v += 26;
        _skeletonCheckmark = [self addToggle:@(OBF("Skeleton")) atY:y2v action:@selector(skeletonTapped) enabled:esp_skeleton_enabled colorR:&esp_skeleton_r g:&esp_skeleton_g b:&esp_skeleton_b show:YES];
        y2v += 32;
        _skeletonHeadCheckmark = [self addToggle:@(OBF("Skel + Head")) atY:y2v action:@selector(skeletonHeadTapped) enabled:esp_skeleton_head];
        y2v += 32;
        [self addSectionHeader:@(OBF("Skel Width")) atY:y2v]; y2v += 24;
        [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:0.5f max:6.0f current:esp_skeleton_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_skeleton_thickness = v; } valueLabel:&_skelThicknessValueLabel slider:&_skelThicknessSlider];
        y2v += 55;

        [self addSectionHeader:@(OBF("Box 2D Width")) atY:y2v]; y2v += 24;
        [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:0.5f max:6.0f current:esp_box_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_box_thickness = v; } valueLabel:&_boxThicknessValueLabel slider:&_boxThicknessSlider];
        y2v += 55;

        CGFloat visH = MAX(yOffset, y2v) + 10;
        CGRect visualContentFrame = _visualContent.frame;
        visualContentFrame.size.height = visH;
        _visualContent.frame = visualContentFrame;


        _innerContent = _playerContent; // PLAYER
        yOffset = 4;
        CGFloat plCol2X = _playerContent.bounds.size.width / 2.0f + 5;
        CGFloat plCol2W = _playerContent.bounds.size.width / 2.0f - 10;
        _toggleColX = 0;
        _toggleColWidth = plCol2X - 5;

        [self addSectionHeader:@(OBF("PLAYER")) atY:yOffset];
        yOffset += 26;
        _invisibleCheckmark = [self addToggle:@(OBF("Invisible")) atY:yOffset action:@selector(invisibleTapped) enabled:esp_invisible];
        yOffset += 32;
        _addscoreCheckmark = [self addToggle:@(OBF("Add Score")) atY:yOffset action:@selector(addskoreTapped) enabled:esp_addscore];
        yOffset += 32;
        _infAmmoCheckmark   = [self addToggle:@(OBF("Inf Ammo"))   atY:yOffset action:@selector(infAmmoTapped)   enabled:esp_inf_ammo];
        yOffset += 32;
        _noSpreadCheckmark  = [self addToggle:@(OBF("No Spread"))  atY:yOffset action:@selector(noSpreadTapped)  enabled:esp_no_spread];
        yOffset += 32;
        _airJumpCheckmark   = [self addToggle:@(OBF("Air Jump"))   atY:yOffset action:@selector(airJumpTapped)   enabled:esp_air_jump];
        yOffset += 32;
        _fastKnifeCheckmark = [self addToggle:@(OBF("Fast Knife")) atY:yOffset action:@selector(fastKnifeTapped) enabled:esp_fast_knife];
        yOffset += 32;
        _bunnyHopCheckmark  = [self addToggle:@(OBF("Bunny Hop"))  atY:yOffset action:@selector(bunnyHopTapped)  enabled:esp_bunny_hop];
        yOffset += 32;
        _wallshotCheckmark  = [self addToggle:@(OBF("Wallshot"))   atY:yOffset action:@selector(wallshotTapped)  enabled:esp_wallshot];
        yOffset += 32;
        _fireRateCheckmark  = [self addToggle:@(OBF("Fire Rate"))  atY:yOffset action:@selector(fireRateTapped)  enabled:esp_fire_rate];
        yOffset += 32;

        // Right column — bhop + RCS sliders
        CGFloat y2p = 4;
        [self addSectionHeader:@(OBF("Bunny Hop Speed")) atX:plCol2X y:y2p width:plCol2W]; y2p += 24;
        [self addSliderAtX:plCol2X y:y2p width:plCol2W title:nil min:1.0f max:20.0f current:(float)esp_bhop_setting fmt:@"%.0f" valueChanged:^(float v){ esp_bhop_setting = (int)v; } valueLabel:&_bhopValueLabel slider:&_bhopSlider];
        y2p += 55;

        _toggleColX = plCol2X; _toggleColWidth = plCol2W;
        _rcsCheckmark = [self addToggle:@(OBF("RCS")) atY:y2p action:@selector(rcsTapped) enabled:esp_rcs_enabled];
        _toggleColX = 0; _toggleColWidth = plCol2X - 5;
        y2p += 34;

        [self addSectionHeader:@(OBF("RCS Horizontal")) atX:plCol2X y:y2p width:plCol2W]; y2p += 24;
        [self addSliderAtX:plCol2X y:y2p width:plCol2W title:nil min:-2.0f max:2.0f current:esp_rcs_h fmt:@"%.2f" valueChanged:^(float v){ esp_rcs_h = v; } valueLabel:&_rcsHValueLabel slider:&_rcsHSlider];
        y2p += 55;

        [self addSectionHeader:@(OBF("RCS Vertical")) atX:plCol2X y:y2p width:plCol2W]; y2p += 24;
        [self addSliderAtX:plCol2X y:y2p width:plCol2W title:nil min:-2.0f max:2.0f current:esp_rcs_v fmt:@"%.2f" valueChanged:^(float v){ esp_rcs_v = v; } valueLabel:&_rcsVValueLabel slider:&_rcsVSlider];
        y2p += 55;

        CGFloat plH = MAX(yOffset, y2p) + 10;
        CGRect playerFrame = _playerContent.frame;
        playerFrame.size.height = plH;
        _playerContent.frame = playerFrame;

        _innerContent = _configContent;
        _toggleColX = 0; _toggleColWidth = 0;
        yOffset = 4;

        // Теперь CONFIG и OTHER объединены в _otherContent с двумя столбцами
        _innerContent = _otherContent;
        
        CGFloat leftColX = 10;
        CGFloat rightColX = _otherContent.bounds.size.width / 2 + 5;
        CGFloat colWidth = _otherContent.bounds.size.width / 2 - 15;
        
        // ЛЕВЫЙ СТОЛБЕЦ - CONFIG
        yOffset = 4;
        [self addSectionHeader:@(OBF("CONFIGS")) atX:leftColX y:yOffset width:colWidth];
        yOffset += 26;

        CGFloat btnW = (colWidth - 10) / 3.0;

        UILabel *createLbl = [[UILabel alloc] initWithFrame:CGRectMake(leftColX, yOffset, btnW, 28)];
        createLbl.text = @(OBF("Create"));
        createLbl.textAlignment = NSTextAlignmentCenter;
        createLbl.font = [UIFont boldSystemFontOfSize:11];
        createLbl.textColor = [UIColor blackColor];
        createLbl.backgroundColor = [UIColor whiteColor];
        createLbl.layer.cornerRadius = 4;
        createLbl.layer.masksToBounds = YES;
        createLbl.userInteractionEnabled = YES;
        [createLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createConfigFlow)]];
        [_otherContent addSubview:createLbl];

        UILabel *deleteLbl = [[UILabel alloc] initWithFrame:CGRectMake(leftColX + btnW + 2, yOffset, btnW, 28)];
        deleteLbl.text = @(OBF("Delete"));
        deleteLbl.textAlignment = NSTextAlignmentCenter;
        deleteLbl.font = [UIFont boldSystemFontOfSize:11];
        deleteLbl.textColor = [UIColor blackColor];
        deleteLbl.backgroundColor = [UIColor whiteColor];
        deleteLbl.layer.cornerRadius = 4;
        deleteLbl.layer.masksToBounds = YES;
        deleteLbl.userInteractionEnabled = YES;
        [deleteLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteConfigFlow)]];
        [_otherContent addSubview:deleteLbl];

        UILabel *loadLbl = [[UILabel alloc] initWithFrame:CGRectMake(leftColX + (btnW + 2) * 2, yOffset, btnW, 28)];
        loadLbl.text = @(OBF("Load"));
        loadLbl.textAlignment = NSTextAlignmentCenter;
        loadLbl.font = [UIFont boldSystemFontOfSize:11];
        loadLbl.textColor = [UIColor blackColor];
        loadLbl.backgroundColor = [UIColor whiteColor];
        loadLbl.layer.cornerRadius = 4;
        loadLbl.layer.masksToBounds = YES;
        loadLbl.userInteractionEnabled = YES;
        [loadLbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadConfigFlow)]];
        [_otherContent addSubview:loadLbl];

        yOffset += 36;
        _configListStartY = yOffset;
        
        // ПРАВЫЙ СТОЛБЕЦ - OTHER
        CGFloat rightYOffset = 4;
        [self addSectionHeader:@(OBF("OTHER")) atX:rightColX y:rightYOffset width:colWidth];
        rightYOffset += 26;
        
        _toggleColX = rightColX;
        _toggleColWidth = colWidth;
        _screenshotSafeCheckmark = [self addToggle:@(OBF("Overlay")) atY:rightYOffset action:@selector(screenshotSafeTapped) enabled:esp_screenshot_safe];
        rightYOffset += 32;
        _hitSoundCheckmark = [self addToggle:@(OBF("Hit Sound")) atY:rightYOffset action:@selector(hitSoundTapped) enabled:esp_hit_sound_enabled];
        rightYOffset += 32;
        _previewWindowCheckmark = [self addToggle:@(OBF("Preview Window")) atY:rightYOffset action:@selector(previewWindowTapped) enabled:esp_preview_window];
        rightYOffset += 32;
        _rainbowCheckmark = [self addToggle:@(OBF("Rainbow Function")) atY:rightYOffset action:@selector(rainbowTapped) enabled:esp_rainbow];
        rightYOffset += 32;
        _rainbowMenuCheckmark = [self addToggle:@(OBF("Rainbow Menu")) atY:rightYOffset action:@selector(rainbowMenuTapped) enabled:g_rainbowMenu];
        rightYOffset += 32;
        
        // Menu Effect (Снег/Дождь/Выкл)
        UILabel *effectLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX + 4, rightYOffset, colWidth - 8, 20)];
        effectLabel.text = @(OBF("Menu Effect"));
        effectLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        effectLabel.font = [UIFont systemFontOfSize:11];
        [_otherContent addSubview:effectLabel];
        rightYOffset += 22;
        
        CustomSegmentedControl *effectSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(rightColX + 4, rightYOffset, colWidth - 8, 28) items:@[@"Off", @"Snow", @"Rain"] current:esp_menu_effect];
        effectSelector.valueChanged = ^(NSInteger newIndex) {
            esp_menu_effect = (int)newIndex;
        };
        [_otherContent addSubview:effectSelector];
        rightYOffset += 34;

        // EUR — ESP Update Rate (30-60)
        UILabel *eurLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX + 4, rightYOffset, colWidth - 50, 20)];
        eurLabel.text = @"EUR";
        eurLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        eurLabel.font = [UIFont systemFontOfSize:11];
        [_otherContent addSubview:eurLabel];

        UILabel *eurValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX + colWidth - 46, rightYOffset, 46, 20)];
        eurValueLabel.textAlignment = NSTextAlignmentRight;
        eurValueLabel.textColor = [UIColor whiteColor];
        eurValueLabel.font = [UIFont systemFontOfSize:11];
        eurValueLabel.text = [NSString stringWithFormat:@"%d fps", esp_update_rate];
        [_otherContent addSubview:eurValueLabel];
        rightYOffset += 22;

        CustomSliderView *eurSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(rightColX + 4, rightYOffset, colWidth - 8, 28) min:30 max:60 current:(float)esp_update_rate];
        eurSlider.valueChanged = ^(float v) {
            esp_update_rate = (int)roundf(v);
            eurValueLabel.text = [NSString stringWithFormat:@"%d fps", esp_update_rate];
        };
        [_otherContent addSubview:eurSlider];
        rightYOffset += 34;

        UILabel *channelLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX, rightYOffset, colWidth, 20)];
        channelLabel.text = @(OBF("Наш канал:"));
        channelLabel.textColor = [UIColor whiteColor];
        channelLabel.font = [UIFont systemFontOfSize:11.0f];
        channelLabel.userInteractionEnabled = NO;
        [_otherContent addSubview:channelLabel];
        rightYOffset += 18;

        UILabel *channelLinkLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX, rightYOffset, colWidth, 20)];
        channelLinkLabel.text = @(OBF("t.me/evnbankoolo"));
        channelLinkLabel.textColor = [UIColor whiteColor];
        channelLinkLabel.font = [UIFont systemFontOfSize:11.0f];
        channelLinkLabel.userInteractionEnabled = NO;
        [_otherContent addSubview:channelLinkLabel];
        rightYOffset += 24;

        // --- Menu Color ---
        [self addSectionHeader:@(OBF("Menu Color")) atX:rightColX y:rightYOffset width:colWidth];
        rightYOffset += 22;
        __weak typeof(self) wsMenu = self;
        
        UIView *menuColorSwatch = [[UIView alloc] initWithFrame:CGRectMake(rightColX, rightYOffset, 30, 30)];
        menuColorSwatch.backgroundColor = [UIColor colorWithRed:g_menuR green:g_menuG blue:g_menuB alpha:1.0];
        menuColorSwatch.layer.cornerRadius = 6;
        menuColorSwatch.layer.borderWidth = 1;
        menuColorSwatch.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        menuColorSwatch.userInteractionEnabled = YES;
        menuColorSwatch.tag = 1001;
        UITapGestureRecognizer *menuTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorRowSwatchTapped:)];
        [menuColorSwatch addGestureRecognizer:menuTap];
        [_otherContent addSubview:menuColorSwatch];
        
        UILabel *menuColorLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX + 38, rightYOffset + 5, colWidth - 38, 20)];
        menuColorLabel.text = @(OBF("Menu Color"));
        menuColorLabel.textColor = [UIColor whiteColor];
        menuColorLabel.font = [UIFont systemFontOfSize:11];
        [_otherContent addSubview:menuColorLabel];
        rightYOffset += 36;

        // --- Text Color ---
        [self addSectionHeader:@(OBF("Text Color")) atX:rightColX y:rightYOffset width:colWidth];
        rightYOffset += 22;
        __weak typeof(self) wsText = self;
        
        UIView *textColorSwatch = [[UIView alloc] initWithFrame:CGRectMake(rightColX, rightYOffset, 30, 30)];
        textColorSwatch.backgroundColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:1.0];
        textColorSwatch.layer.cornerRadius = 6;
        textColorSwatch.layer.borderWidth = 1;
        textColorSwatch.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        textColorSwatch.userInteractionEnabled = YES;
        textColorSwatch.tag = 1002;
        UITapGestureRecognizer *textTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorRowSwatchTapped:)];
        [textColorSwatch addGestureRecognizer:textTap];
        [_otherContent addSubview:textColorSwatch];
        
        UILabel *textColorLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightColX + 38, rightYOffset + 5, colWidth - 38, 20)];
        textColorLabel.text = @(OBF("Text Color"));
        textColorLabel.textColor = [UIColor whiteColor];
        textColorLabel.font = [UIFont systemFontOfSize:11];
        [_otherContent addSubview:textColorLabel];
        rightYOffset += 36;

        _toggleColX = 0;
        _toggleColWidth = 0;
        [self refreshConfigList];

        _innerContent = nil;

        [self showViewForCapture];
    }
    return self;
}

// ── Color popup ──────────────────────────────────────────────────────────────
static UIView *g_colorPopup = nil;

static void showColorPopup(UIView *anchor, volatile float *rPtr, volatile float *gPtr, volatile float *bPtr) {
    if (g_colorPopup) { [g_colorPopup removeFromSuperview]; g_colorPopup = nil; }

    UIView *root = anchor.window;
    if (!root) return;

    UIView *overlay = [[UIView alloc] initWithFrame:root.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.01];
    overlay.userInteractionEnabled = YES;
    g_colorPopup = overlay;
    [root addSubview:overlay];

    // picker popup — будет повёрнут на 90°, поэтому pw/cpH меняются местами визуально
    CGFloat pw = MIN(root.bounds.size.width * 0.85, 300);
    CGFloat cpH = pw * 0.55 + 18 + 18 + 10 + 36 + 24 + 16;
    UIView *popup = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, cpH)];
    popup.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.97];
    popup.layer.cornerRadius = 12;
    popup.layer.shadowColor = [UIColor blackColor].CGColor;
    popup.layer.shadowRadius = 12;
    popup.layer.shadowOpacity = 0.5;
    popup.layer.shadowOffset = CGSizeZero;
    popup.userInteractionEnabled = YES;

    ColorPickerView *cp = [[ColorPickerView alloc] initWithFrame:CGRectMake(8, 8, pw - 16, cpH - 16) initialR:*rPtr g:*gPtr b:*bPtr];
    cp.onChange = ^(CGFloat r, CGFloat g, CGFloat b) { *rPtr = r; *gPtr = g; *bPtr = b;
        anchor.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    };
    [popup addSubview:cp];

    // Поворот на 90° по часовой стрелке
    popup.transform = CGAffineTransformMakeRotation(M_PI_2);

    // После поворота визуальные размеры: ширина = cpH, высота = pw
    CGRect anchorInRoot = [anchor convertRect:anchor.bounds toView:root];
    CGFloat visW = cpH, visH = pw;
    CGFloat px = anchorInRoot.origin.x - visW - 8;
    if (px < 8) px = anchorInRoot.origin.x + anchorInRoot.size.width + 8;
    CGFloat py = anchorInRoot.origin.y - visH / 2;
    py = MAX(8, MIN(py, root.bounds.size.height - visH - 8));
    popup.center = CGPointMake(px + visW / 2, py + visH / 2);

    [overlay addSubview:popup];

    // Перетаскивание попапа
    UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:popup action:@selector(handlePopupDrag:)];
    drag.cancelsTouchesInView = NO;
    [popup addGestureRecognizer:drag];

    objc_setAssociatedObject(overlay, "dismissBlock", ^{ [overlay removeFromSuperview]; if (g_colorPopup == overlay) g_colorPopup = nil; }, OBJC_ASSOCIATION_COPY_NONATOMIC);
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:overlay action:@selector(handleDismissTap:)];
    [overlay addGestureRecognizer:tap];
}

// ─────────────────────────────────────────────────────────────────────────────

- (void)addColorRow:(NSString *)name atY:(CGFloat)y inView:(UIView *)container
               rPtr:(volatile float *)rPtr gPtr:(volatile float *)gPtr bPtr:(volatile float *)bPtr
           onChange:(ColorPickCallback)onChange {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, y + 8, container.bounds.size.width - 60, 20)];
    lbl.text = name;
    lbl.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:1.0];
    lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [container addSubview:lbl];

    UIView *swatch = [[UIView alloc] initWithFrame:CGRectMake(container.bounds.size.width - 46, y + 5, 26, 26)];
    swatch.backgroundColor = [UIColor colorWithRed:*rPtr green:*gPtr blue:*bPtr alpha:1.0];
    swatch.layer.cornerRadius = 6;
    swatch.layer.borderWidth = 1.5;
    swatch.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    swatch.userInteractionEnabled = YES;
    [container addSubview:swatch];

    NSValue *rVal = [NSValue valueWithPointer:(void *)rPtr];
    NSValue *gVal = [NSValue valueWithPointer:(void *)gPtr];
    NSValue *bVal = [NSValue valueWithPointer:(void *)bPtr];
    objc_setAssociatedObject(swatch, "rPtr", rVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(swatch, "gPtr", gVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(swatch, "bPtr", bVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(swatch, "onChange", onChange, OBJC_ASSOCIATION_COPY_NONATOMIC);

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorRowSwatchTapped:)];
    [swatch addGestureRecognizer:tap];
}

- (void)colorRowSwatchTapped:(UITapGestureRecognizer *)g {
    UIView *swatch = g.view;
    
    // Проверяем tag для определения какой цвет менять
    if (swatch.tag == 1001) {
        // Menu Color
        __weak typeof(self) wsMenu = self;
        showColorPopup(swatch, &g_menuR, &g_menuG, &g_menuB);
        if (g_colorPopup) {
            for (UIView *sub in g_colorPopup.subviews) {
                for (UIView *cp in sub.subviews) {
                    if ([cp isKindOfClass:[ColorPickerView class]]) {
                        ((ColorPickerView *)cp).onChange = ^(CGFloat r, CGFloat g, CGFloat b) {
                            g_menuR = r; g_menuG = g; g_menuB = b;
                            swatch.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
                            [wsMenu applyMenuColor];
                        };
                    }
                }
            }
        }
    } else if (swatch.tag == 1002) {
        // Text Color
        __weak typeof(self) wsText = self;
        showColorPopup(swatch, &g_textR, &g_textG, &g_textB);
        if (g_colorPopup) {
            for (UIView *sub in g_colorPopup.subviews) {
                for (UIView *cp in sub.subviews) {
                    if ([cp isKindOfClass:[ColorPickerView class]]) {
                        ((ColorPickerView *)cp).onChange = ^(CGFloat r, CGFloat g, CGFloat b) {
                            g_textR = r; g_textG = g; g_textB = b;
                            swatch.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
                            [wsText applyTextColor];
                        };
                    }
                }
            }
        }
    } else {
        // Старый код для других цветов
        NSValue *rVal = objc_getAssociatedObject(swatch, "rPtr");
        NSValue *gVal = objc_getAssociatedObject(swatch, "gPtr");
        NSValue *bVal = objc_getAssociatedObject(swatch, "bPtr");
        ColorPickCallback onChange = objc_getAssociatedObject(swatch, "onChange");
        if (!rVal || !gVal || !bVal) return;
        volatile float *rPtr = (volatile float *)[rVal pointerValue];
        volatile float *gPtr = (volatile float *)[gVal pointerValue];
        volatile float *bPtr = (volatile float *)[bVal pointerValue];

        volatile float *rp = rPtr, *gp = gPtr, *bp = bPtr;
        UIView *sw = swatch;
        showColorPopup(swatch, rPtr, gPtr, bPtr);
        if (g_colorPopup) {
            for (UIView *sub in g_colorPopup.subviews) {
                for (UIView *cp in sub.subviews) {
                    if ([cp isKindOfClass:[ColorPickerView class]]) {
                        ((ColorPickerView *)cp).onChange = ^(CGFloat r, CGFloat g, CGFloat b) {
                            *rp = r; *gp = g; *bp = b;
                            sw.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
                            if (onChange) onChange(r, g, b);
                        };
                    }
                }
            }
        }
    }
}

- (void)addSectionHeader:(NSString *)title atY:(CGFloat)y {
    CGFloat colX = (_toggleColWidth > 0) ? _toggleColX : 0;
    CGFloat colW = (_toggleColWidth > 0) ? _toggleColWidth : _innerContent.bounds.size.width;
    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(colX + 4, y, colW - 8, 22)];
    h.text = title;
    h.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:0.55f];
    h.font = [UIFont boldSystemFontOfSize:11];
    h.userInteractionEnabled = NO;
    [_innerContent addSubview:h];
    [_sectionHeaders addObject:h];
}

- (void)addSectionHeader:(NSString *)title atX:(CGFloat)x y:(CGFloat)y width:(CGFloat)w {
    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(x + 4, y, w - 8, 22)];
    h.text = title;
    h.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:0.55f];
    h.font = [UIFont boldSystemFontOfSize:11];
    h.userInteractionEnabled = NO;
    [_innerContent addSubview:h];
    [_sectionHeaders addObject:h];
}

- (void)addSliderAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)w title:(NSString *)title
                 min:(float)mn max:(float)mx current:(float)cur fmt:(NSString *)fmt
        valueChanged:(void(^)(float))cb valueLabel:(__strong UILabel **)outLabel slider:(__strong CustomSliderView **)outSlider {
    UILabel *valLbl = [[UILabel alloc] initWithFrame:CGRectMake(x + w - 50, y, 46, 20)];
    valLbl.textColor = [UIColor whiteColor];
    valLbl.font = [UIFont systemFontOfSize:11];
    valLbl.textAlignment = NSTextAlignmentRight;
    valLbl.text = [NSString stringWithFormat:fmt, cur];
    [_innerContent addSubview:valLbl];
    if (outLabel) *outLabel = valLbl;

    CustomSliderView *sl = [[CustomSliderView alloc] initWithFrame:CGRectMake(x + 4, y + 22, w - 8, 28) min:mn max:mx current:cur];
    sl.valueChanged = ^(float v) {
        valLbl.text = [NSString stringWithFormat:fmt, v];
        if (cb) cb(v);
    };
    [_innerContent addSubview:sl];
    if (outSlider) *outSlider = sl;
}

- (CAShapeLayer *)addToggle:(NSString *)name atY:(CGFloat)y action:(SEL)action enabled:(BOOL)enabled {
    return [self addToggle:name atY:y action:action enabled:enabled colorR:nil g:nil b:nil show:NO];
}

- (CAShapeLayer *)addToggle:(NSString *)name atY:(CGFloat)y action:(SEL)action enabled:(BOOL)enabled
                    colorR:(volatile float *)rPtr g:(volatile float *)gPtr b:(volatile float *)bPtr
                      show:(BOOL)showSwatch {
    CGFloat colX = (_toggleColWidth > 0) ? _toggleColX : 0;
    CGFloat colW = (_toggleColWidth > 0) ? _toggleColWidth : _innerContent.bounds.size.width;
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(colX, y, colW, 30)];
    row.userInteractionEnabled = YES;
    row.backgroundColor = [UIColor colorWithRed:g_menuR green:g_menuG blue:g_menuB alpha:0.0];
    [_innerContent addSubview:row];
    [_rowViews addObject:row];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, colW - 80, 30)];
    label.text = name;
    label.textColor = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:1.0];
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.userInteractionEnabled = NO;
    [row addSubview:label];
    [_toggleLabels addObject:label];

    // color swatch (only if color pointers provided)
    if (rPtr && gPtr && bPtr) {
        UIView *swatch = [[UIView alloc] initWithFrame:CGRectMake(colW - 65, 5, 20, 20)];
        swatch.backgroundColor = [UIColor colorWithRed:*rPtr green:*gPtr blue:*bPtr alpha:1.0];
        swatch.layer.cornerRadius = 4;
        swatch.layer.borderWidth = 1.5;
        swatch.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
        swatch.hidden = !showSwatch;
        swatch.userInteractionEnabled = YES;
        swatch.tag = 9901;
        [row addSubview:swatch];

        NSValue *rVal = [NSValue valueWithPointer:(void *)rPtr];
        NSValue *gVal = [NSValue valueWithPointer:(void *)gPtr];
        NSValue *bVal = [NSValue valueWithPointer:(void *)bPtr];
        objc_setAssociatedObject(swatch, "rPtr", rVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(swatch, "gPtr", gVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(swatch, "bPtr", bVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        UITapGestureRecognizer *swatchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swatchTapped:)];
        [swatch addGestureRecognizer:swatchTap];
    }

    UIView *checkbox = [[UIView alloc] initWithFrame:CGRectMake(colW - 37, 4, 22, 22)];
    checkbox.layer.borderWidth = 2.0;
    checkbox.layer.borderColor = [UIColor whiteColor].CGColor;
    checkbox.layer.cornerRadius = 4.0;
    checkbox.userInteractionEnabled = NO;
    [row addSubview:checkbox];

    CAShapeLayer *checkmark = [self createCheckmarkLayer:checkbox.bounds];
    checkmark.opacity = enabled ? 1.0 : 0.0;
    [checkbox.layer addSublayer:checkmark];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    tap.cancelsTouchesInView = NO;
    [row addGestureRecognizer:tap];

    return checkmark;
}

- (void)swatchTapped:(UITapGestureRecognizer *)g {
    UIView *swatch = g.view;
    NSValue *rVal = objc_getAssociatedObject(swatch, "rPtr");
    NSValue *gVal = objc_getAssociatedObject(swatch, "gPtr");
    NSValue *bVal = objc_getAssociatedObject(swatch, "bPtr");
    if (!rVal || !gVal || !bVal) return;
    volatile float *rPtr = (volatile float *)[rVal pointerValue];
    volatile float *gPtr = (volatile float *)[gVal pointerValue];
    volatile float *bPtr = (volatile float *)[bVal pointerValue];
    showColorPopup(swatch, rPtr, gPtr, bPtr);
}

- (CAShapeLayer *)createCheckmarkLayer:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(rect.size.width * 0.20, rect.size.height * 0.50)];
    [path addLineToPoint:CGPointMake(rect.size.width * 0.42, rect.size.height * 0.72)];
    [path addLineToPoint:CGPointMake(rect.size.width * 0.80, rect.size.height * 0.28)];

    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 2.5;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    return layer;
}

- (void)animateCheckmark:(CAShapeLayer *)checkmark show:(BOOL)show {
    if (show) {
        checkmark.opacity = 1.0;
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        anim.fromValue = @0.0;
        anim.toValue = @1.0;
        anim.duration = 0.25;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        checkmark.strokeEnd = 1.0;
        [checkmark addAnimation:anim forKey:@"drawCheckmark"];
    } else {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        anim.fromValue = @1.0;
        anim.toValue = @0.0;
        anim.duration = 0.15;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        checkmark.opacity = 0.0;
        [checkmark addAnimation:anim forKey:@"hideCheckmark"];
    }
    // Обновляем preview window сразу при любом изменении
    [self refreshPreviewWindow];
}

- (void)boxTapped {
    esp_box_enabled = !esp_box_enabled;
    [self animateCheckmark:_boxCheckmark show:esp_box_enabled];
    if (!esp_box_enabled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ESPClearBoxes" object:nil];
    }
    [self setColorSwatch:_boxCheckmark visible:esp_box_enabled];
}

- (void)lineTapped {
    esp_line_enabled = !esp_line_enabled;
    [self animateCheckmark:_lineCheckmark show:esp_line_enabled];
    [self setColorSwatch:_lineCheckmark visible:esp_line_enabled];
}

- (void)setColorSwatch:(CAShapeLayer *)checkmark visible:(BOOL)visible {
    // checkmark is sublayer of checkbox which is subview of row
    CALayer *checkboxLayer = checkmark.superlayer;
    // find row — checkbox is direct subview of row
    UIView *row = nil;
    for (UIView *rv in _rowViews) {
        for (UIView *sub in rv.subviews) {
            if (sub.layer == checkboxLayer) { row = rv; break; }
        }
        if (row) break;
    }
    if (!row) return;
    for (UIView *sub in row.subviews) {
        if (sub.tag == 9901) { sub.hidden = !visible; return; }
    }
}

- (void)infAmmoTapped   { esp_inf_ammo   = !esp_inf_ammo;   [self animateCheckmark:_infAmmoCheckmark   show:esp_inf_ammo];   }
- (void)noSpreadTapped  { esp_no_spread  = !esp_no_spread;  [self animateCheckmark:_noSpreadCheckmark  show:esp_no_spread];  }
- (void)airJumpTapped   { esp_air_jump   = !esp_air_jump;   [self animateCheckmark:_airJumpCheckmark   show:esp_air_jump];   }
- (void)fastKnifeTapped { esp_fast_knife = !esp_fast_knife; [self animateCheckmark:_fastKnifeCheckmark show:esp_fast_knife]; }
- (void)bunnyHopTapped  { esp_bunny_hop  = !esp_bunny_hop;  [self animateCheckmark:_bunnyHopCheckmark  show:esp_bunny_hop];  }
- (void)wallshotTapped  { esp_wallshot   = !esp_wallshot;   [self animateCheckmark:_wallshotCheckmark  show:esp_wallshot];   }
- (void)fireRateTapped  { esp_fire_rate  = !esp_fire_rate;  [self animateCheckmark:_fireRateCheckmark  show:esp_fire_rate];  }

- (void)addskoreTapped {
    esp_addscore = !esp_addscore;
    [self animateCheckmark:_addscoreCheckmark show:esp_addscore];
}

- (void)invisibleTapped {
    esp_invisible = !esp_invisible;
    [self animateCheckmark:_invisibleCheckmark show:esp_invisible];
}

- (void)boxOutlineTapped {
    esp_box_outline = !esp_box_outline;
    [self animateCheckmark:_boxOutlineCheckmark show:esp_box_outline];
}

- (void)boxFillTapped {
    esp_box_fill = !esp_box_fill;
    [self animateCheckmark:_boxFillCheckmark show:esp_box_fill];
}

- (void)boxCornerTapped {
    esp_box_corner = !esp_box_corner;
    [self animateCheckmark:_boxCornerCheckmark show:esp_box_corner];
}

- (void)box3DTapped {
    esp_box_3d = !esp_box_3d;
    [self animateCheckmark:_box3DCheckmark show:esp_box_3d];
}


- (void)lineOutlineTapped {
    esp_line_outline = !esp_line_outline;
    [self animateCheckmark:_lineOutlineCheckmark show:esp_line_outline];
}

- (void)nameTapped {
    esp_name_enabled = !esp_name_enabled;
    [self animateCheckmark:_nameCheckmark show:esp_name_enabled];
}

- (void)nameOutlineTapped {
    esp_name_outline = !esp_name_outline;
    [self animateCheckmark:_nameOutlineCheckmark show:esp_name_outline];
}

- (void)addBoneSelectorAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    NSArray *items = @[@"Head", @"Neck", @"Spine", @"Hip"];
    _boneSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(10, y, w - 20, 28) items:items current:aimbot_bone_index];
    _boneSelector.valueChanged = ^(NSInteger newIndex) {
        aimbot_bone_index = (int)newIndex;
    };
    [_innerContent addSubview:_boneSelector];
}

- (void)addFovSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _fovValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _fovValueLabel.textColor = [UIColor whiteColor];
    _fovValueLabel.font = [UIFont systemFontOfSize:11];
    _fovValueLabel.textAlignment = NSTextAlignmentRight;
    _fovValueLabel.text = [NSString stringWithFormat:@"%.0f", aimbot_fov];
    [_innerContent addSubview:_fovValueLabel];

    _fovSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:10.0f max:180.0f current:aimbot_fov];
    __weak MenuView *weakSelf = self;
    _fovSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            aimbot_fov = newValue;
            strongSelf->_fovValueLabel.text = [NSString stringWithFormat:@"%.0f", aimbot_fov];
        }
    };
    [_innerContent addSubview:_fovSlider];
}

- (void)addSmoothSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _smoothValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _smoothValueLabel.textColor = [UIColor whiteColor];
    _smoothValueLabel.font = [UIFont systemFontOfSize:11];
    _smoothValueLabel.textAlignment = NSTextAlignmentRight;
    _smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
    [_innerContent addSubview:_smoothValueLabel];

    _smoothSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:0.0f max:20.0f current:aimbot_smooth];
    __weak MenuView *weakSelf = self;
    _smoothSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            aimbot_smooth = newValue;
            strongSelf->_smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
        }
    };
    [_innerContent addSubview:_smoothSlider];
}

- (void)addTriggerDelaySliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _triggerDelayValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _triggerDelayValueLabel.textColor = [UIColor whiteColor];
    _triggerDelayValueLabel.font = [UIFont systemFontOfSize:11];
    _triggerDelayValueLabel.textAlignment = NSTextAlignmentRight;
    _triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.2f", aimbot_trigger_delay];
    [_innerContent addSubview:_triggerDelayValueLabel];

    _triggerDelaySlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:0.01f max:1.0f current:aimbot_trigger_delay];
    __weak MenuView *weakSelf = self;
    _triggerDelaySlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            aimbot_trigger_delay = newValue;
            strongSelf->_triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.2f", aimbot_trigger_delay];
        }
    };
    [_innerContent addSubview:_triggerDelaySlider];
}

- (void)addRCSHSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _rcsHValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _rcsHValueLabel.textColor = [UIColor whiteColor];
    _rcsHValueLabel.font = [UIFont systemFontOfSize:11];
    _rcsHValueLabel.textAlignment = NSTextAlignmentRight;
    _rcsHValueLabel.text = [NSString stringWithFormat:@"%.1f", esp_rcs_h];
    [_innerContent addSubview:_rcsHValueLabel];

    _rcsHSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:0.0f max:10.0f current:esp_rcs_h];
    __weak MenuView *weakSelf = self;
    _rcsHSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            esp_rcs_h = newValue;
            strongSelf->_rcsHValueLabel.text = [NSString stringWithFormat:@"%.1f", esp_rcs_h];
        }
    };
    [_innerContent addSubview:_rcsHSlider];
}

- (void)addRCSVSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _rcsVValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _rcsVValueLabel.textColor = [UIColor whiteColor];
    _rcsVValueLabel.font = [UIFont systemFontOfSize:11];
    _rcsVValueLabel.textAlignment = NSTextAlignmentRight;
    _rcsVValueLabel.text = [NSString stringWithFormat:@"%.1f", esp_rcs_v];
    [_innerContent addSubview:_rcsVValueLabel];

    _rcsVSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:0.0f max:10.0f current:esp_rcs_v];
    __weak MenuView *weakSelf = self;
    _rcsVSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            esp_rcs_v = newValue;
            strongSelf->_rcsVValueLabel.text = [NSString stringWithFormat:@"%.1f", esp_rcs_v];
        }
    };
    [_innerContent addSubview:_rcsVSlider];
}

- (void)addBhopSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _bhopValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _bhopValueLabel.textColor = [UIColor whiteColor];
    _bhopValueLabel.font = [UIFont systemFontOfSize:11];
    _bhopValueLabel.textAlignment = NSTextAlignmentRight;
    _bhopValueLabel.text = [NSString stringWithFormat:@"%d", esp_bhop_setting];
    [_innerContent addSubview:_bhopValueLabel];

    _bhopSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:1.0f max:10.0f current:(float)esp_bhop_setting];
    __weak MenuView *weakSelf = self;
    _bhopSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            esp_bhop_setting = (int)newValue;
            strongSelf->_bhopValueLabel.text = [NSString stringWithFormat:@"%d", esp_bhop_setting];
        }
    };
    [_innerContent addSubview:_bhopSlider];
}


- (void)addViewmodelXSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    _viewmodelXValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _viewmodelXValueLabel.textColor = [UIColor whiteColor];
    _viewmodelXValueLabel.font = [UIFont systemFontOfSize:11];
    _viewmodelXValueLabel.textAlignment = NSTextAlignmentRight;
    _viewmodelXValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_x];
    [_innerContent addSubview:_viewmodelXValueLabel];

    _viewmodelXSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:-10.0f max:10.0f current:viewmodel_x];
    __weak MenuView *weakSelf = self;
    _viewmodelXSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            viewmodel_x = newValue;
            strongSelf->_viewmodelXValueLabel.text = [NSString stringWithFormat:@"%.1f", newValue];
        }
    };
    [_innerContent addSubview:_viewmodelXSlider];
}

- (void)addViewmodelYSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    _viewmodelYValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _viewmodelYValueLabel.textColor = [UIColor whiteColor];
    _viewmodelYValueLabel.font = [UIFont systemFontOfSize:11];
    _viewmodelYValueLabel.textAlignment = NSTextAlignmentRight;
    _viewmodelYValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_y];
    [_innerContent addSubview:_viewmodelYValueLabel];

    _viewmodelYSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:-10.0f max:10.0f current:viewmodel_y];
    __weak MenuView *weakSelf = self;
    _viewmodelYSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            viewmodel_y = newValue;
            strongSelf->_viewmodelYValueLabel.text = [NSString stringWithFormat:@"%.1f", newValue];
        }
    };
    [_innerContent addSubview:_viewmodelYSlider];
}

- (void)addViewmodelZSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    _viewmodelZValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _viewmodelZValueLabel.textColor = [UIColor whiteColor];
    _viewmodelZValueLabel.font = [UIFont systemFontOfSize:11];
    _viewmodelZValueLabel.textAlignment = NSTextAlignmentRight;
    _viewmodelZValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_z];
    [_innerContent addSubview:_viewmodelZValueLabel];

    _viewmodelZSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:-10.0f max:10.0f current:viewmodel_z];
    __weak MenuView *weakSelf = self;
    _viewmodelZSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            viewmodel_z = newValue;
            strongSelf->_viewmodelZValueLabel.text = [NSString stringWithFormat:@"%.1f", newValue];
        }
    };
    [_innerContent addSubview:_viewmodelZSlider];
}

- (void)refreshConfigList {
    // Теперь конфиги в _otherContent, удаляем старые элементы списка
    for (UIView *v in [_otherContent subviews]) {
        if (v.frame.origin.y >= _configListStartY && v.frame.origin.x < _otherContent.bounds.size.width / 2) {
            [v removeFromSuperview];
        }
    }
    
    NSArray *configs = cfg_get_list();
    CGFloat y = _configListStartY;
    CGFloat leftColX = 10;
    CGFloat colWidth = _otherContent.bounds.size.width / 2 - 15;
    
    for (NSString *name in configs) {
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(leftColX, y, colWidth, 28)];
        lbl.text = [NSString stringWithFormat:@"  %@", name];
        lbl.font = [UIFont systemFontOfSize:11];
        lbl.textColor = [UIColor whiteColor];
        lbl.backgroundColor = [name isEqualToString:esp_selected_config] ? [UIColor colorWithWhite:1 alpha:0.3] : [UIColor colorWithWhite:1 alpha:0.1];
        lbl.layer.cornerRadius = 4;
        lbl.layer.masksToBounds = YES;
        lbl.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectConfigLbl:)];
        [lbl addGestureRecognizer:tap];
        
        [_otherContent addSubview:lbl];
        y += 32;
    }
}

- (void)selectConfigLbl:(UITapGestureRecognizer *)sender {
    UILabel *lbl = (UILabel *)sender.view;
    NSString *name = [lbl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    esp_selected_config = name;
    [self refreshConfigList];
}

static __attribute__((unused)) std::string readUnityString(uintptr_t str_ptr, task_t task) {
    if (!str_ptr) return "";
    int length = Read<int>(str_ptr + 0x10, task);
    if (length <= 0 || length > 256) return "";
    std::string result;
    result.reserve(length);
    for (int i = 0; i < length; i++) {
        char16_t c = Read<char16_t>(str_ptr + 0x14 + i * 2, task);
        if (c < 128) result += (char)c;
        else result += '?';
    }
    return result;
}

- (void)refreshSkinList {
    static pid_t c_pid = 0;
    static task_t c_task = 0;
    static mach_vm_address_t c_base = 0;

    pid_t pid = get_pid_by_name("Standoff2");
    if (pid <= 0) {
        c_pid = 0; c_task = 0; c_base = 0;
        return;
    }

    if (pid != c_pid || !c_task || !c_base) {
        c_task = get_task_by_pid(pid);
        if (c_task) c_base = get_image_base_address(c_task, "UnityFramework");
        c_pid = pid;
    }

    if (!c_task || !c_base) return;

    uintptr_t typeInfo = Read<uintptr_t>(c_base + 148040544, c_task);
    if (!typeInfo) return;

    // staticFields хранится прямо в typeInfo + 0xB8 (или 0xB0)
    uintptr_t staticFields = Read<uintptr_t>(typeInfo + 0xB8, c_task);
    if (!staticFields || staticFields < 0x1000000)
        staticFields = Read<uintptr_t>(typeInfo + 0xB0, c_task);
    if (!staticFields || staticFields < 0x1000000) {
        // Попробуем через parentTypeInfo
        uintptr_t parentTypeInfo = Read<uintptr_t>(typeInfo + 0x58, c_task);
        if (!parentTypeInfo || parentTypeInfo < 0x1000000) return;
        staticFields = Read<uintptr_t>(parentTypeInfo + 0xB8, c_task);
        if (!staticFields || staticFields < 0x1000000)
            staticFields = Read<uintptr_t>(parentTypeInfo + 0xB0, c_task);
        if (!staticFields || staticFields < 0x1000000) return;
    }

    uintptr_t inventoryManager = Read<uintptr_t>(staticFields, c_task);
    if (!inventoryManager || inventoryManager < 0x1000000) return;

    if (_skinContainer.hidden) return;

    // Dictionary<int, InventoryItemDefinition> @ 0x38 — all item definitions
    uintptr_t droppedDict = Read<uintptr_t>(inventoryManager + 0x38, c_task);
    int droppedCount = (droppedDict > 0x1000000) ? Read<int>(droppedDict + 0x20, c_task) : 0;
    if (droppedCount > 0 && droppedCount < 10000) {
        _allSkinsMap.clear();
        _allSkinsList.clear();
        uintptr_t entries = Read<uintptr_t>(droppedDict + 0x18, c_task);
        for (int i = 0; i < droppedCount; i++) {
            uintptr_t skin = Read<uintptr_t>(entries + 0x20 + 0x10 + 0x18 * i, c_task);
            if (!skin) continue;
            int sid = Read<int>(skin + 0x10, c_task);
            uintptr_t namePtr = Read<uintptr_t>(skin + 0x18, c_task);
            std::string name = readUnityString(namePtr, c_task);
            if (!name.empty()) {
                _allSkinsMap[sid] = name;
                NSString *nsName = [NSString stringWithUTF8String:name.c_str()].lowercaseString;
                BOOL isPremium =
                    [nsName containsString:@"knife"] ||
                    [nsName containsString:@"m9"] ||
                    [nsName containsString:@"bayonet"] ||
                    [nsName containsString:@"karambit"] ||
                    [nsName containsString:@"butterfly"] ||
                    [nsName containsString:@"kunai"] ||
                    [nsName containsString:@"jkommando"] ||
                    [nsName containsString:@"dual"] ||
                    [nsName containsString:@"gloves"];
                if (isPremium && ![nsName containsString:@"case"] && ![nsName containsString:@"graffiti"]) {
                    _allSkinsList.push_back({sid, name});
                }
            }
        }
    }

    // Dictionary<int, WeaponParameters> @ 0x28 — owned skins
    // Получаем BoltInventory напрямую через его TypeInfo
    uintptr_t boltTypeInfo = Read<uintptr_t>(c_base + 148490880, c_task);
    uintptr_t boltInventory = 0;
    if (boltTypeInfo > 0x1000000) {
        uintptr_t boltStatic = Read<uintptr_t>(boltTypeInfo + 0xB8, c_task);
        if (!boltStatic || boltStatic < 0x1000000)
            boltStatic = Read<uintptr_t>(boltTypeInfo + 0xB0, c_task);
        if (boltStatic > 0x1000000)
            boltInventory = Read<uintptr_t>(boltStatic, c_task);
    }

    _ownedSkinsInfo.clear();
    NSMutableArray *ownedLabels = [NSMutableArray array];

    if (boltInventory > 0x1000000) {
        // List<CDHCHDHHCCCEHAA> @ 0xE0
        uintptr_t itemsList = Read<uintptr_t>(boltInventory + 0xE0, c_task);
        int count = (itemsList > 0x1000000) ? Read<int>(itemsList + 0x18, c_task) : 0;
        if (count > 0 && count < 2000) {
            uintptr_t items = Read<uintptr_t>(itemsList + 0x10, c_task);
            for (int i = 0; i < count; i++) {
                uintptr_t item = Read<uintptr_t>(items + 0x20 + 0x8 * i, c_task);
                if (!item || item < 0x1000000) continue;
                int sid = Read<int>(item + 0x10, c_task);
                if (sid <= 0) continue;
                _ownedSkinsInfo.push_back({sid, item});
                NSString *nsName = _allSkinsMap.count(sid)
                    ? [NSString stringWithUTF8String:_allSkinsMap[sid].c_str()]
                    : [NSString stringWithFormat:@"Item #%d", sid];
                [ownedLabels addObject:nsName];
            }
        }
    }

    for (UIView *v in [_skinContent subviews]) {
        [v removeFromSuperview];
    }
    
    CGFloat y = 4;
    [self addSectionHeader:@"YOUR INVENTORY" atY:y]; y += 26;
    
    if (_ownedSkinsInfo.empty()) {
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _skinContent.bounds.size.width-20, 30)];
        empty.text = @"Inventory empty";
        empty.textColor = [UIColor grayColor];
        empty.font = [UIFont italicSystemFontOfSize:12];
        [_skinContent addSubview:empty];
        y += 40;
    } else {
        for (int i = 0; i < _ownedSkinsInfo.size(); i++) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _skinContent.bounds.size.width - 20, 30)];
            lbl.text = [NSString stringWithFormat:@"  %@", ownedLabels[i]];
            lbl.font = [UIFont systemFontOfSize:13];
            lbl.textColor = [UIColor whiteColor];
            lbl.backgroundColor = (i == _selectedOwnedIdx) ? [UIColor colorWithWhite:1 alpha:0.3] : [UIColor colorWithWhite:1 alpha:0.1];
            lbl.layer.cornerRadius = 4;
            lbl.layer.masksToBounds = YES;
            lbl.userInteractionEnabled = YES;
            lbl.tag = 1000 + i;
            [lbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ownedSkinTapped:)]];
            [_skinContent addSubview:lbl];
            y += 35;
        }
    }
    
    y += 10;
    [self addSectionHeader:@"SELECT REPLACEMENT" atY:y]; y += 26;
    
    if (_allSkinsList.empty()) {
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _skinContent.bounds.size.width-20, 30)];
        empty.text = @"No replacement skins found";
        empty.textColor = [UIColor grayColor];
        [_skinContent addSubview:empty];
        y += 40;
    } else {
        for (int i = 0; i < _allSkinsList.size(); i++) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, _skinContent.bounds.size.width - 20, 30)];
            lbl.text = [NSString stringWithFormat:@"  %@", [NSString stringWithUTF8String:_allSkinsList[i].second.c_str()]];
            lbl.font = [UIFont systemFontOfSize:13];
            lbl.textColor = [UIColor whiteColor];
            lbl.backgroundColor = (i == _selectedReplaceIdx) ? [UIColor colorWithWhite:1 alpha:0.3] : [UIColor colorWithWhite:1 alpha:0.1];
            lbl.layer.cornerRadius = 4;
            lbl.layer.masksToBounds = YES;
            lbl.userInteractionEnabled = YES;
            lbl.tag = 2000 + i;
            [lbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replaceSkinTapped:)]];
            [_skinContent addSubview:lbl];
            y += 35;
        }
    }

    CGRect cf = _skinContent.frame;
    cf.size.height = y + 10;
    _skinContent.frame = cf;
}

- (void)ownedSkinTapped:(UITapGestureRecognizer *)g {
    _selectedOwnedIdx = (int)g.view.tag - 1000;
    [self refreshSkinList];
    [self tryApplySkinPair];
}

- (void)replaceSkinTapped:(UITapGestureRecognizer *)g {
    _selectedReplaceIdx = (int)g.view.tag - 2000;
    [self refreshSkinList];
    [self tryApplySkinPair];
}

- (void)tryApplySkinPair {
    if (_selectedOwnedIdx >= 0 && _selectedOwnedIdx < _ownedSkinsInfo.size() && 
        _selectedReplaceIdx >= 0 && _selectedReplaceIdx < _allSkinsList.size()) {
        
        uintptr_t skinPtr = _ownedSkinsInfo[_selectedOwnedIdx].second;
        int newId = _allSkinsList[_selectedReplaceIdx].first;
        
        pid_t pid = get_pid_by_name("Standoff2");
        if (pid > 0) {
            task_t task = get_task_by_pid(pid);
            if (task) {
                // CDHCHDHHCCCEHAA.FAHEBCCGAFCDAHF (DefinitionId) @ 0x10
                Write<int>(skinPtr + 0x10, newId, task);
            }
        }
    }
}



- (void)createConfigFlow {
    NSString *dir = cfg_get_dir();
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
    NSInteger count = 1;
    for (NSString *f in files) {
        if ([f hasSuffix:@".plist"]) count++;
    }
    NSString *name = [NSString stringWithFormat:@"Config %ld", (long)count];
    // ensure unique name
    while ([[NSFileManager defaultManager] fileExistsAtPath:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", name]]]) {
        count++;
        name = [NSString stringWithFormat:@"Config %ld", (long)count];
    }
    cfg_create(name);
    esp_selected_config = name;
    [self refreshConfigList];
}

- (void)deleteConfigFlow {
    if (esp_selected_config.length > 0) {
        cfg_delete(esp_selected_config);
        esp_selected_config = nil;
        [self refreshConfigList];
    }
}

- (void)loadConfigFlow {
    if (esp_selected_config.length > 0) {
        cfg_load(esp_selected_config);
        
        [self animateCheckmark:_boxCheckmark show:esp_box_enabled];
        [self animateCheckmark:_boxOutlineCheckmark show:esp_box_outline];
        [self animateCheckmark:_boxFillCheckmark show:esp_box_fill];
        [self animateCheckmark:_boxCornerCheckmark show:esp_box_corner];
        [self animateCheckmark:_box3DCheckmark show:esp_box_3d];
        [self animateCheckmark:_lineCheckmark show:esp_line_enabled];
        [self animateCheckmark:_lineOutlineCheckmark show:esp_line_outline];
        [self animateCheckmark:_invisibleCheckmark show:esp_invisible];
        [self animateCheckmark:_addscoreCheckmark show:esp_addscore];
        [self animateCheckmark:_infAmmoCheckmark show:esp_inf_ammo];
        [self animateCheckmark:_noSpreadCheckmark show:esp_no_spread];
        [self animateCheckmark:_airJumpCheckmark show:esp_air_jump];
        [self animateCheckmark:_fastKnifeCheckmark show:esp_fast_knife];
        [self animateCheckmark:_bunnyHopCheckmark show:esp_bunny_hop];
        [self animateCheckmark:_wallshotCheckmark show:esp_wallshot];
        [self animateCheckmark:_fireRateCheckmark show:esp_fire_rate];
        [self animateCheckmark:_teamCheckmark show:esp_team_check];
        [self animateCheckmark:_nameCheckmark show:esp_name_enabled];
        [self animateCheckmark:_nameOutlineCheckmark show:esp_name_outline];
        [self animateCheckmark:_healthCheckmark show:esp_health_enabled];
        [self animateCheckmark:_healthBarCheckmark show:esp_health_bar_enabled];
        [self animateCheckmark:_healthBarOutlineCheckmark show:esp_health_bar_outline];
        [self animateCheckmark:_weaponCheckmark show:esp_weapon_enabled];
        [self animateCheckmark:_platformCheckmark show:esp_platform_enabled];
        [self animateCheckmark:_aimbotCheckmark show:aimbot_enabled];
        [self animateCheckmark:_visibleCheckCheckmark show:aimbot_visible_check];
        [self animateCheckmark:_shootingCheckCheckmark show:aimbot_shooting_check];
        [self animateCheckmark:_rcsCheckmark show:esp_rcs_enabled];
        [self animateCheckmark:_triggerbotCheckmark show:aimbot_triggerbot];
        [self animateCheckmark:_aimbotFovVisibleCheckmark show:aimbot_fov_visible];
        [self animateCheckmark:_aimbotTeamCheckmark show:aimbot_team_check];
        [self animateCheckmark:_viewmodelCheckmark show:viewmodel_enabled];
        [self animateCheckmark:_screenshotSafeCheckmark show:esp_screenshot_safe];
        
        if (self.superview) [self.superview hideViewFromCapture:esp_screenshot_safe];
        else [self hideViewFromCapture:esp_screenshot_safe];

        _fovValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_fov];
        _fovSlider.value = aimbot_fov;
        
        _smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
        _smoothSlider.value = aimbot_smooth;

        _triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_trigger_delay];
        _triggerDelaySlider.value = aimbot_trigger_delay;

        _rcsHValueLabel.text = [NSString stringWithFormat:@"%.1f", esp_rcs_h];
        _rcsHSlider.value = esp_rcs_h;

        _rcsVValueLabel.text = [NSString stringWithFormat:@"%.1f", esp_rcs_v];
        _rcsVSlider.value = esp_rcs_v;
        
        _bhopValueLabel.text = [NSString stringWithFormat:@"%d", esp_bhop_setting];
        _bhopSlider.value = esp_bhop_setting;
        
        _viewmodelXValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_x];
        _viewmodelXSlider.value = viewmodel_x;
        _viewmodelYValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_y];
        _viewmodelYSlider.value = viewmodel_y;
        _viewmodelZValueLabel.text = [NSString stringWithFormat:@"%.1f", viewmodel_z];
        _viewmodelZSlider.value = viewmodel_z;
        
        if (_boneSelector) {
            [_boneSelector reloadUI:aimbot_bone_index];
        }

        [self applyMenuColor];
        [self applyTextColor];
    }
}

- (UIViewController *)_topViewController {
    // Ищем window с наибольшим уровнем который может презентовать VC
    UIWindow *bestWin = nil;
    for (UIWindow *win in [UIApplication sharedApplication].windows) {
        if (!win.isHidden && win.rootViewController && win.windowLevel < 10000000) {
            if (!bestWin || win.windowLevel > bestWin.windowLevel) {
                bestWin = win;
            }
        }
    }
    if (!bestWin) {
        // Fallback — берём любой window с rootVC
        for (UIWindow *win in [UIApplication sharedApplication].windows) {
            if (win.rootViewController) { bestWin = win; break; }
        }
    }
    UIViewController *vc = bestWin.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

- (void)shareConfigFlow {
    if (!esp_selected_config.length) return;
    NSString *fileName = [NSString stringWithFormat:@"wxr_conf_%@.confing", esp_selected_config];
    NSString *path = [cfg_get_dir() stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return;

    NSURL *fileURL = [NSURL fileURLWithPath:path];

    UIDocumentInteractionController *dic = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    objc_setAssociatedObject(self, "docIC", dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Ищем view из нашего HUD window
    UIWindow *hudWin = self.window;
    UIView *anchor = hudWin ? hudWin.rootViewController.view : self;
    CGRect rect = CGRectMake(anchor.bounds.size.width/2 - 1, anchor.bounds.size.height/2 - 1, 2, 2);

    BOOL ok = [dic presentOptionsMenuFromRect:rect inView:anchor animated:YES];
    if (!ok) {
        ok = [dic presentOpenInMenuFromRect:rect inView:anchor animated:YES];
    }
    if (!ok) {
        // Последний fallback через UIActivityViewController
        UIActivityViewController *avc = [[UIActivityViewController alloc]
            initWithActivityItems:@[fileURL] applicationActivities:nil];
        UIViewController *root = [self _topViewController];
        if (root) {
            avc.popoverPresentationController.sourceView = root.view;
            avc.popoverPresentationController.sourceRect = rect;
            [root presentViewController:avc animated:YES completion:nil];
        }
    }
}

- (void)importConfigFlow {
    UIViewController *root = [self _topViewController];
    if (!root) return;

    UIDocumentPickerViewController *picker;
    if (@available(iOS 14.0, *)) {
        UTType *dataType = [UTType typeWithIdentifier:@"public.data"];
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[dataType]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        picker = [[UIDocumentPickerViewController alloc]
            initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
#pragma clang diagnostic pop
    }
    picker.delegate = (id<UIDocumentPickerDelegate>)self;
    picker.allowsMultipleSelection = NO;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [root presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    NSString *fileName = url.lastPathComponent;
    if (![fileName hasSuffix:@".confing"]) return;

    NSString *destPath = [cfg_get_dir() stringByAppendingPathComponent:fileName];
    NSError *err = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:destPath])
        [[NSFileManager defaultManager] removeItemAtPath:destPath error:nil];
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:destPath] error:&err];

    if (!err) {
        // Показываем имя без префикса и расширения
        NSString *displayName = [fileName stringByDeletingPathExtension];
        if ([displayName hasPrefix:@"wxr_conf_"])
            displayName = [displayName substringFromIndex:9];
        esp_selected_config = displayName;
        [self refreshConfigList];
    }
}




- (void)visibleCheckTapped  { aimbot_visible_check  = !aimbot_visible_check;  [self animateCheckmark:_visibleCheckCheckmark  show:aimbot_visible_check];  }
- (void)shootingCheckTapped { aimbot_shooting_check = !aimbot_shooting_check; [self animateCheckmark:_shootingCheckCheckmark show:aimbot_shooting_check]; }
- (void)knifeBotTapped      { aimbot_knife_bot      = !aimbot_knife_bot;      [self animateCheckmark:_knifeBotCheckmark      show:aimbot_knife_bot];      }
- (void)rcsTapped           { esp_rcs_enabled       = !esp_rcs_enabled;       [self animateCheckmark:_rcsCheckmark           show:esp_rcs_enabled];       }


- (void)viewmodelTapped {
    viewmodel_enabled = !viewmodel_enabled;
    [self animateCheckmark:_viewmodelCheckmark show:viewmodel_enabled];
}


- (void)aimbotTapped {
    aimbot_enabled = !aimbot_enabled;
    [self animateCheckmark:_aimbotCheckmark show:aimbot_enabled];
}

- (void)triggerbotTapped {
    aimbot_triggerbot = !aimbot_triggerbot;
    [self animateCheckmark:_triggerbotCheckmark show:aimbot_triggerbot];
}

- (void)aimbotFovTapped {
    aimbot_fov_visible = !aimbot_fov_visible;
    [self animateCheckmark:_aimbotFovVisibleCheckmark show:aimbot_fov_visible];
}

- (void)teamTapped {
    esp_team_check = !esp_team_check;
    [self animateCheckmark:_teamCheckmark show:esp_team_check];
}

- (void)healthTapped {
    esp_health_enabled = !esp_health_enabled;
    [self animateCheckmark:_healthCheckmark show:esp_health_enabled];
}


- (void)healthBarTapped {
    esp_health_bar_enabled = !esp_health_bar_enabled;
    [self animateCheckmark:_healthBarCheckmark show:esp_health_bar_enabled];
}

- (void)healthBarOutlineTapped {
    esp_health_bar_outline = !esp_health_bar_outline;
    [self animateCheckmark:_healthBarOutlineCheckmark show:esp_health_bar_outline];
}

- (void)weaponTapped {
    esp_weapon_enabled = !esp_weapon_enabled;
    [self animateCheckmark:_weaponCheckmark show:esp_weapon_enabled];
}

- (void)weaponIconTapped {
    esp_weapon_icon_enabled = !esp_weapon_icon_enabled;
    [self animateCheckmark:_weaponIconCheckmark show:esp_weapon_icon_enabled];
}

- (void)platformTapped {
    esp_platform_enabled = !esp_platform_enabled;
    [self animateCheckmark:_platformCheckmark show:esp_platform_enabled];
}

- (void)avatarTapped {
    esp_avatar_enabled = !esp_avatar_enabled;
    [self animateCheckmark:_avatarCheckmark show:esp_avatar_enabled];
}

- (void)screenshotSafeTapped {
    esp_screenshot_safe = !esp_screenshot_safe;
    [self animateCheckmark:_screenshotSafeCheckmark show:esp_screenshot_safe];
    
    if (self.superview) {
        [self.superview hideViewFromCapture:esp_screenshot_safe];
    } else {
        [self hideViewFromCapture:esp_screenshot_safe];
    }
}

- (void)hitSoundTapped {
    esp_hit_sound_enabled = !esp_hit_sound_enabled;
    [self animateCheckmark:_hitSoundCheckmark show:esp_hit_sound_enabled];
}

- (void)previewWindowTapped {
    esp_preview_window = !esp_preview_window;
    [self animateCheckmark:_previewWindowCheckmark show:esp_preview_window];
    
    if (esp_preview_window) {
        [self showPreviewWindow];
    } else {
        [self hidePreviewWindow];
    }
}

- (void)showPreviewWindow {
    if (_previewWindow) return;
    
    UIView *parentView = self.superview;
    if (!parentView) return;
    
    CGFloat menuH = self.frame.size.height;
    
    // Вертикальный прямоугольник: высота = высота меню, ширина = высота меню * 0.6 (портрет)
    CGFloat previewW = menuH * 0.6f;
    CGFloat previewH = menuH;
    
    // Позиция справа от меню, выровнена по верху
    CGFloat previewX = self.frame.origin.x + self.frame.size.width + 12;
    CGFloat previewY = self.frame.origin.y;
    
    _previewWindow = [[UIView alloc] initWithFrame:CGRectMake(previewX, previewY, previewW, previewH)];
    _previewWindow.backgroundColor = [UIColor colorWithRed:0.156 green:0.158 blue:0.258 alpha:1.0];
    _previewWindow.layer.cornerRadius = 12.0;
    _previewWindow.layer.borderWidth = 1;
    _previewWindow.layer.borderColor = [UIColor colorWithRed:0.565 green:0.481 blue:1.0 alpha:0.4].CGColor;
    _previewWindow.clipsToBounds = YES;
    _previewWindow.userInteractionEnabled = NO;
    
    // Заголовок
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, previewW, 20)];
    headerLabel.text = @"Preview";
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:12];
    [_previewWindow addSubview:headerLabel];
    
    // Разделитель
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(8, 28, previewW - 16, 1)];
    sep.backgroundColor = [UIColor colorWithRed:0.565 green:0.481 blue:1.0 alpha:0.5];
    [_previewWindow addSubview:sep];
    
    // Контент — весь оставшийся размер
    UIView *previewContent = [[UIView alloc] initWithFrame:CGRectMake(0, 32, previewW, previewH - 32)];
    previewContent.backgroundColor = [UIColor clearColor];
    previewContent.tag = 8888;
    [_previewWindow addSubview:previewContent];
    
    [self drawPreviewESP:previewContent];
    
    [parentView addSubview:_previewWindow];
    
    _previewWindow.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _previewWindow.alpha = 1;
    } completion:nil];
}

- (void)refreshPreviewWindow {
    if (!_previewWindow) return;
    UIView *content = [_previewWindow viewWithTag:8888];
    if (!content) return;
    // Удаляем старые subviews и слои
    for (UIView *v in [content.subviews copy]) [v removeFromSuperview];
    for (CALayer *l in [content.layer.sublayers copy]) [l removeFromSuperlayer];
    [self drawPreviewESP:content];
}

- (void)hidePreviewWindow {
    if (!_previewWindow) return;
    
    [UIView animateWithDuration:0.25 animations:^{
        _previewWindow.alpha = 0;
        _previewWindow.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [_previewWindow removeFromSuperview];
        _previewWindow = nil;
    }];
}

- (void)rebuildVisualContent {
    // Удаляем все subviews из _visualContent
    for (UIView *subview in [_visualContent.subviews copy]) {
        [subview removeFromSuperview];
    }
    
    // Пересоздаём контент (копия кода из initWithFrame)
    _innerContent = _visualContent;
    CGFloat yOffset = 4;
    CGFloat visCol2X = _visualContent.bounds.size.width / 2.0f + 5;
    CGFloat visCol2W = _visualContent.bounds.size.width / 2.0f - 10;
    _toggleColX = 0;
    _toggleColWidth = visCol2X - 5;

    // Left column
    [self addSectionHeader:@(OBF("ESP")) atY:yOffset];
    yOffset += 26;
    _boxCheckmark = [self addToggle:@(OBF("Box 2D")) atY:yOffset action:@selector(boxTapped) enabled:esp_box_enabled colorR:&esp_box_r g:&esp_box_g b:&esp_box_b show:YES];
    yOffset += 32;
    _boxOutlineCheckmark = [self addToggle:@(OBF("Box Outline")) atY:yOffset action:@selector(boxOutlineTapped) enabled:esp_box_outline];
    yOffset += 32;
    _boxFillCheckmark = [self addToggle:@(OBF("Box Fill")) atY:yOffset action:@selector(boxFillTapped) enabled:esp_box_fill];
    yOffset += 32;
    _boxCornerCheckmark = [self addToggle:@(OBF("Box Corner")) atY:yOffset action:@selector(boxCornerTapped) enabled:esp_box_corner];
    yOffset += 32;
    _box3DCheckmark = [self addToggle:@(OBF("Box 3D")) atY:yOffset action:@selector(box3DTapped) enabled:esp_box_3d];
    yOffset += 32;
    _lineCheckmark = [self addToggle:@(OBF("Line")) atY:yOffset action:@selector(lineTapped) enabled:esp_line_enabled colorR:&esp_line_r g:&esp_line_g b:&esp_line_b show:YES];
    yOffset += 32;
    _lineOutlineCheckmark = [self addToggle:@(OBF("Line Outline")) atY:yOffset action:@selector(lineOutlineTapped) enabled:esp_line_outline];
    yOffset += 32;
    {
        CGFloat segW = _toggleColWidth > 0 ? _toggleColWidth : _visualContent.bounds.size.width;
        NSArray *lineModes = @[@"Top", @"Center", @"Bottom"];
        _lineModeSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(4, yOffset, segW - 8, 26) items:lineModes current:esp_line_mode];
        _lineModeSelector.valueChanged = ^(NSInteger idx){ esp_line_mode = (int)idx; };
        [_innerContent addSubview:_lineModeSelector];
        yOffset += 32;
    }
    _teamCheckmark = [self addToggle:@(OBF("Team Check")) atY:yOffset action:@selector(teamTapped) enabled:esp_team_check];
    yOffset += 32;
    _nameCheckmark = [self addToggle:@(OBF("Name")) atY:yOffset action:@selector(nameTapped) enabled:esp_name_enabled colorR:&esp_name_r g:&esp_name_g b:&esp_name_b show:YES];
    yOffset += 32;

    [self addSectionHeader:@(OBF("Thickness")) atY:yOffset]; yOffset += 24;
    [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:0.5f max:6.0f current:esp_box_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_box_thickness = v; } valueLabel:&_boxThicknessValueLabel slider:&_boxThicknessSlider];
    yOffset += 50;
    [self addSectionHeader:@(OBF("Box 3D")) atY:yOffset]; yOffset += 24;
    [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:0.5f max:6.0f current:esp_box3d_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_box3d_thickness = v; } valueLabel:&_box3dThicknessValueLabel slider:&_box3dThicknessSlider];
    yOffset += 50;

    [self addSectionHeader:@(OBF("VIEWMODEL")) atY:yOffset]; yOffset += 26;
    _viewmodelCheckmark = [self addToggle:@(OBF("Viewmodel")) atY:yOffset action:@selector(viewmodelTapped) enabled:viewmodel_enabled];
    yOffset += 34;
    [self addSectionHeader:@(OBF("View X")) atY:yOffset]; yOffset += 24;
    [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:-5.0f max:5.0f current:viewmodel_x fmt:@"%.1f" valueChanged:^(float v){ viewmodel_x = v; } valueLabel:&_viewmodelXValueLabel slider:&_viewmodelXSlider];
    yOffset += 50;
    [self addSectionHeader:@(OBF("View Y")) atY:yOffset]; yOffset += 24;
    [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:-5.0f max:5.0f current:viewmodel_y fmt:@"%.1f" valueChanged:^(float v){ viewmodel_y = v; } valueLabel:&_viewmodelYValueLabel slider:&_viewmodelYSlider];
    yOffset += 50;
    [self addSectionHeader:@(OBF("View Z")) atY:yOffset]; yOffset += 24;
    [self addSliderAtX:0 y:yOffset width:(visCol2X - 5) title:nil min:-5.0f max:5.0f current:viewmodel_z fmt:@"%.1f" valueChanged:^(float v){ viewmodel_z = v; } valueLabel:&_viewmodelZValueLabel slider:&_viewmodelZSlider];
    yOffset += 50;

    // Right column
    CGFloat y2v = 4;
    _toggleColX = visCol2X; _toggleColWidth = visCol2W;
    [self addSectionHeader:@(OBF("ESP")) atY:y2v];
    y2v += 26;
    _nameOutlineCheckmark = [self addToggle:@(OBF("Name Outline")) atY:y2v action:@selector(nameOutlineTapped) enabled:esp_name_outline];
    y2v += 32;
    _healthCheckmark = [self addToggle:@(OBF("HP")) atY:y2v action:@selector(healthTapped) enabled:esp_health_enabled colorR:&esp_health_r g:&esp_health_g b:&esp_health_b show:YES];
    y2v += 32;
    _healthBarCheckmark = [self addToggle:@(OBF("Health Bar")) atY:y2v action:@selector(healthBarTapped) enabled:esp_health_bar_enabled];
    y2v += 32;
    _healthBarOutlineCheckmark = [self addToggle:@(OBF("Bar Outline")) atY:y2v action:@selector(healthBarOutlineTapped) enabled:esp_health_bar_outline];
    y2v += 32;
    _weaponCheckmark = [self addToggle:@(OBF("Weapon")) atY:y2v action:@selector(weaponTapped) enabled:esp_weapon_enabled colorR:&esp_weapon_r g:&esp_weapon_g b:&esp_weapon_b show:YES];
    y2v += 32;
    _weaponIconCheckmark = [self addToggle:@(OBF("Weapon Icon")) atY:y2v action:@selector(weaponIconTapped) enabled:esp_weapon_icon_enabled];
    y2v += 32;
    _platformCheckmark = [self addToggle:@(OBF("Platform")) atY:y2v action:@selector(platformTapped) enabled:esp_platform_enabled];
    y2v += 32;
    _avatarCheckmark = [self addToggle:@(OBF("Avatar")) atY:y2v action:@selector(avatarTapped) enabled:esp_avatar_enabled];
    y2v += 32;
    _arrowsCheckmark = [self addToggle:@(OBF("Arrows")) atY:y2v action:@selector(arrowsTapped) enabled:esp_arrows_enabled colorR:&esp_arrows_r g:&esp_arrows_g b:&esp_arrows_b show:YES];
    y2v += 32;
    _arrowsOutlineCheckmark = [self addToggle:@(OBF("Arrows Outline")) atY:y2v action:@selector(arrowsOutlineTapped) enabled:esp_arrows_outline];
    y2v += 32;
    [self addSectionHeader:@(OBF("Arrow Margin")) atY:y2v]; y2v += 24;
    [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:20.0f max:500.0f current:esp_arrows_margin fmt:@"%.0f" valueChanged:^(float v){ esp_arrows_margin = v; } valueLabel:&_arrowsMarginValueLabel slider:&_arrowsMarginSlider];
    y2v += 55;
    [self addSectionHeader:@(OBF("Arrow Size")) atY:y2v]; y2v += 24;
    [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:4.0f max:40.0f current:esp_arrows_size fmt:@"%.0f" valueChanged:^(float v){ esp_arrows_size = v; } valueLabel:&_arrowsSizeValueLabel slider:&_arrowsSizeSlider];
    y2v += 55;

    [self addSectionHeader:@(OBF("SKELETON")) atY:y2v]; y2v += 26;
    _skeletonCheckmark = [self addToggle:@(OBF("Skeleton")) atY:y2v action:@selector(skeletonTapped) enabled:esp_skeleton_enabled colorR:&esp_skeleton_r g:&esp_skeleton_g b:&esp_skeleton_b show:YES];
    y2v += 32;
    _skeletonHeadCheckmark = [self addToggle:@(OBF("Skel + Head")) atY:y2v action:@selector(skeletonHeadTapped) enabled:esp_skeleton_head];
    y2v += 32;
    [self addSectionHeader:@(OBF("Skel Width")) atY:y2v]; y2v += 24;
    [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:0.5f max:6.0f current:esp_skeleton_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_skeleton_thickness = v; } valueLabel:&_skelThicknessValueLabel slider:&_skelThicknessSlider];
    y2v += 55;

    [self addSectionHeader:@(OBF("Box 2D Width")) atY:y2v]; y2v += 24;
    [self addSliderAtX:visCol2X y:y2v width:visCol2W title:nil min:0.5f max:6.0f current:esp_box_thickness fmt:@"%.1f" valueChanged:^(float v){ esp_box_thickness = v; } valueLabel:&_boxThicknessValueLabel slider:&_boxThicknessSlider];
    y2v += 55;

    CGFloat visH = MAX(yOffset, y2v) + 10;
    CGRect visualContentFrame = _visualContent.frame;
    visualContentFrame.size.height = visH;
    _visualContent.frame = visualContentFrame;
}

- (void)rainbowTapped {
    esp_rainbow = !esp_rainbow;
    [self animateCheckmark:_rainbowCheckmark show:esp_rainbow];
}

- (void)rainbowMenuTapped {
    g_rainbowMenu = !g_rainbowMenu;
    [self animateCheckmark:_rainbowMenuCheckmark show:g_rainbowMenu];
    if (g_rainbowMenu) {
        _rainbowMenuHue = 0.0f;
        _rainbowMenuTimer = [NSTimer scheduledTimerWithTimeInterval:0.016
                                                            target:self
                                                          selector:@selector(rainbowMenuTick)
                                                          userInfo:nil
                                                           repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_rainbowMenuTimer forMode:NSRunLoopCommonModes];
    } else {
        [_rainbowMenuTimer invalidate];
        _rainbowMenuTimer = nil;
    }
}

- (void)rainbowMenuTick {
    _rainbowMenuHue += 0.004f;
    if (_rainbowMenuHue > 1.0f) _rainbowMenuHue -= 1.0f;
    CGFloat r, g, b;
    [[UIColor colorWithHue:_rainbowMenuHue saturation:0.8 brightness:0.9 alpha:1.0]
        getRed:&r green:&g blue:&b alpha:nil];
    g_menuR = r; g_menuG = g; g_menuB = b;
    [self applyMenuColor];
}

- (void)arrowsTapped {
    esp_arrows_enabled = !esp_arrows_enabled;
    [self animateCheckmark:_arrowsCheckmark show:esp_arrows_enabled];
}

- (void)arrowsOutlineTapped {
    esp_arrows_outline = !esp_arrows_outline;
    [self animateCheckmark:_arrowsOutlineCheckmark show:esp_arrows_outline];
}

- (void)skeletonTapped {
    esp_skeleton_enabled = !esp_skeleton_enabled;
    [self animateCheckmark:_skeletonCheckmark show:esp_skeleton_enabled];
}

- (void)skeletonHeadTapped {
    esp_skeleton_head = !esp_skeleton_head;
    [self animateCheckmark:_skeletonHeadCheckmark show:esp_skeleton_head];
}

- (void)drawPreviewESP:(UIView *)container {
    CGFloat w = container.bounds.size.width;
    CGFloat h = container.bounds.size.height;
    
    // Бокс — вертикальный прямоугольник по центру
    // Отступы: слева 16 (для HP bar), сверху 18 (для name), справа 8, снизу 18 (для weapon)
    CGFloat leftPad  = 16.0f;
    CGFloat rightPad = 8.0f;
    CGFloat topPad   = 18.0f;
    CGFloat botPad   = 18.0f;
    
    CGFloat charX = leftPad;
    CGFloat charY = topPad;
    CGFloat charW = w - leftPad - rightPad;
    CGFloat charH = h - topPad - botPad;
    CGFloat cx = charX + charW / 2.0f;
    
    // Box 2D
    if (esp_box_enabled) {
        UIBezierPath *bp = [UIBezierPath bezierPathWithRect:CGRectMake(charX, charY, charW, charH)];
        if (esp_box_outline) {
            CAShapeLayer *ol = [CAShapeLayer layer]; ol.path = bp.CGPath;
            ol.strokeColor = [UIColor blackColor].CGColor; ol.fillColor = [UIColor clearColor].CGColor;
            ol.lineWidth = esp_box_thickness + 2; [container.layer addSublayer:ol];
        }
        CAShapeLayer *bl = [CAShapeLayer layer]; bl.path = bp.CGPath;
        bl.strokeColor = [UIColor colorWithRed:esp_box_r green:esp_box_g blue:esp_box_b alpha:1].CGColor;
        bl.fillColor = esp_box_fill ? [UIColor colorWithRed:esp_box_r green:esp_box_g blue:esp_box_b alpha:0.15].CGColor : [UIColor clearColor].CGColor;
        bl.lineWidth = esp_box_thickness;
        [container.layer addSublayer:bl];
    }
    
    // Box Corner
    if (esp_box_corner) {
        UIBezierPath *cp = [UIBezierPath bezierPath];
        CGFloat cl = MIN(charW, charH) * 0.15f;
        [cp moveToPoint:CGPointMake(charX + cl, charY)]; [cp addLineToPoint:CGPointMake(charX, charY)]; [cp addLineToPoint:CGPointMake(charX, charY + cl)];
        [cp moveToPoint:CGPointMake(charX + charW - cl, charY)]; [cp addLineToPoint:CGPointMake(charX + charW, charY)]; [cp addLineToPoint:CGPointMake(charX + charW, charY + cl)];
        [cp moveToPoint:CGPointMake(charX, charY + charH - cl)]; [cp addLineToPoint:CGPointMake(charX, charY + charH)]; [cp addLineToPoint:CGPointMake(charX + cl, charY + charH)];
        [cp moveToPoint:CGPointMake(charX + charW, charY + charH - cl)]; [cp addLineToPoint:CGPointMake(charX + charW, charY + charH)]; [cp addLineToPoint:CGPointMake(charX + charW - cl, charY + charH)];
        CAShapeLayer *csl = [CAShapeLayer layer]; csl.path = cp.CGPath;
        csl.strokeColor = [UIColor colorWithRed:esp_box_r green:esp_box_g blue:esp_box_b alpha:1].CGColor;
        csl.fillColor = [UIColor clearColor].CGColor; csl.lineWidth = esp_box_thickness;
        [container.layer addSublayer:csl];
    }
    
    // Name
    if (esp_name_enabled) {
        UILabel *nl = [[UILabel alloc] initWithFrame:CGRectMake(charX, charY - 16, charW, 14)];
        nl.text = @"Player";
        nl.textAlignment = NSTextAlignmentCenter;
        nl.textColor = [UIColor colorWithRed:esp_name_r green:esp_name_g blue:esp_name_b alpha:1];
        nl.font = [UIFont boldSystemFontOfSize:10];
        if (esp_name_outline) {
            nl.layer.shadowColor = [UIColor blackColor].CGColor;
            nl.layer.shadowRadius = 1; nl.layer.shadowOpacity = 1; nl.layer.shadowOffset = CGSizeZero;
        }
        [container addSubview:nl];
    }
    
    // Health Bar (слева от бокса)
    if (esp_health_bar_enabled) {
        CGFloat bx = charX - 8, bw = 4, hp = 0.75f;
        if (esp_health_bar_outline) {
            UIView *ol = [[UIView alloc] initWithFrame:CGRectMake(bx-1, charY-1, bw+2, charH+2)];
            ol.backgroundColor = [UIColor blackColor]; [container addSubview:ol];
        }
        UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(bx, charY, bw, charH)];
        bg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8]; [container addSubview:bg];
        UIView *fill = [[UIView alloc] initWithFrame:CGRectMake(bx, charY + charH * (1 - hp), bw, charH * hp)];
        fill.backgroundColor = [UIColor colorWithRed:0 green:0.9 blue:0.2 alpha:0.9]; [container addSubview:fill];
    }
    
    // Health text
    if (esp_health_enabled) {
        UILabel *hl = [[UILabel alloc] initWithFrame:CGRectMake(charX - 24, charY + charH/2 - 7, 20, 14)];
        hl.text = @"75"; hl.textAlignment = NSTextAlignmentRight;
        hl.textColor = [UIColor colorWithRed:esp_health_r green:esp_health_g blue:esp_health_b alpha:1];
        hl.font = [UIFont boldSystemFontOfSize:9]; [container addSubview:hl];
    }
    
    // Weapon
    if (esp_weapon_enabled) {
        UILabel *wl = [[UILabel alloc] initWithFrame:CGRectMake(charX, charY + charH + 3, charW, 13)];
        wl.text = @"AK-47"; wl.textAlignment = NSTextAlignmentCenter;
        wl.textColor = [UIColor colorWithRed:esp_weapon_r green:esp_weapon_g blue:esp_weapon_b alpha:1];
        wl.font = [UIFont systemFontOfSize:9]; [container addSubview:wl];
    }
    
    // Line
    if (esp_line_enabled) {
        UIBezierPath *lp = [UIBezierPath bezierPath];
        CGFloat endY = (esp_line_mode == 0) ? charY : (esp_line_mode == 1) ? charY + charH/2 : charY + charH;
        [lp moveToPoint:CGPointMake(cx, h - 4)]; [lp addLineToPoint:CGPointMake(cx, endY)];
        if (esp_line_outline) {
            CAShapeLayer *lo = [CAShapeLayer layer]; lo.path = lp.CGPath;
            lo.strokeColor = [UIColor blackColor].CGColor; lo.lineWidth = 3; [container.layer addSublayer:lo];
        }
        CAShapeLayer *ll = [CAShapeLayer layer]; ll.path = lp.CGPath;
        ll.strokeColor = [UIColor colorWithRed:esp_line_r green:esp_line_g blue:esp_line_b alpha:1].CGColor;
        ll.lineWidth = 1.5; [container.layer addSublayer:ll];
    }
    
    // Skeleton — пропорции относительно charH, armSpan ограничен charW
    if (esp_skeleton_enabled) {
        CGFloat headR    = charH * 0.07f;
        CGFloat headCY   = charY + headR + charH * 0.04f;
        CGFloat neckY    = headCY + headR;
        CGFloat shoulderY = neckY + charH * 0.04f;
        CGFloat hipY     = shoulderY + charH * 0.28f;
        CGFloat kneeY    = hipY + charH * 0.20f;
        CGFloat footY    = charY + charH - 4;
        // Руки ограничены шириной бокса
        CGFloat armSpan  = MIN(charW * 0.42f, charH * 0.18f);
        CGFloat legSpan  = charH * 0.10f;
        
        UIBezierPath *sp = [UIBezierPath bezierPath];
        if (esp_skeleton_head) {
            [sp addArcWithCenter:CGPointMake(cx, headCY) radius:headR startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        }
        // Позвоночник
        [sp moveToPoint:CGPointMake(cx, neckY)];
        [sp addLineToPoint:CGPointMake(cx, hipY)];
        // Руки
        [sp moveToPoint:CGPointMake(cx - armSpan, shoulderY)];
        [sp addLineToPoint:CGPointMake(cx + armSpan, shoulderY)];
        // Ноги
        [sp moveToPoint:CGPointMake(cx, hipY)];
        [sp addLineToPoint:CGPointMake(cx - legSpan, kneeY)];
        [sp addLineToPoint:CGPointMake(cx - legSpan * 0.8f, footY)];
        [sp moveToPoint:CGPointMake(cx, hipY)];
        [sp addLineToPoint:CGPointMake(cx + legSpan, kneeY)];
        [sp addLineToPoint:CGPointMake(cx + legSpan * 0.8f, footY)];
        
        CAShapeLayer *sl = [CAShapeLayer layer]; sl.path = sp.CGPath;
        sl.strokeColor = [UIColor colorWithRed:esp_skeleton_r green:esp_skeleton_g blue:esp_skeleton_b alpha:1].CGColor;
        sl.fillColor = [UIColor clearColor].CGColor;
        sl.lineWidth = esp_skeleton_thickness; sl.lineCap = kCALineCapRound; sl.lineJoin = kCALineJoinRound;
        [container.layer addSublayer:sl];
    }
}

- (void)aimbotTeamTapped {
    aimbot_team_check = !aimbot_team_check;
    [self animateCheckmark:_aimbotTeamCheckmark show:aimbot_team_check];
}

- (void)tabTapped:(UITapGestureRecognizer *)gesture {
    NSInteger tag = gesture.view.tag;
    
    // Обновляем визуальное состояние кнопок
    for (UIView *subview in _leftBarView.subviews) {
        if ([subview isKindOfClass:[UIView class]] && subview.tag >= 0 && subview.tag < 4) {
            if (subview.tag == tag) {
                subview.backgroundColor = [UIColor colorWithRed:0.020 green:0.356 blue:0.568 alpha:1.0];
                subview.transform = CGAffineTransformMakeScale(1.1, 1.1);
            } else {
                subview.backgroundColor = [UIColor colorWithRed:0.020 green:0.356 blue:0.568 alpha:0.6];
                subview.transform = CGAffineTransformIdentity;
            }
        }
    }
    
    // Переключаем контейнеры: 0=VISUAL, 1=AIM, 2=PLAYER, 3=OTHER (с CONFIG)
    _visualContainer.hidden = (tag != 0);
    _aimContainer.hidden = (tag != 1);
    _playerContainer.hidden = (tag != 2);
    _otherContainer.hidden = (tag != 3);
    _configContainer.hidden = YES;
    _skinContainer.hidden = YES;
    
    if (tag == 3) {
        [self refreshConfigList];
    }
}

- (void)toggleCollapse {
    _collapsed = !_collapsed;

    CGAffineTransform rot = _collapsed
        ? CGAffineTransformMakeRotation(M_PI)
        : CGAffineTransformIdentity;

    CGFloat headerH = 35.0f;
    CGRect f = self.frame;
    
    if (_collapsed) {
        // Сворачивание: контент сворачивается К полоске (вверх)
        f.size.height = headerH;
        
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.frame = f;
            _arrowLayer.affineTransform = rot;
            
            // Сжимаем контент вертикально к верху (к полоске)
            CGRect contentFrame = _contentView.frame;
            contentFrame.size.height = 0;
            _contentView.frame = contentFrame;
            _contentView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            // Восстанавливаем размер для следующего открытия
            CGRect contentFrame = _contentView.frame;
            contentFrame.size.height = self.frame.size.width * 1.2;
            _contentView.frame = contentFrame;
        }];
        
    } else {
        // Открытие: ВЫЛЕТ из полоски (вниз)
        // Начальное состояние - контент сжат
        CGRect contentFrame = _contentView.frame;
        CGFloat targetHeight = self.frame.size.width * 1.2;
        contentFrame.size.height = 0;
        _contentView.frame = contentFrame;
        _contentView.alpha = 0.0f;
        
        f.size.height = headerH + targetHeight;
        
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.frame = f;
            _arrowLayer.affineTransform = rot;
            
            // Разворачиваем контент вниз из полоски
            CGRect contentFrame = _contentView.frame;
            contentFrame.size.height = targetHeight;
            _contentView.frame = contentFrame;
            _contentView.alpha = 1.0f;
        } completion:nil];
    }
}

- (void)handleScrollPan:(UIPanGestureRecognizer *)g {
    // Don't scroll if touch started inside a ColorPickerView
    if (g.state == UIGestureRecognizerStateBegan) {
        CGPoint pt = [g locationInView:self];
        UIView *hit = [self hitTest:pt withEvent:nil];
        UIView *v = hit;
        while (v) {
            if ([v isKindOfClass:[ColorPickerView class]]) {
                [g setTranslation:CGPointZero inView:_contentView];
                return;
            }
            v = v.superview;
        }
    }

    UIView *target = nil;
    if (!_aimContainer.hidden) target = _aimContent;
    else if (!_visualContainer.hidden) target = _visualContent;
    else if (!_playerContainer.hidden) target = _playerContent;
    else if (!_configContainer.hidden) target = _configContent;
    else if (!_skinContainer.hidden) target = _skinContent;
    else if (!_otherContainer.hidden) target = _otherContent;

    if (!target) return;

    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [g translationInView:_contentView];
        CGRect f = target.frame;
        f.origin.y += translation.y;
        if (f.origin.y > 0) f.origin.y = 0;
        CGFloat minY = _contentView.frame.size.height - f.size.height;
        if (minY > 0) minY = 0;
        if (f.origin.y < minY) f.origin.y = minY;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        target.frame = f;
        [CATransaction commit];
        [g setTranslation:CGPointZero inView:_contentView];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *v = touch.view;
    while (v) {
        if ([v isKindOfClass:[CustomSegmentedControl class]] ||
            [v isKindOfClass:[CustomSliderView class]] ||
            [v isKindOfClass:[ColorPickerView class]]) {
            return NO;
        }
        v = v.superview;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    // Block scroll pan if touch starts inside a ColorPickerView
    if (g == nil) return YES;
    CGPoint pt = [g locationInView:self];
    UIView *hit = [self hitTest:pt withEvent:nil];
    UIView *v = hit;
    while (v) {
        if ([v isKindOfClass:[ColorPickerView class]]) return NO;
        v = v.superview;
    }
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.superview];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _initialTouchPoint = touchPoint;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat deltaX = touchPoint.x - _initialTouchPoint.x;
        CGFloat deltaY = touchPoint.y - _initialTouchPoint.y;
        self.center = CGPointMake(self.center.x + deltaX, self.center.y + deltaY);
        _initialTouchPoint = touchPoint;
        
        // Перемещаем preview window вместе с меню
        if (_previewWindow) {
            _previewWindow.center = CGPointMake(_previewWindow.center.x + deltaX, _previewWindow.center.y + deltaY);
        }
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self centerMenu];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    // Синхронизируем preview window с видимостью меню
    if (hidden) {
        [self hidePreviewWindow];
    } else if (esp_preview_window) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showPreviewWindow];
        });
    }
}

- (void)centerMenu {
    if (self.superview) {
        self.center = CGPointMake(self.superview.bounds.size.width / 2,
                                  self.superview.bounds.size.height / 2);
    }
}

- (void)dealloc {
}

- (void)applyMenuColor {
    UIColor *bg      = [UIColor colorWithRed:g_menuR green:g_menuG blue:g_menuB alpha:0.55];
    UIColor *bgDark  = [UIColor colorWithRed:g_menuR * 0.7 green:g_menuG * 0.7 blue:g_menuB * 0.7 alpha:0.65];
    UIColor *bgLeft  = [UIColor colorWithRed:g_menuR * 0.85 green:g_menuG * 0.85 blue:g_menuB * 0.85 alpha:0.60];

    _headerView.backgroundColor = bgDark;
    _leftBarView.backgroundColor = bgLeft;
    _contentView.backgroundColor = bg;

    for (UIView *c in @[_aimContainer, _visualContainer, _playerContainer,
                        _configContainer, _skinContainer, _otherContainer]) {
        c.backgroundColor = bg;
    }
    for (UIView *c in @[_aimContent, _visualContent, _playerContent,
                        _configContent, _skinContent, _otherContent]) {
        c.backgroundColor = bg;
    }
}

- (void)applyTextColor {
    UIColor *color     = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:1.0];
    UIColor *colorDim  = [UIColor colorWithRed:g_textR green:g_textG blue:g_textB alpha:0.55];

    _headerLabel.textColor = color;

    for (UILabel *lbl in _tabLabels)      lbl.textColor = color;
    for (UILabel *lbl in _toggleLabels)   lbl.textColor = color;
    for (UILabel *lbl in _sectionHeaders) lbl.textColor = colorDim;
}

@end
