//
//  RDYSegmentedControl.m
//  Read
//
//  Created by 虞冠群 on 2016/11/12.
//  Copyright © 2016年 Yu Guanqun. All rights reserved.
//

#import "UUSegment.h"
#import "UULabel.h"
#import "UUImageView.h"
#import "UUImageTextView.h"
#import "UUIndicatorView.h"

typedef NS_ENUM(NSUInteger, UUSegmentContentType) {
    UUSegmentContentTypeTitle,
    UUSegmentContentTypeImage,
    UUSegmentContentTypeMixture,
};

@interface UUSegment ()

///-----------------
/// @name Appearence
///-----------------



///---------------------
/// @name Managing Views
///---------------------

@property (nonatomic, strong) UIView                                *containerView;
@property (nonatomic, strong) UIView                                *selectedContainerView;
@property (nonatomic, strong) UIScrollView                          *scrollView;
@property (nonatomic, strong) UUIndicatorView                       *indicatorView;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *leadingConstraints;

///------------------------
/// @name Managing Segments
///------------------------

@property (nonatomic, assign) UUSegmentContentType              contentType;
@property (nonatomic, assign) NSUInteger                        segments;
@property (nonatomic, strong) NSMutableArray <NSString *>       *titles;
@property (nonatomic, strong) NSMutableArray <UIImage *>        *images;

///---------------------------------
/// @name Managing Indicator Gesture
///---------------------------------

@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;
@property (nonatomic, assign) CGFloat                panCorrection;

///--------------------
/// @name Mapping Table
///--------------------

@property (nonatomic, strong) NSMutableArray <UULabel *>         *labelTable;
@property (nonatomic, strong) NSMutableArray <UUImageView *>     *imageViewTable;
@property (nonatomic, strong) NSMutableArray <UULabel *>         *selectedLabelTable;
@property (nonatomic, strong) NSMutableArray <UUImageView *>     *selectedImageViewTable;

//@property (nonatomic, assign, getter = isDataSourceNil) BOOL dataSourceNil;

@end

@implementation UUSegment

@dynamic font;
@dynamic selectedFont;

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithTitles:nil];
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles {
    NSAssert((titles && [titles count]), @"Titles can not be empty. If you are using `-initWithFrame:`, please use `-initWithTitles:`, `-initWithImages:`, `-initWithTitles:forImages:` instead.");
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _titles = [titles mutableCopy];
        _segments = [titles count];
        _contentType = UUSegmentContentTypeTitle;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithImages:(NSArray <UIImage *> *)images {
    NSAssert((images && [images count]), @"Images can not be empty.");
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _images = [images mutableCopy];
        _segments = [images count];
        _contentType = UUSegmentContentTypeImage;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles forImages:(NSArray <UIImage *> *)images {
    NSAssert((titles && [titles count] && images && [images count]), @"Titles and images can not be empty.");
    NSAssert(([titles count] == [images count]), @"The count of titles should be equal to the count of images.");
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _titles = [titles mutableCopy];
        _images = [images mutableCopy];
        _segments = [titles count];
        _contentType = UUSegmentContentTypeMixture;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _currentIndex = 0;
    // Setup UI
//    _style = UUSegmentStyleSlider;
    _style = UUSegmentStyleRounded;
    [self setupContainerView];
    [self setupSegmentViewsSelected:NO];
    [self setupSelectedContainerView];
    [self setupSegmentViewsSelected:YES];
    [self buildUIWithStyle:_style];
    // Add gesture
    [self addGesture];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSLog(@"Segment layoutSubviews");
    
    self.indicatorView.frame = (CGRect){[self segmentWidth] * _currentIndex, 0, [self segmentWidth], CGRectGetHeight(self.frame)};
    
//    CGRect containerViewFrame = _containerView.frame;
//    CGFloat scrollViewWidth = CGRectGetWidth(_scrollView.frame);
//    if (CGRectGetWidth(containerViewFrame) < scrollViewWidth) {
//        NSLog(@"containerView.width < scrollView.width");
//        containerViewFrame.size.width = scrollViewWidth;
//        _containerView.frame = containerViewFrame;
//    }
}

#pragma mark - Items Setting

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Index should in the range of 0...%lu", _segments - 1);
    [self update:title forTitlesAtIndex:index];
    [self updateTitle:title forSegmentViewAtIndex:index];
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Index should in the range of 0...%lu", _segments - 1);
    [self update:image forImagesAtIndex:index];
    [self updateImage:image forSegmentViewAtIndex:index];
}

- (void)setTitle:(NSString *)title forImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Index should in the range of 0...%lu", _segments - 1);
    [self update:title forImage:image forTitlesAndImagesAtIndex:index];
    [self updateTitle:title forImage:image forSegmentViewAtIndex:index];
}

- (void)update:(NSString *)title forTitlesAtIndex:(NSUInteger)index {
    self.titles[index] = title;
}

- (void)update:(UIImage *)image forImagesAtIndex:(NSUInteger)index {
    self.images[index] = image;
}

- (void)update:(NSString *)title forImage:(UIImage *)image forTitlesAndImagesAtIndex:(NSUInteger)index {
    self.titles[index] = title;
    self.images[index] = image;
}

- (void)updateTitle:(NSString *)title forSegmentViewAtIndex:(NSUInteger)index {
    UULabel *label = _labelTable[index];
    label.text = title;
}

- (void)updateImage:(UIImage *)image forSegmentViewAtIndex:(NSUInteger)index {
    UUImageView *imageView = _imageViewTable[index];
    imageView.image = image;
}

- (void)updateTitle:(NSString *)title forImage:(UIImage *)image forSegmentViewAtIndex:(NSUInteger)index {
    UULabel *label = _labelTable[index];
    label.text = title;
    UUImageView *imageView = _imageViewTable[index];
    imageView.image = image;
}

#pragma mark - Items Getting

- (NSString *)titleForSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Index should in the range of 0...%lu", _segments - 1);
    return _titles[index];
}

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Index should in the range of 0...%lu", _segments - 1);
    return _images[index];
}

- (NSDictionary *)titleAndImageForSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Index should in the range of 0...%lu", _segments - 1);
    NSDictionary *dic = @{@"title" : _titles[index], @"image" : _images[index]};
    return dic;
}

#pragma mark - Items Insert

- (void)addSegmentWithTitle:(NSString *)title {
    [self insertSegmentWithTitle:title atIndex:_segments];
}

- (void)addSegmentWithImage:(UIImage *)image {
    [self insertSegmentWithImage:image atIndex:_segments];
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)index {
    NSAssert1(index <= _segments, @"Index should in the range of 0...%lu", _segments);
    
    [self.titles insertObject:title atIndex:index];
    self.segments++;
}

- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)index {
    NSAssert1(index <= _segments, @"Index should in the range of 0...%lu", _segments);
    
    [self.images insertObject:image atIndex:index];
    self.segments++;
}

- (void)insertSegment:(UIView *)segmentView atIndex:(NSUInteger)index {
    [self updateConstraintsWithInsertSegmentView:segmentView atIndex:index];
}

#pragma mark - Items Delete

- (void)removeAllItems {
    
}

- (void)removeLastItem {
    [self removeItemAtIndex:_segments - 1];
}

- (void)removeItemAtIndex:(NSUInteger)index {
    NSAssert1(index < _segments, @"Parameter index should in the range of 0...%lu", _segments - 1);
}

#pragma mark - Views Setup

- (void)setupSegmentViewsSelected:(BOOL)selected {
    switch (_contentType) {
        case UUSegmentContentTypeTitle: {
            for (NSString *title in _titles) {
                [self setupSegmentViewWithTitle:title selected:selected];
            }
            if (selected) {
                [self setupConstraintsWithSegments:_selectedLabelTable toContainerView:_selectedContainerView];
            } else {
                [self setupConstraintsWithSegments:_labelTable toContainerView:_containerView];
            }
            break;
        }
        case UUSegmentContentTypeImage: {
            for (UIImage *image in _images) {
                [self setupSegmentViewWithImage:image selected:selected];
            }
            if (selected) {
                [self setupConstraintsWithSegments:_selectedImageViewTable toContainerView:_selectedContainerView];
            } else {
                [self setupConstraintsWithSegments:_imageViewTable toContainerView:_containerView];
            }
            break;
        }
        case UUSegmentContentTypeMixture: {
            NSMutableArray *imageTextViews = [NSMutableArray array];
            for (int i = 0; i < _segments; i++) {
                [imageTextViews addObject:[self setupSegmentViewWithTitle:_titles[i] forImage:_images[i] selected:selected]];
            }
            if (selected) {
                [self setupConstraintsWithSegments:imageTextViews toContainerView:_selectedContainerView];
            } else {
                [self setupConstraintsWithSegments:imageTextViews toContainerView:_containerView];
            }
            break;
        }
    }
}

- (void)setupSegmentViewWithTitle:(NSString *)title selected:(BOOL)selected {
    UULabel *label = [[UULabel alloc] initWithText:title selected:selected];
    if (selected) {
        [_selectedContainerView addSubview:label];
        [self.selectedLabelTable addObject:label];
    }
    else {
        [_containerView addSubview:label];
        [self.labelTable addObject:label];
    }
    label.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setupSegmentViewWithImage:(UIImage *)image selected:(BOOL)selected {
    UUImageView *imageView = [[UUImageView alloc] initWithImage:image];
    if (selected) {
        [_selectedContainerView addSubview:imageView];
        [self.selectedImageViewTable addObject:imageView];
    }
    else {
        [_containerView addSubview:imageView];
        [self.imageViewTable addObject:imageView];
    }
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (UUImageTextView *)setupSegmentViewWithTitle:(NSString *)title forImage:(UIImage *)image selected:(BOOL)selected {
    UUImageTextView *imageTextView = [[UUImageTextView alloc] initWithTitle:title forImage:image];
    if (selected) {
        [_selectedContainerView addSubview:imageTextView];
        [self.selectedLabelTable addObject:[imageTextView getLabel]];
        [self.selectedImageViewTable addObject:[imageTextView getImageView]];
    }
    else {
        [_containerView addSubview:imageTextView];
        [self.labelTable addObject:[imageTextView getLabel]];
        [self.imageViewTable addObject:[imageTextView getImageView]];
    }
    imageTextView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return imageTextView;
}

- (void)setupContainerView {
    _containerView = ({
        UIView *containerView = [UIView new];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        
        containerView;
    });
    [self setupConstraintsToSelfWithView:_containerView];
}

- (void)setupSelectedContainerView {
    _selectedContainerView = ({
        UIView *containerView = [UIView new];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:containerView];
        
        containerView;
    });
    [self setupConstraintsToSelfWithView:_selectedContainerView];
}

- (void)setupIndicatorViewWithStyle:(UUSegmentStyle)style {
    UUIndicatorViewType type;
    switch (style) {
        case UUSegmentStyleSlider: {
            type = UUIndicatorViewTypeSlider;
            break;
        }
        case UUSegmentStyleRounded: {
            type = UUIndicatorViewTypeRounded;
            break;
        }
    }
    _indicatorView = [[UUIndicatorView alloc] initWithType:type];
    [_containerView addSubview:_indicatorView];
    _selectedContainerView.layer.mask = _indicatorView.maskView.layer;
}

#pragma mark - Views Update

- (void)updateTitleAppearanceWithColor:(UIColor *)color selected:(BOOL)selected {
    NSArray *labels = selected ? _selectedLabelTable : _labelTable;
    for (UULabel *label in labels) {
        label.textColor = color;
    }
}

- (void)updateTitleAppearanceWithFont:(UIFont *)font selected:(BOOL)selected {
    NSArray *labels = selected ? _selectedLabelTable : _labelTable;
    for (UULabel *label in labels) {
        label.font = font;
    }
}

- (void)updateImageForColor:(UIColor *)color {
    for (UUImageView *imageView in _imageViewTable) {
        imageView.tintColor = color;
    }
}

- (void)updateBorderOfSegmentForColor:(UIColor *)color {
    self.containerView.layer.borderColor = color.CGColor;
}

- (void)updateViewForColor:(UIColor *)color {
    self.containerView.backgroundColor = color;
}

- (void)buildUIWithStyle:(UUSegmentStyle)style {
    switch (style) {
        case UUSegmentStyleSlider: {
            [self setupIndicatorViewWithStyle:UUSegmentStyleSlider];
            break;
        }
        case UUSegmentStyleRounded: {
            [self setupIndicatorViewWithStyle:UUSegmentStyleRounded];
            break;
        }
    }
}

#pragma mark - Constraints

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)setupConstraintsWithSegments:(NSArray *)segments toContainerView:(UIView *)containerView {
    UIView *lastView;
    for (UIView *view in segments) {
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:containerView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0.0
         ].active = YES;
        
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:containerView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0.0
         ].active = YES;
        
        if (lastView) {
            NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:lastView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0.0];
            leading.active = YES;
//            [self.leadingConstraints addObject:leading];
            
            [NSLayoutConstraint constraintWithItem:view
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:lastView
                                         attribute:NSLayoutAttributeWidth
                                        multiplier:1.0
                                          constant:0.0
             ].active = YES;
        }
        else {
            NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:containerView
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1.0
                                                                        constant:0.0];
            leading.active = YES;
//            [self.leadingConstraints addObject:leading];
        }
        
        lastView = view;
    }
    [NSLayoutConstraint constraintWithItem:containerView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:lastView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
}

- (void)setupConstraintsToSelfWithView:(UIView *)view {
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
}

- (void)setupConstraintsWithContainerViewToScrollView {
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeHeight
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_containerView
                                 attribute:NSLayoutAttributeWidth
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
}

- (void)updateConstraintsWithInsertSegmentView:(UIView *)segmentView atIndex:(NSUInteger)index {
    if (_leadingConstraints) {
        NSLayoutConstraint *oldLeading = _leadingConstraints[index];
        id item = oldLeading.firstItem;
        id toItem = oldLeading.secondItem;
        oldLeading.active = NO;
        
        NSLayoutConstraint *newLeading = [NSLayoutConstraint constraintWithItem:segmentView
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:toItem
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:8.0];
        newLeading.active = YES;
        [self.leadingConstraints insertObject:newLeading atIndex:index];
        
        oldLeading = [NSLayoutConstraint constraintWithItem:item
                                                  attribute:NSLayoutAttributeLeading
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:segmentView
                                                  attribute:NSLayoutAttributeTrailing
                                                 multiplier:1.0
                                                   constant:8.0];
        oldLeading.active = YES;
        self.leadingConstraints[index + 1] = oldLeading;
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        widthConstraint.active = YES;
        
        [self layoutIfNeeded];
        
        [NSLayoutConstraint constraintWithItem:segmentView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:_containerView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0.0
         ].active = YES;
        
        [NSLayoutConstraint constraintWithItem:segmentView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:_containerView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0.0
         ].active = YES;
        
        widthConstraint.active = NO;
        widthConstraint = [NSLayoutConstraint constraintWithItem:segmentView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:toItem
                                     attribute:NSLayoutAttributeWidth
                                    multiplier:1.0
                                      constant:0.0
         ];
        widthConstraint.active = YES;
        
        [UIView animateWithDuration:3 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (void)updateConstraintsWithDeleteSegmentViewAtIndex:(NSUInteger)index {
    
}

#pragma mark - Event Response

- (void)addGesture {
    if (_style == UUSegmentStyleRounded) {
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:_pan];
    }
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:_tap];
}

- (void)tap:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self];
    NSUInteger oldIndex = self.currentIndex;
    self.currentIndex = [self nearestIndexOfSegmentAtXCoordinate:location.x];
    if (oldIndex != self.currentIndex) {
        [self moveIndicatorViewToIndex:_currentIndex animated:YES];
    }
}

- (void)pan:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            _panCorrection = [gestureRecognizer locationInView:_indicatorView].x - CGRectGetWidth(_indicatorView.frame) / 2;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint panLocation = [gestureRecognizer locationInView:self];
            [self.indicatorView setCenterX:(panLocation.x - _panCorrection)];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            CGFloat indicatorCenterX = [_indicatorView getCenterX];
            self.currentIndex = [self nearestIndexOfSegmentAtXCoordinate:indicatorCenterX];
            [self moveIndicatorViewToIndex:_currentIndex animated:YES];
        }
        default:
            break;
    }
}

- (NSUInteger)nearestIndexOfSegmentAtXCoordinate:(CGFloat)x {
    NSUInteger index = x / [self segmentWidth];
    return index;
}

- (void)moveIndicatorViewToIndex:(NSUInteger)currentIndex animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:2.0 animations:^{
            [_indicatorView setCenterX:[self segmentWidth] * (0.5 + currentIndex)];
        } completion:^(BOOL finished) {
            if (finished) {
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
        }];
    }
    else {
        [_indicatorView setCenterX:[self segmentWidth] * (0.5 + currentIndex)];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

#pragma mark -

- (CGFloat)segmentWidth {
    return CGRectGetWidth(self.bounds) / _segments;
}

- (UIFont *)convertFont:(UUFont)font {
    CGFloat fontSize = font.size;
    CGFloat fontWeight;
    switch (font.weight) {
        case UUFontWeightThin:
            fontWeight = UIFontWeightThin;
            break;
        case UUFontWeightMedium:
            fontWeight = UIFontWeightMedium;
            break;
        case UUFontWeightBold:
            fontWeight = UIFontWeightBold;
            break;
    }
    return [UIFont systemFontOfSize:fontSize weight:fontWeight];
}

#pragma mark - Setters

///----------------------------------
/// @name Managing Segment Appearance
///----------------------------------

- (void)setStyle:(UUSegmentStyle)style {
    if (_style == style) {
        return;
    }
    _style = style;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
//    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.cornerRadius = cornerRadius;
    self.indicatorView.cornerRadius = cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.containerView.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    NSAssert(borderColor, @"The color should not be nil.");
    if (borderColor != _borderColor && ![borderColor isEqual:_borderColor]) {
        _borderColor = borderColor;
        [self updateBorderOfSegmentForColor:borderColor];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    NSAssert(backgroundColor, @"The color should not be nil.");
    if (backgroundColor != _backgroundColor && ![backgroundColor isEqual:_backgroundColor]) {
        _backgroundColor = backgroundColor;
        [self updateViewForColor:backgroundColor];
    }
}

///---------------------------
/// @name Managing Scroll View
///---------------------------

- (void)setScrollOn:(BOOL)scrollOn {
    _scrollOn = scrollOn;
    [_containerView removeFromSuperview];
    [self.scrollView addSubview:_containerView];
    [self setupConstraintsWithContainerViewToScrollView];
}

///-------------------------------
/// @name Managing Text Appearance
///-------------------------------

- (void)setTextColor:(UIColor *)textColor {
    NSAssert(textColor, @"The color should not be nil.");
    if (textColor != _textColor && ![textColor isEqual:_textColor]) {
        _textColor = textColor;
        [self updateTitleAppearanceWithColor:textColor selected:NO];
    }
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColor {
    NSAssert(selectedTextColor, @"The color should not be nil.");
    if (selectedTextColor != _selectedTextColor && ![selectedTextColor isEqual:_selectedTextColor]) {
        _selectedTextColor = selectedTextColor;
        [self updateTitleAppearanceWithColor:selectedTextColor selected:YES];
    }
}

- (void)setFont:(UUFont)font {
    [self updateTitleAppearanceWithFont:[self convertFont:font] selected:NO];
}

- (void)setSelectedFont:(UUFont)selectedFont {
    [self updateTitleAppearanceWithFont:[self convertFont:selectedFont] selected:YES];
}

///--------------------------------
/// @name Managing Image Appearance
///--------------------------------

- (void)setImageColor:(UIColor *)imageColor {
    NSAssert(imageColor, @"The color should not be nil.");
    if (imageColor != _imageColor && ![imageColor isEqual:_imageColor]) {
        _imageColor = imageColor;
        [self updateImageForColor:imageColor];
    }
}

#pragma mark - Getters

- (UIScrollView *)scrollView {
    if (_scrollView) {
        return _scrollView;
    }
    _scrollView = ({
        UIScrollView *scrollView = [UIScrollView new];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:scrollView];
        
        scrollView;
    });
    [self setupConstraintsToSelfWithView:_scrollView];
    
    return _scrollView;
}

- (NSMutableArray <NSLayoutConstraint *> *)leadingConstraints {
    if (_leadingConstraints) {
        return _leadingConstraints;
    }
    _leadingConstraints = [NSMutableArray array];
    return _leadingConstraints;
}

- (NSMutableArray <UULabel *> *)labelTable {
    if (_labelTable) {
        return _labelTable;
    }
    _labelTable = [NSMutableArray array];
    return _labelTable;
}

- (NSMutableArray <UUImageView *> *)imageViewTable {
    if (_imageViewTable) {
        return _imageViewTable;
    }
    _imageViewTable = [NSMutableArray array];
    return _imageViewTable;
}

- (NSMutableArray <UULabel *> *)selectedLabelTable {
    if (_selectedLabelTable) {
        return _selectedLabelTable;
    }
    _selectedLabelTable = [NSMutableArray array];
    return _selectedLabelTable;
}

- (NSMutableArray <UUImageView *> *)selectedImageViewTable {
    if (_selectedImageViewTable) {
        return _selectedImageViewTable;
    }
    _selectedImageViewTable = [NSMutableArray array];
    return _selectedImageViewTable;
}

@end
