//
//  RMAction.m
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMAction+Private.h"

#import "RMActionController+Private.h"
#import "NSProcessInfo+RMActionController.h"

@interface RMAction ()

@property (nonatomic, strong, readwrite) UIView *view;

@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) UIImage *image;

@property (nonatomic, strong) UIButton *button;

@end

@implementation RMAction

#pragma mark - Class

+ (instancetype)actionWithTitle:(NSString *)title style:(RMActionStyle)style customFont:(nullable UIFont *)customFont andHandler:(void (^)(RMActionController<UIView *> * _Nonnull))handler {
    RMAction *action = [[self class] actionWithStyle:style customFont:customFont andHandler:handler];
    action.title = title;
    
    return action;
}

+ (instancetype)actionWithImage:(UIImage *)image style:(RMActionStyle)style customFont:(nullable UIFont *)customFont andHandler:(void (^)(RMActionController<UIView *> * _Nonnull controller))handler {
    RMAction *action = [[self class] actionWithStyle:style customFont:customFont andHandler:handler];
    action.image = image;
    
    return action;
}

+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image style:(RMActionStyle)style customFont:(nullable UIFont *)customFont andHandler:(void (^)(RMActionController<UIView *> * _Nonnull controller))handler {
    RMAction *action = [[self class] actionWithStyle:style customFont:customFont andHandler:handler];
    action.title = title;
    action.image = image;
    
    return action;
}

+ (instancetype)actionWithStyle:(RMActionStyle)style customFont:(nullable UIFont *)customFont andHandler:(void (^)(RMActionController<UIView *> *controller))handler {
    RMAction *action = [[self class] new];
    action.style = style;
    action.customFont = customFont;
    
    __weak RMAction *weakAction = action;
    [action setHandler:^(RMActionController *controller) {
        if(handler) {
            handler(controller);
        }
        
        if(weakAction.dismissesActionController && controller.presentingViewController != nil) {
            if(controller.modalPresentationStyle == UIModalPresentationPopover || controller.yConstraint != nil) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            } else {
                [controller dismissViewControllerAnimated:NO completion:nil];
            }
        }
    }];
    
    return action;
}

#pragma mark - Init and Dealloc

- (instancetype)init {
    self = [super init];
    if(self) {
        self.dismissesActionController = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryChanged) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Cancel Helper

- (BOOL)containsCancelAction {
    return self.style == RMActionStyleCancel;
}

- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller {
    if (self.style == RMActionStyleCancel) {
        self.handler(controller);
    }
}

#pragma mark - Other Helper

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)updateFont {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCallout];
    if (self.style == RMActionStyleCancel) {
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    }
    self.button.titleLabel.font = [UIFont fontWithDescriptor:descriptor size:descriptor.pointSize];
    
    if (self.customFont) {
        self.button.titleLabel.font = self.customFont;
    }
}

#pragma mark - View

- (UIView *)view {
    if(!_view) {
        _view = [self loadView];
        _view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self updateFont];
    }
    
    return _view;
}

- (UIView *)loadView {
    UIButtonType buttonType = UIButtonTypeCustom;
    if (self.controller.disableBlurEffectsForActions) {
        buttonType = UIButtonTypeSystem;
    }
    
    UIButton *actionButton = [UIButton buttonWithType:buttonType];
    [actionButton addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
    [actionButton setBackgroundImage:[self imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0]] forState:UIControlStateNormal];
    
    if (!self.controller.disableBlurEffectsForActions) {
        [actionButton setBackgroundImage:[self imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3]] forState:UIControlStateHighlighted];
    } else {
        switch (self.controller.style) {
            case RMActionControllerStyleWhite:
            case RMActionControllerStyleSheetWhite:
            case RMActionControllerStyleAdaptive:
            case RMActionControllerStyleSheetAdaptive:
                [actionButton setBackgroundImage:[self imageWithColor:[UIColor colorWithWhite:0.2 alpha:1]] forState:UIControlStateHighlighted];
                break;
            case RMActionControllerStyleBlack:
            case RMActionControllerStyleSheetBlack:
                [actionButton setBackgroundImage:[self imageWithColor:[UIColor colorWithWhite:0.8 alpha:1]] forState:UIControlStateHighlighted];
                break;
        }
    }
    
    if (self.title) {
        [actionButton setTitle:self.title forState:UIControlStateNormal];
    } else if (self.image) {
        [actionButton setImage:self.image forState:UIControlStateNormal];
    }
    
    [actionButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionButton(>=minHeight)]" options:0 metrics:@{@"minHeight": @([NSProcessInfo runningAtLeastiOS9] ? 55 : 44)} views:NSDictionaryOfVariableBindings(actionButton)]];
    
    if (self.style == RMActionStyleDestructive) {
        [actionButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    
    self.button = actionButton;
    return actionButton;
}

- (void)actionTapped:(id)sender {
    self.handler(self.controller);
}

#pragma mark - Notifications

- (void)contentSizeCategoryChanged {
    [self updateFont];
}

@end
