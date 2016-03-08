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

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (id)initWithRadius:(CGFloat)radius {
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
    CGFloat lineWidth  = 3.0;
    CGSize unselectedInnerSize = CGSizeMake(self.unselectedCircleSize.width - 2 * lineWidth, self.unselectedCircleSize.height - 2 * lineWidth);
    CGRect rectToDraw = CGRectMake(rect.origin.x + rect.size.width/2 - unselectedInnerSize.width/2, rect.origin.y + rect.size.height/2 - unselectedInnerSize.height/2, unselectedInnerSize.width, unselectedInnerSize.height);
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, self.outerColor.CGColor);
    CGContextStrokeEllipseInRect(context, rectToDraw);

    // Fill inner part
    CGRect innerRect = CGRectInset(rectToDraw, 1, 1);
    CGContextSetFillColorWithColor(context, self.innerColor.CGColor);
    CGContextFillEllipseInRect(context, innerRect);

    if (!self.selected)
        return;

    // For selected View
    CGRect selectedRect = CGRectMake(rect.origin.x + rect.size.width/2 - self.selectedCircleSize.width/2, rect.origin.y + rect.size.height/2 - self.selectedCircleSize.height/2, self.selectedCircleSize.width, self.selectedCircleSize.height);
    CGContextSetStrokeColorWithColor(context, self.highlightColor.CGColor);
    CGContextStrokeEllipseInRect(context, selectedRect);
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
