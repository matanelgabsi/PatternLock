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

- (void)resetScreen;

@end

@implementation SPLockScreen


- (id)initWithDelegate:(id <LockScreenDelegate>)lockDelegate {
    self = [self init];
    if (self) {
        self.delegate = lockDelegate;
        [self setupView];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
    }
    return self;
}


- (void)setupView {
    [self setDefaults];

    CGFloat gap = (self.frame.size.width - self.padding * 2 - self.radius * 6) / 2;

    for (NSUInteger i          = 0; i < 9; i++) {
        NormalCircle *circle = [[NormalCircle alloc] initwithRadius:self.radius];
        circle.innerColor     = self.innerColor;
        circle.outerColor     = self.outerColor;
        circle.highlightColor = self.highlightColor;
        NSUInteger     column = i % 3;
        NSUInteger     row    = i / 3;
        CGFloat x      = self.padding + self.radius + (gap + 2 * self.radius) * column;
        CGFloat y      = self.padding + self.radius + (gap + 2 * self.radius) * row;
        circle.center = CGPointMake(x, y);
        circle.tag    = (row + kSeed) * kTagIdentifier + (column + kSeed);
        [self addSubview:circle];
    }
    self.drawnLines            = [[NSMutableDictionary alloc] init];
    self.finalLines            = [[NSMutableArray alloc] init];
    self.cellsInOrder          = [[NSMutableArray alloc] init];
    // Add an overlay view
    self.overLay               = [[SPLockOverlay alloc] initWithFrame:self.frame];
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
    if (!self.lineColor) {
        self.lineColor = kLineColor;
    }
    if (!self.lineGridColor) {
        self.lineGridColor = kLineGridColor;
    }
    if (!self.outerColor) {
        self.outerColor = kOuterColor;
    }
    if (!self.innerColor) {
        self.innerColor = kInnerColor;
    }
    if (!self.highlightColor) {
        self.highlightColor = kHighlightColor;
    }
    if (!self.radius) {
        self.radius = 35.0;
    }
    if (!self.padding) {
        self.padding = 20.0;
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

                else if (cell.selected && self.allowClosedPattern) {
                    self.currentCellIndex = [self indexForCell:cell];
                    self.selectedCell     = cell;
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

    if (cellPos >= 0 && cellPos != self.oldCellIndex && [self.cellsInOrder indexOfObject:@(self.currentCellIndex)] == NSNotFound)
        [self.cellsInOrder addObject:@(self.currentCellIndex)];

    if (cellPos < 0 && self.oldCellIndex < 0)
        return;

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
    long     finalNumber = 0;
    long     thisNum;
    for (NSUInteger i           = self.cellsInOrder.count - 1; i >= 0; i--) {
        thisNum     = ([self.cellsInOrder[i] integerValue] + 1) * (long)pow(10, (self.cellsInOrder.count - i - 1));
        finalNumber = finalNumber + thisNum;
    }
    return @(finalNumber);
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
            [self.cellsInOrder addObject:@(self.currentCellIndex)];
            [self performSelector:@selector(endPattern) withObject:nil afterDelay:0.3];
        }
    }
}
@end
