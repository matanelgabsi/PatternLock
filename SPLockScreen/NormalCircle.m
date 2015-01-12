//
//  NormalCircle.m
//  SuQian
//
//  Created by Suraj on 24/9/12.
//  Copyright (c) 2012 Suraj. All rights reserved.
//

#import "NormalCircle.h"
#import <QuartzCore/QuartzCore.h>

@implementation NormalCircle
@synthesize selected, cacheContext;
@synthesize outerColor, innerColor, highlightColor;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (id)initwithRadius:(CGFloat)radius {
    CGRect       frame   = CGRectMake(0, 0, 2 * radius, 2 * radius);
    NormalCircle *circle = [self initWithFrame:frame];
    if (circle) {
        [circle setBackgroundColor:[UIColor clearColor]];
    }
    return circle;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    self.cacheContext = context;
    CGFloat lineWidth  = 5.0;
    CGRect  rectToDraw = CGRectMake(rect.origin.x + lineWidth, rect.origin.y + lineWidth, rect.size.width - 2 * lineWidth, rect.size.height - 2 * lineWidth);
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, outerColor.CGColor);
    CGContextStrokeEllipseInRect(context, rectToDraw);

    // Fill inner part
    CGRect innerRect = CGRectInset(rectToDraw, 1, 1);
    CGContextSetFillColorWithColor(context, innerColor.CGColor);
    CGContextFillEllipseInRect(context, innerRect);

    if (self.selected == NO)
        return;

    // For selected View
    CGRect smallerRect = CGRectInset(rectToDraw, 10, 10);
    CGContextSetFillColorWithColor(context, highlightColor.CGColor);
    CGContextFillEllipseInRect(context, smallerRect);
}

- (void)highlightCell {
    self.selected = YES;
    [self setNeedsDisplay];
}

- (void)resetCell {
    self.selected = NO;
    [self setNeedsDisplay];
}


@end
