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

@end

@interface SPLockScreen : UIView

@property (nonatomic, strong) id<LockScreenDelegate> delegate;

@property (nonatomic) BOOL allowClosedPattern;			// Set to YES to allow a closed pattern, a complex type pattern; NO by default

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *lineGridColor;

@property (nonatomic, strong) UIColor *outerColor;
@property (nonatomic, strong) UIColor *innerColor;
@property (nonatomic, strong) UIColor *highlightColor;

// Init Method

- (id)initWithDelegate:(id<LockScreenDelegate>)lockDelegate;
@end
