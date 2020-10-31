//
//  HistoryVC.m
//  CigarGuard
//
//  Created by admin on 4/30/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import <MagicalRecord/MagicalRecord.h>
#import "HistoryVC.h"
#import "History.h"
#import "HistoryView.h"

@interface HistoryVC ()
{
    __weak IBOutlet UIScrollView *_scrollView;
    __weak IBOutlet UIView *_scrollContentView;
    __weak IBOutlet NSLayoutConstraint *_scrollContentWidthConstraint;
    __weak IBOutlet UIPageControl *_pageControl;
    
    NSMutableArray *pages;
}
@end

@implementation HistoryVC

#define MAX_PAGE_COUNT  10

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initialize];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadData];
}

- (void)initialize
{
    pages = [NSMutableArray array];
	_pageControl.transform = CGAffineTransformMakeScale(0.7, 0.7);
}

- (void)loadData
{
    // Clean
    
    _scrollView.contentOffset = CGPointMake(0, 0);
    
    for (UIView *view in pages) {
        [view removeFromSuperview];
    }
    
    // Add
    
    int pageCount = 0;
    
    NSArray *list = [History MR_findAllSortedBy:@"date" ascending:NO];
    if (list && list.count > 0) {
        for (int i=0; i<list.count; i++) {
            History *history = list[i];
			NSLog(@"%@", [history date]);
            if (pageCount < MAX_PAGE_COUNT) {
                [self addPage:history at:pageCount++];
            } else {
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
                    [history MR_deleteEntity];
                }];
            }
        }
    }
    
    _pageControl.numberOfPages = pageCount;
    _scrollContentWidthConstraint.constant = _scrollView.bounds.size.width * pageCount;
}

- (void)addPage:(History *)history at:(int)index
{
    HistoryView *view = [[[NSBundle mainBundle] loadNibNamed:@"HistoryView" owner:self options:nil] firstObject];
    view.frame = CGRectMake(_scrollView.bounds.size.width * index, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
    [view loadData:history];
    [_scrollContentView addSubview:view];
    
    [pages addObject:view];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	NSInteger index = fabs(scrollView.contentOffset.x) / scrollView.frame.size.width;
	[_pageControl setCurrentPage:index];
}

@end
