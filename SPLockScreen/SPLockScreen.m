//
//  SPLockScreen.m
//  SuQian
//
//  Created by Suraj on 24/9/12.
//  Copyright (c) 2012 Suraj. All rights reserved.
//

#import "SPLockScreen.h"
#import "NormalCircle.h"
#import "SPLockOverlay.h"

#define kSeed                         23
#define kAlterOne                     1234
#define kAlterTwo                     4321
#define kTagIdentifier                22222


#define kOuterColor     [UIColor colorWithRed:94.0/255.0 green:132.0/255.0 blue:170.0/255.0 alpha:1]
#define kInnerColor     [UIColor colorWithRed:59.0/255.0 green:83.0/255.0 blue:107.0/255.0 alpha:1]
#define kHighlightColor [UIColor colorWithRed:52.0/255.0 green:152.0/255.0 blue:219.0/255.0 alpha:1]

#define kLineColor      [UIColor colorWithRed:86.0/255.0 green:187.0/255.0 blue:255.0/232.0 alpha:1]
#define kLineGridColor  [UIColor colorWithRed:86.0/255.0 green:187.0/255.0 blue:255.0/232.0 alpha:1]


@interface SPLockScreen ()
@property (nonatomic, strong) NormalCircle        *selectedCell;
@property (nonatomic, strong) SPLockOverlay       *overLay;
@property (nonatomic) NSInteger                   oldCellIndex, currentCellIndex;
@property (nonatomic, strong) NSMutableDictionary *drawnLines;
@property (nonatomic, strong) NSMutableArray      *finalLines, *cellsInOrder;

@property (nonatomic) BOOL allowClosedPattern;            // Set to YES to allow a closed pattern, a complex type pattern; NO by default

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *lineGridColor;

@property (nonatomic, strong) UIColor *outerColor;
@property (nonatomic, strong) UIColor *innerColor;
@property (nonatomic, strong) UIColor *highlightColor;

@property (nonatomic) CGFloat padding;
@property (nonatomic) CGFloat radius;

- (void)resetScreen;

@end

@implementation SPLockScreen


- (id)initWithDelegate:(id <LockScreenDelegate>)lockDelegate {
    self = [self init];
    if (self) {
        self.delegate = lockDelegate;
    }

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [self setDefaults];
    [self setupView];
}

- (void)setupView {
    CGFloat gap = (self.frame.size.width - self.padding * 2 - self.radius * 6) / 2;

    for (NSUInteger i          = 0; i < 9; i++) {
        NormalCircle *circle = [[NormalCircle alloc] initWithRadius:self.radius];
        circle.innerColor     = self.innerColor;
        circle.outerColor     = self.outerColor;
        circle.highlightColor = self.highlightColor;
        NSUInteger column = i % 3;
        NSUInteger row    = i / 3;
        CGFloat    x      = self.padding + self.radius + (gap + 2 * self.radius) * column;
        CGFloat    y      = self.padding + self.radius + (gap + 2 * self.radius) * row;
        circle.center = CGPointMake(x, y);
        circle.tag    = (row + kSeed) * kTagIdentifier + (column + kSeed);
        [self addSubview:circle];
    }
    self.drawnLines            = [[NSMutableDictionary alloc] init];
    self.finalLines            = [[NSMutableArray alloc] init];
    self.cellsInOrder          = [[NSMutableArray alloc] init];
    // Add an overlay view
    self.overLay               = [[SPLockOverlay alloc] initWithFrame:self.bounds];
    self.overLay.lineColor     = self.lineColor;
    self.overLay.lineGridColor = self.lineGridColor;
    [self.overLay setUserInteractionEnabled:NO];
    [self addSubview:self.overLay];
    // set selected cell indexes to be invalid
    self.currentCellIndex = -1;
    self.oldCellIndex     = self.currentCellIndex;

    [self setNeedsDisplay];
    [self addGestureRecognizer];
}

- (void)setDefaults {
    self.lineColor      = kLineColor;
    self.lineGridColor  = kLineGridColor;
    self.outerColor     = kOuterColor;
    self.innerColor     = kInnerColor;
    self.highlightColor = kHighlightColor;
    self.radius         = 35.0;
    self.padding        = 20.0;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(lineColor)]) {
            self.lineColor = self.delegate.lineColor;
        }
        if ([self.delegate respondsToSelector:@selector(lineGridColor)]) {
            self.lineGridColor = self.delegate.lineGridColor;
        }
        if ([self.delegate respondsToSelector:@selector(outerColor)]) {
            self.outerColor = self.delegate.outerColor;
        }
        if ([self.delegate respondsToSelector:@selector(innerColor)]) {
            self.innerColor = self.delegate.innerColor;
        }
        if ([self.delegate respondsToSelector:@selector(highlightColor)]) {
            self.highlightColor = self.delegate.highlightColor;
        }
        if ([self.delegate respondsToSelector:@selector(radius)]) {
            self.radius = self.delegate.radius;
        }
        if ([self.delegate respondsToSelector:@selector(padding)]) {
            self.padding = self.delegate.padding;
        }
    }

    self.backgroundColor = [UIColor clearColor];
}

#pragma - helper methods

- (NSInteger)indexForPoint:(CGPoint)point {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[NormalCircle class]]) {
            if (CGRectContainsPoint(view.frame, point)) {
                NormalCircle *cell = (NormalCircle *)view;

                if (!cell.selected) {
                    [cell highlightCell];
                    self.currentCellIndex = [self indexForCell:cell];
                    self.selectedCell     = cell;
                }

                else if (cell.selected) {
                    if ([self.delegate respondsToSelector:@selector(allowClosedPattern)]) {
                        if (self.delegate.allowClosedPattern) {
                            self.currentCellIndex = [self indexForCell:cell];
                            self.selectedCell     = cell;
                        }
                    }
                }

                NSInteger row    = view.tag / kTagIdentifier - kSeed;
                NSInteger column = view.tag % kTagIdentifier - kSeed;
                return row * 3 + column;
            }
        }
    }
    return -1;
}

- (NSInteger)indexForCell:(NormalCircle *)cell {
    if (![cell isKindOfClass:[NormalCircle class]] || ![cell.superview isEqual:self])
        return -1;
    else
        return (cell.tag / kTagIdentifier - kSeed) * 3 + (cell.tag % kTagIdentifier - kSeed);
}

- (NormalCircle *)cellAtIndex:(NSInteger)index {
    if (index < 0 || index > 8)
        return nil;
    return (NormalCircle *)[self viewWithTag:((index / 3 + kSeed) * kTagIdentifier + index % 3 + kSeed)];
}

- (NSNumber *)uniqueLineIdForLineJoiningPoint:(NSInteger)A AndPoint:(NSInteger)B {
    return @(abs(A + B) * kAlterOne + abs(A - B) * kAlterTwo);
}

- (void)handlePanAtPoint:(CGPoint)point {
    self.oldCellIndex = self.currentCellIndex;
    NSInteger cellPos = [self indexForPoint:point];

    if (cellPos >= 0 && cellPos != self.oldCellIndex && [self.cellsInOrder indexOfObject:@(self.currentCellIndex)] == NSNotFound) {
        [self.cellsInOrder addObject:@(self.currentCellIndex)];
    }

    if (cellPos < 0 && self.oldCellIndex < 0) {
        return;
    }

    else if (cellPos < 0) {
        SPLine *aLine = [[SPLine alloc] initWithFromPoint:[self cellAtIndex:self.oldCellIndex].center
                                                  toPoint:point
                                          AndIsFullLength:NO];
        [self.overLay.pointsToDraw removeAllObjects];
        [self.overLay.pointsToDraw addObjectsFromArray:self.finalLines];
        [self.overLay.pointsToDraw addObject:aLine];
        [self.overLay setNeedsDisplay];
    }
    else if (cellPos >= 0 && self.currentCellIndex == self.oldCellIndex) {
        return;
    }
    else if (cellPos >= 0 && self.oldCellIndex == -1) {
        return;
    }
    else if (cellPos >= 0 && self.oldCellIndex != self.currentCellIndex) {
        // two situations: line already drawn, or not fully drawn yet
        NSNumber *uniqueId = [self uniqueLineIdForLineJoiningPoint:self.oldCellIndex AndPoint:self.currentCellIndex];

        if (!(self.drawnLines)[uniqueId]) {
            SPLine *aLine = [[SPLine alloc] initWithFromPoint:[self cellAtIndex:self.oldCellIndex].center
                                                      toPoint:self.selectedCell.center
                                              AndIsFullLength:YES];
            [self.finalLines addObject:aLine];
            [self.overLay.pointsToDraw removeAllObjects];
            [self.overLay.pointsToDraw addObjectsFromArray:self.finalLines];
            [self.overLay setNeedsDisplay];
            self.drawnLines[uniqueId] = @(YES);
        }
        else {
            return;
        }
    }
}

- (void)endPattern {
    NSLog(@"PATTERN: %@", [self patternToUniqueId]);
    if ([self.delegate respondsToSelector:@selector(lockScreen:didEndWithPattern:)]) {
        [self.delegate lockScreen:self didEndWithPattern:[self patternToUniqueId]];
    }

    [self resetScreen];
}

- (NSNumber *)patternToUniqueId {
    NSMutableString *numberString = [NSMutableString new];

    for (NSInteger i = self.cellsInOrder.count; i > 0; i--) {
        NSNumber *thisNumber = self.cellsInOrder[(NSUInteger)(i - 1)];
        [numberString appendString:thisNumber.stringValue];
    }
    return @(numberString.integerValue);
}

- (void)resetScreen {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[NormalCircle class]]) {
            [(NormalCircle *)view resetCell];
        }
    }
    [self.finalLines removeAllObjects];
    [self.drawnLines removeAllObjects];
    [self.cellsInOrder removeAllObjects];
    [self.overLay.pointsToDraw removeAllObjects];
    [self.overLay setNeedsDisplay];
    self.oldCellIndex     = -1;
    self.currentCellIndex = -1;
    self.selectedCell     = nil;
}


#pragma - Gesture Handler

- (void)addGestureRecognizer {
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestured:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestured:)];
    [self addGestureRecognizer:pan];
    [self addGestureRecognizer:tap];
}

- (void)gestured:(UIGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        if (gesture.state == UIGestureRecognizerStateEnded) {
            if (self.finalLines.count > 0) {
                [self endPattern];
            }
            else {
                [self resetScreen];
            }
        }
        else {
            [self handlePanAtPoint:point];
        }
    }
    else {
        NSInteger cellPos = [self indexForPoint:point];
        self.oldCellIndex = self.currentCellIndex;
        if (cellPos >= 0) {
            [self.cellsInOrder addObject:@(self.currentCellIndex + 1)];
            [self performSelector:@selector(endPattern) withObject:nil afterDelay:0.3];
        }
    }
}
@end
