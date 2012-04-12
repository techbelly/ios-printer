//
//  TBFlipsideViewController.h
//  GFRPrinter
//
//  Created by Ben Griffiths on 12/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TBFlipsideViewController;

@protocol TBFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(TBFlipsideViewController *)controller;
@end

@interface TBFlipsideViewController : UIViewController

@property (weak, nonatomic) id <TBFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
