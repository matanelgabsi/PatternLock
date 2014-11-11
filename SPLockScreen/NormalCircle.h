//
//  NormalCircle.h
//  SuQian
//
//  Created by Suraj on 24/9/12.
//  Copyright (c) 2012 Suraj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NormalCircle : UIView

@property (nonatomic) BOOL selected;
@property (nonatomic) CGContextRef cacheContext;

@property (nonatomic, strong) UIColor *outerColor;
@property (nonatomic, strong) UIColor *innerColor;
@property (nonatomic, strong) UIColor *highlightColor;

- (id)initwithRadius:(CGFloat)radius;

- (void)highlightCell;
- (void)resetCell;

@end
