//
//  GHUnitIOSTestView.m
//  GHUnitIOS
//
//  Created by John Boiles on 8/8/11.
//  Copyright 2011. All rights reserved.
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

#import "GHUnitIOSTestView.h"
#import <QuartzCore/QuartzCore.h>

@interface GHUnitIOSTestView ()

// TODO(johnb): Perhaps hold a scrollview here as subclassing UIViews can be weird.
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) GHUIImageViewControl *savedImageView;
@property (strong, nonatomic) GHUIImageViewControl *renderedImageView;
@property (strong, nonatomic) UIButton *approveButton;
@property (strong, nonatomic) UILabel *textLabel;

@property (strong, nonatomic) NSMutableArray *updateableConstraints;

@end

@implementation GHUnitIOSTestView

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.backgroundColor = [UIColor whiteColor];
    
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_contentView];
    
    _textLabel = [[UILabel alloc] init];
    _textLabel.font = [UIFont systemFontOfSize:12];
    _textLabel.textColor = [UIColor blackColor];
    _textLabel.numberOfLines = 0;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_textLabel];
    
    _savedImageView = [[GHUIImageViewControl alloc] init];
    [_savedImageView addTarget:self action:@selector(_selectSavedImage) forControlEvents:UIControlEventTouchUpInside];
    [_savedImageView.layer setBorderWidth:2.0];
    [_savedImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    _savedImageView.hidden = YES;
    _savedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_savedImageView];
    
    _renderedImageView = [[GHUIImageViewControl alloc] init];
    [_renderedImageView addTarget:self action:@selector(_selectRenderedImage) forControlEvents:UIControlEventTouchUpInside];
    [_renderedImageView.layer setBorderWidth:2.0];
    [_renderedImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    _renderedImageView.hidden = YES;
    _renderedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_renderedImageView];
    
    _approveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_approveButton addTarget:self action:@selector(_approveChange) forControlEvents:UIControlEventTouchUpInside];
    _approveButton.hidden = YES;
    [_approveButton setTitle:@"Approve this change" forState:UIControlStateNormal];
    [_approveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _approveButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _approveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentView addSubview:_approveButton];
    
    _updateableConstraints = [[NSMutableArray alloc] init];
    
    [self _installConstraints];
  }
  return self;
}

- (void)_installConstraints {
  NSDictionary *views = NSDictionaryOfVariableBindings(self, _contentView, _textLabel, _savedImageView, _renderedImageView, _approveButton);
  
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_contentView]|" options:0 metrics:nil views:views]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentView(320)]|" options:0 metrics:nil views:views]];
  
  // Fix text view to sides and bottom of the content view
  [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_textLabel]-10-|" options:0 metrics:nil views:views]];
  [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textLabel]-10-|" options:0 metrics:nil views:views]];
  [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_approveButton]-10-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
  [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_savedImageView]-[_renderedImageView]" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
}

- (void)updateConstraints {
  NSDictionary *views = NSDictionaryOfVariableBindings(self, _contentView, _textLabel, _savedImageView, _renderedImageView, _approveButton);
  
  [self.contentView removeConstraints:self.updateableConstraints];
  [self.updateableConstraints removeAllObjects];
  
  if (self.savedImageView.hidden && self.renderedImageView.hidden) {
    [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_textLabel]" options:0 metrics:nil views:views]];
  } else {
    if (!self.approveButton.hidden) {
      [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_approveButton]-10-[_savedImageView]" options:0 metrics:nil views:views]];
    } else {
      [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_savedImageView]" options:0 metrics:nil views:views]];
    }
    [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_savedImageView]-(>=10)-[_textLabel]" options:NSLayoutFormatAlignAllLeft metrics:nil views:views]];
    [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_renderedImageView]-(>=10)-[_textLabel]" options:0 metrics:nil views:views]];
    
    if (!self.savedImageView.hidden) {
      CGFloat width = self.renderedImageView.hidden ? 300.0 : 145.0;
      CGFloat aspectRatio = self.savedImageView.image.size.height / self.savedImageView.image.size.width;
      CGFloat height = aspectRatio * width;
      [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_savedImageView(%f)]", height] options:0 metrics:nil views:views]];
      [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[_savedImageView(%f)]", width] options:0 metrics:nil views:views]];
    }
    
    if (!self.renderedImageView.hidden) {
      CGFloat width = 145.0;
      CGFloat aspectRatio = self.renderedImageView.image.size.height / self.renderedImageView.image.size.width;
      CGFloat height = aspectRatio * width;
      [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_renderedImageView(%f)]", height] options:0 metrics:nil views:views]];
      [self.updateableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[_renderedImageView(%f)]", width] options:0 metrics:nil views:views]];
    }
  }
  
  [_contentView addConstraints:self.updateableConstraints];
  [super updateConstraints];
}

- (void)_selectSavedImage {
  [self.controlDelegate testViewDidSelectSavedImage:self];
}

- (void)_selectRenderedImage {
  [self.controlDelegate testViewDidSelectRenderedImage:self];
}

- (void)_approveChange {
  [self.controlDelegate testViewDidApproveChange:self];
}

- (void)setSavedImage:(UIImage *)savedImage renderedImage:(UIImage *)renderedImage text:(NSString *)text {
  self.savedImageView.image = savedImage;
  self.savedImageView.hidden = savedImage ? NO : YES;
  self.savedImageView.userInteractionEnabled = YES;
  self.renderedImageView.image = renderedImage;
  self.renderedImageView.hidden = NO;
  self.approveButton.hidden = NO;
  self.textLabel.text = text;
  [self setNeedsUpdateConstraints];
}

- (void)setText:(NSString *)text {
  self.savedImageView.hidden = YES;
  self.renderedImageView.hidden = YES;
  self.approveButton.hidden = YES;
  self.textLabel.text = text;
  [self setNeedsUpdateConstraints];
}

- (void)setPassingImage:(UIImage *)passingImage {
  self.savedImageView.image = passingImage;
  self.savedImageView.hidden = NO;
  self.savedImageView.userInteractionEnabled = NO;
  [self setNeedsUpdateConstraints];
}

@end
