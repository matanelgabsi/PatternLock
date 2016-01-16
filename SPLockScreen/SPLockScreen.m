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
@property (nonatomic, strong) SPLockOverlay       *overLay;
@property (nonatomic) NSInteger                   oldCellIndex;
@property (nonatomic, strong) NSMutableDictionary *drawnLines;
@property (nonatomic, strong) NSMutableArray      *finalLines, *cellsInOrder;
@property (nonatomic, strong) NSMutableArray      *circles;
@property (nonatomic, assign) BOOL                initWasDone;

@property (nonatomic) BOOL allowClosedPattern;            // Set to YES to allow a closed pattern, a complex type pattern; NO by default

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *lineGridColor;

@property (nonatomic, strong) UIColor *outerColor;
@property (nonatomic, strong) UIColor *innerColor;
@property (nonatomic, strong) UIColor *highlightColor;

@property (nonatomic) CGFloat paddingX;
@property (nonatomic) CGFloat paddingY;
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
    [self initialSetup];
    [self setDefaults];
    [self setupView];
}

-(void)setBounds:(CGRect)newBounds {
    [super setBounds:newBounds];
    [self.overLay setFrame:self.bounds];
    [self initialSetup];
    [self setDefaults];
    [self setupView];
}

- (void) initialSetup {
    if (self.initWasDone) {
        return;
    }
    self.circles = [NSMutableArray new];
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
    self.oldCellIndex     = -1;
    
    [self addGestureRecognizer];
    self.initWasDone = YES;
}

- (void)setupView {
    for (UIView *circle in self.circles) {
        [circle removeFromSuperview];
    }
    [self.circles removeAllObjects];
    CGFloat gapX = (self.frame.size.width - self.paddingX * 2 - self.radius * 6) / 2;
    CGFloat gapY = (self.frame.size.height - self.paddingY * 2 - self.radius * 6) / 2;

    for (NSUInteger i          = 0; i < 9; i++) {
        NormalCircle *circle = [[NormalCircle alloc] initWithRadius:self.radius];
        circle.innerColor     = self.innerColor;
        circle.outerColor     = self.outerColor;
        circle.highlightColor = self.highlightColor;
        NSUInteger column = i % 3;
        NSUInteger row    = i / 3;
        CGFloat    x      = self.paddingX + self.radius + (gapX + 2 * self.radius) * column;
        CGFloat    y      = self.paddingY + self.radius + (gapY + 2 * self.radius) * row;
        circle.center = CGPointMake(x, y);
        circle.tag    = (row + kSeed) * kTagIdentifier + (column + kSeed);
        [self addSubview:circle];
        [self.circles addObject:circle];
    }
    
    [self setNeedsDisplay];
}

- (void)setDefaults {
    self.lineColor      = kLineColor;
    self.lineGridColor  = kLineGridColor;
    self.outerColor     = kOuterColor;
    self.innerColor     = kInnerColor;
    self.highlightColor = kHighlightColor;
    self.radius         = 35.0;
    self.paddingX        = 20.0;
    self.paddingY        = 20.0;

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
        if ([self.delegate respondsToSelector:@selector(paddingX)]) {
            self.paddingX = self.delegate.paddingX;
        }
        if ([self.delegate respondsToSelector:@selector(paddingY)]) {
            self.paddingY = self.delegate.paddingY;
        }
    }

    self.backgroundColor = [UIColor clearColor];
}

#pragma - helper methods

- (NSInteger)indexForPoint:(CGPoint)point {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[NormalCircle class]]) {
            if (CGRectContainsPoint(view.frame, point)) {
                return [self indexForCell: view];
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
    NSInteger cellPos = [self indexForPoint:point];

    if (cellPos >= 0 && cellPos != self.oldCellIndex && [self.cellsInOrder indexOfObject:@(cellPos)] == NSNotFound) {
        NSLog(@"Added point %d", cellPos);
        if (self.oldCellIndex != -1) {
            SPLine *aLine = [[SPLine alloc] initWithFromPoint:[self cellAtIndex:self.oldCellIndex].center
                                                  toPoint:[self cellAtIndex:cellPos].center
                                          AndIsFullLength:YES];
            [self.finalLines addObject:aLine];
        }
        
        [self.cellsInOrder addObject:@(cellPos)];
        self.oldCellIndex = cellPos;
        [[self cellAtIndex:cellPos] highlightCell];
    }
    if (self.oldCellIndex != -1) {
        SPLine *aLine = [[SPLine alloc] initWithFromPoint:[self cellAtIndex:self.oldCellIndex].center
                                                  toPoint:point
                                          AndIsFullLength:NO];
        [self.overLay.pointsToDraw removeAllObjects];
        [self.overLay.pointsToDraw addObjectsFromArray:self.finalLines];
        [self.overLay.pointsToDraw addObject:aLine];
        [self.overLay setNeedsDisplay];
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
    NSUInteger finalNumber = 0;

    for (NSInteger i = 0; i < self.cellsInOrder.count; i++) {
        NSUInteger thisNumber = [self.cellsInOrder[(NSUInteger)i] unsignedLongValue] + 1;
        finalNumber = finalNumber * 10 + thisNumber;
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
        if (cellPos >= 0) {
            [self.cellsInOrder addObject:@(cellPos)];
            [self performSelector:@selector(endPattern) withObject:nil afterDelay:0.3];
        }
    }
}
@end
