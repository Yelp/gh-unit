//
//  GHUnitIOSViewController.m
//  GHUnitIOS
//
//  Created by Gabriel Handford on 1/25/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "GHUnitIOSViewController.h"

NSString *const GHUnitTextFilterKey = @"TextFilter";
NSString *const GHUnitFilterKey = @"Filter";

@interface GHUnitIOSViewController ()

@property (strong, nonatomic) NSIndexPath *lastSelectedIndexPath;

@end

@implementation GHUnitIOSViewController

@synthesize suite=suite_;

- (id)init {
  if ((self = [super init])) {
    self.title = @"Tests";
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
      self.edgesForExtendedLayout = UIRectEdgeNone;
    }
  }
  return self;
}

- (void)dealloc {
  view_.tableView.delegate = nil;
  view_.searchBar.delegate = nil;
}

- (void)loadDefaults { }

- (void)saveDefaults {
  [dataSource_ saveDefaults];
}

- (void)loadView {
  [super loadView];

  runButton_ = [[UIBarButtonItem alloc] initWithTitle:@"Run" style:UIBarButtonItemStyleDone
                                               target:self action:@selector(_toggleTestsRunning)];
  self.navigationItem.rightBarButtonItem = runButton_;  

  // Clear view
  view_.tableView.delegate = nil;
  view_.searchBar.delegate = nil;
  
  view_ = [[GHUnitIOSView alloc] init];
  view_.searchBar.delegate = self;
  NSString *textFilter = [self _textFilter];
  if (textFilter) view_.searchBar.text = textFilter;  
  view_.filterControl.selectedSegmentIndex = [self _filterIndex];
  [view_.filterControl addTarget:self action:@selector(_filterChanged:) forControlEvents:UIControlEventValueChanged];
  view_.tableView.delegate = self;
  view_.tableView.dataSource = self.dataSource;
  self.view = view_;  
  [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self reload];
  if (self.lastSelectedIndexPath) {
    NSInteger section = MIN(self.lastSelectedIndexPath.section, self.dataSource.root.children.count - 1);
    GHTestNode *sectionNode = self.dataSource.root.children[section];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:MIN(self.lastSelectedIndexPath.row, sectionNode.children.count - 1) inSection:section];
    if (![[view_.tableView indexPathsForVisibleRows] containsObject:indexPath] && [view_.tableView cellForRowAtIndexPath:indexPath]) {
      [view_.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
  }
  self.lastSelectedIndexPath = nil;
}

- (GHUnitIOSTableViewDataSource *)dataSource {
  if (!dataSource_) {
    dataSource_ = [[GHUnitIOSTableViewDataSource alloc] initWithIdentifier:@"Tests" suite:[GHTestSuite suiteFromEnv]];  
    [dataSource_ loadDefaults];    
  }
  return dataSource_;
}

- (void)reload {
  [self.dataSource.root setTextFilter:[self _textFilter]];  
  [self.dataSource.root setFilter:[self _filterIndex]];
  [view_.tableView reloadData]; 
}

#pragma mark Running

- (void)_toggleTestsRunning {
  if (self.dataSource.isRunning) [self cancel];
  else [self runTests];
}

- (void)runTests {
  if (self.dataSource.isRunning) return;
  
  [self view];
  runButton_.title = @"Cancel";
  userDidDrag_ = NO; // Reset drag status
  view_.statusLabel.textColor = [UIColor blackColor];
  view_.statusLabel.text = @"Starting tests...";
  [self.dataSource run:self inParallel:NO options:GHTestOptionIgnoreViewTestNotification];
}

- (void)cancel {
  view_.statusLabel.text = @"Cancelling...";
  [dataSource_ cancel];
}

- (void)_exit {
  exit(0);
}

#pragma mark Properties

- (NSString *)_textFilter {
  return [[NSUserDefaults standardUserDefaults] objectForKey:GHUnitTextFilterKey];
}

- (void)_setTextFilter:(NSString *)textFilter {
  [[NSUserDefaults standardUserDefaults] setObject:textFilter forKey:GHUnitTextFilterKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_setFilterIndex:(NSInteger)index {
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:index] forKey:GHUnitFilterKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)_filterIndex {
  return [[[NSUserDefaults standardUserDefaults] objectForKey:GHUnitFilterKey] integerValue];
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAll;
}

- (void)_filterChanged:(id)sender {
  [self _setFilterIndex:view_.filterControl.selectedSegmentIndex];
  [self reload];
}

- (void)reloadTest:(id<GHTest>)test {
  NSIndexPath *indexPath = [dataSource_ indexPathToTest:test];
  if (!indexPath) return;
  [view_.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
  if (!userDidDrag_ && !dataSource_.isEditing && ![test isDisabled]
      && [test status] == GHTestStatusRunning && ![test conformsToProtocol:@protocol(GHTestGroup)]) 
    [view_.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (void)scrollToBottom {
  NSInteger lastGroupIndex = [dataSource_ numberOfGroups] - 1;
  if (lastGroupIndex < 0) return;
  NSInteger lastTestIndex = [dataSource_ numberOfTestsInGroup:lastGroupIndex] - 1;
  if (lastTestIndex < 0) return;
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastTestIndex inSection:lastGroupIndex];
  [view_.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)setStatusText:(NSString *)message {
  view_.statusLabel.text = message;
}

- (GHTestNode *)_testNodeForIndexPath:(NSIndexPath *)indexPath {
  GHTestNode *sectionNode = self.dataSource.root.children[indexPath.section];
  return sectionNode.children[indexPath.row];
}

#pragma mark Delegates (UITableView)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  GHTestNode *node = [dataSource_ nodeForIndexPath:indexPath];
  if (dataSource_.isEditing) {
    [node setSelected:![node isSelected]];
    [node notifyChanged];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [view_.tableView reloadData];
  } else {    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GHTestNode *testNode = [self _testNodeForIndexPath:indexPath];
    
    GHUnitIOSTestViewController *testViewController = [[GHUnitIOSTestViewController alloc] init];
    testViewController.delegate = self;
    [testViewController setTest:testNode.test];
    [self.navigationController pushViewController:testViewController animated:YES];
    self.lastSelectedIndexPath = indexPath;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 36.0f;
}

#pragma mark Delegates (UIScrollView) 

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  userDidDrag_ = YES;
}

#pragma mark Delegates (GHTestRunner)

- (void)_setRunning:(BOOL)running runner:(GHTestRunner *)runner {
  if (running) {
    view_.filterControl.enabled = NO;
  } else {
    view_.filterControl.enabled = YES;
    GHTestStats stats = [runner.test stats];
    if (stats.failureCount > 0) {
      view_.statusLabel.textColor = [UIColor redColor];
    } else {
      view_.statusLabel.textColor = [UIColor blackColor];
    }

    runButton_.title = @"Run";
  }
}

- (void)testRunner:(GHTestRunner *)runner didLog:(NSString *)message {
  [self setStatusText:message];
}

- (void)testRunner:(GHTestRunner *)runner test:(id<GHTest>)test didLog:(NSString *)message {
  
}

- (void)testRunner:(GHTestRunner *)runner didStartTest:(id<GHTest>)test {
  [self setStatusText:[NSString stringWithFormat:@"Test '%@' started.", [test identifier]]];
  [self reloadTest:test];
}

- (void)testRunner:(GHTestRunner *)runner didUpdateTest:(id<GHTest>)test {
  [self reloadTest:test];
}

- (void)testRunner:(GHTestRunner *)runner didEndTest:(id<GHTest>)test { 
  [self reloadTest:test];
}

- (void)testRunnerDidStart:(GHTestRunner *)runner { 
  [self _setRunning:YES runner:runner];
}

- (void)testRunnerDidCancel:(GHTestRunner *)runner { 
  [self _setRunning:NO runner:runner];
  [self setStatusText:@"Cancelled..."];
}

- (void)testRunnerDidEnd:(GHTestRunner *)runner {
  [self _setRunning:NO runner:runner];
  [self setStatusText:[dataSource_ statusString:@"Tests finished. "]];
  
  // Save defaults after test run
  [self saveDefaults];
  
  if (getenv("GHUNIT_AUTOEXIT")) {
    NSLog(@"Exiting (GHUNIT_AUTOEXIT)");
    exit((int)runner.test.stats.failureCount);
  }
}

#pragma mark Delegates (UISearchBar)

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  [searchBar setShowsCancelButton:YES animated:YES];  
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
  return ![dataSource_ isRunning];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  // Workaround for clearing search
  if ([searchBar.text isEqualToString:@""]) {
    [self searchBarSearchButtonClicked:searchBar];
    return;
  }
  NSString *textFilter = [self _textFilter];
  searchBar.text = (textFilter ? textFilter : @"");
  [searchBar resignFirstResponder];
  [searchBar setShowsCancelButton:NO animated:YES]; 
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  [searchBar resignFirstResponder];
  [searchBar setShowsCancelButton:NO animated:YES]; 
  
  [self _setTextFilter:searchBar.text];
  [self reload];
}

#pragma mark Delegates (GHUnitIOSTestViewController)

- (id<GHTest>)testViewControllerLoadedNextFailingTest:(GHUnitIOSTestViewController *)controller {
  NSUInteger sectionIndex = self.lastSelectedIndexPath.section;
  NSUInteger testIndex = self.lastSelectedIndexPath.row + 1;
  GHTestNode *nextNode = nil;
  while (!nextNode && sectionIndex < self.dataSource.root.children.count) {
    GHTestNode *sectionNode = self.dataSource.root.children[sectionIndex];
    while (testIndex < sectionNode.children.count) {
      GHTestNode *testNode = sectionNode.children[testIndex];
      if (testNode.test.status != GHTestStatusSucceeded) {
        nextNode = testNode;
        self.lastSelectedIndexPath = [NSIndexPath indexPathForRow:testIndex inSection:sectionIndex];
        break;
      }
      testIndex++;
    }
    testIndex = 0;
    sectionIndex++;
  }
  return nextNode.test;
}

@end
