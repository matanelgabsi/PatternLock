//
//  SPLockScreen.h
//  SuQian
//
//  Created by Suraj on 24/9/12.
//  Copyright (c) 2012 Suraj. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPLockScreen;

@protocol LockScreenDelegate <NSObject>

- (void)lockScreen:(SPLockScreen *)lockScreen didEndWithPattern:(NSNumber *)patternNumber;

@optional

@property (nonatomic) BOOL allowClosedPattern;            // Set to YES to allow a closed pattern, a complex type pattern; NO by default

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *lineGridColor;

@property (nonatomic, strong) UIColor *outerColor;
@property (nonatomic, strong) UIColor *innerColor;
@property (nonatomic, strong) UIColor *highlightColor;

@property (nonatomic) CGFloat paddingX;
@property (nonatomic) CGFloat paddingY;
@property (nonatomic) CGFloat radius;

@end

@interface SPLockScreen : UIView

@property (nonatomic, weak) id <LockScreenDelegate> delegate;

// Init Method

- (id)initWithDelegate:(id <LockScreenDelegate>)lockDelegate;
- (void)resetScreen;

@end
