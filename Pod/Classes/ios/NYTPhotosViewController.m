//
//  NYTPhotosViewController.m
//  NYTNewsReader
//
//  Created by Brian Capps on 2/10/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

#import "NYTPhotosViewController.h"
#import "NYTPhotosViewControllerDataSource.h"
#import "NYTPhotosDataSource.h"
#import "NYTPhotoViewController.h"

@interface NYTPhotosViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic) NYTPhotosDataSource *dataSource;
@property (nonatomic) UIPageViewController *pageViewController;

@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) CGPoint firstCenterForPanning;

@end

@implementation NYTPhotosViewController

#pragma mark - NSObject

- (void)dealloc {
    self.pageViewController.dataSource = nil;
    self.pageViewController.delegate = nil;
}

#pragma mark - UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithPhotos:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.pageViewController.view.backgroundColor = [UIColor clearColor];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.pageViewController.view.frame = self.view.bounds;
}

#pragma mark - NYTPhotosViewController

- (instancetype)initWithPhotos:(NSArray *)photos {
    return [self initWithPhotos:photos initialPhoto:photos.firstObject];
}

- (instancetype)initWithPhotos:(NSArray *)photos initialPhoto:(id<NYTPhoto>)initialPhoto {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _dataSource = [[NYTPhotosDataSource alloc] initWithPhotos:photos];
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanWithGestureRecognizer:)];
        _firstCenterForPanning = CGPointZero;
        
        [self setupPageViewControllerWithInitialPhoto:initialPhoto];
    }
    
    return self;
}

- (void)setupPageViewControllerWithInitialPhoto:(id <NYTPhoto>)initialPhoto {
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionInterPageSpacingKey: @(16)}];

    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    NYTPhotoViewController *initialPhotoViewController;
    
    if ([self.dataSource containsPhoto:initialPhoto]) {
        initialPhotoViewController = [self newPhotoViewControllerForPhoto:initialPhoto];
    }
    else {
        initialPhotoViewController = [self newPhotoViewControllerForPhoto:self.dataSource[0]];
    }
    
    [self.pageViewController setViewControllers:@[initialPhotoViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    [self.pageViewController.view addGestureRecognizer:self.panGestureRecognizer];
}

- (void)moveToPhoto:(id <NYTPhoto>)photo {
    if (![self.dataSource containsPhoto:photo]) {
        return;
    }
    
    NYTPhotoViewController *photoViewController = [self newPhotoViewControllerForPhoto:photo];
    [self.pageViewController setViewControllers:@[photoViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
}

- (NYTPhotoViewController *)newPhotoViewControllerForPhoto:(id <NYTPhoto>)photo {
    if (photo) {
        return [[NYTPhotoViewController alloc] initWithPhoto:photo];
    }
    
    return nil;
}

- (void)didPanWithGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.firstCenterForPanning = self.pageViewController.view.center;
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translatedPanGesturePoint = [panGestureRecognizer translationInView:self.view];
        CGPoint translatedCenterPoint = CGPointMake(self.firstCenterForPanning.x, self.firstCenterForPanning.y + translatedPanGesturePoint.y);

        self.pageViewController.view.center = translatedCenterPoint;
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityY = [panGestureRecognizer velocityInView:self.view].y * 0.35;
        
        CGFloat animationDuration = (ABS(velocityY) * 0.0002) + 0.2;
        
        [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.pageViewController.view.center = self.firstCenterForPanning;
        } completion:nil];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController <NYTPhotoContaining> *)viewController {
    NSUInteger photoIndex = [self.dataSource indexOfPhoto:viewController.photo];
    return [self newPhotoViewControllerForPhoto:self.dataSource[photoIndex - 1]];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController <NYTPhotoContaining> *)viewController {
    NSUInteger photoIndex = [self.dataSource indexOfPhoto:viewController.photo];
    return [self newPhotoViewControllerForPhoto:self.dataSource[photoIndex + 1]];
}

#pragma mark - UIPageViewControllerDelegate

@end
