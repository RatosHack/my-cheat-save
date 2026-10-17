//
//  RootViewController.h
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController
@property (nonatomic, strong) UIView *backgroundView;
- (void)reloadMainButtonState;
- (void)startNeonAnimation:(UIView *)container;
- (void)addNeonLine:(UIView *)container;
- (void)btnTouchDown:(UIButton *)sender;
- (void)btnTouchUp:(UIButton *)sender;
- (void)tapExitButton:(UIButton *)sender;
@end