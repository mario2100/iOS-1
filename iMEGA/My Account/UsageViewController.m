/**
 * @file UsageViewController.h
 * @brief View controller to see your space usage.
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "PieChartView.h"
#import "SVProgressHUD.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"

#import "UsageViewController.h"

@interface UsageViewController () <PieChartViewDelegate, PieChartViewDataSource, UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    NSByteCountFormatter *byteCountFormatter;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutBarButtonItem;

@property (weak, nonatomic) IBOutlet UIScrollView *usageScrollView;

@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UILabel *pieChartMainLabel;
@property (weak, nonatomic) IBOutlet UILabel *pieChartSecondaryLabel;

@property (weak, nonatomic) IBOutlet UIPageControl *usagePageControl;

@property (weak, nonatomic) IBOutlet UILabel *localLabel;
@property (weak, nonatomic) IBOutlet UILabel *localSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *localProgressView;

@property (weak, nonatomic) IBOutlet UILabel *cloudDriveLabel;
@property (weak, nonatomic) IBOutlet UILabel *cloudDriveSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *cloudDriveProgressView;

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel *rubbishBinSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *rubbishBinProgressView;

@property (weak, nonatomic) IBOutlet UILabel *incomingSharesLabel;
@property (weak, nonatomic) IBOutlet UILabel *incomingSharesSizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *incomingSharesProgressView;

@end

@implementation UsageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.pieChartView.delegate = self;
    self.pieChartView.datasource = self;
    
    [self.logoutBarButtonItem setTitle:AMLocalizedString(@"logoutLabel", nil)];
    
    [self.localLabel setText:AMLocalizedString(@"localLabel", @"Local")];
    [self.cloudDriveLabel setText:AMLocalizedString(@"cloudDrive", @"")];
    [self.rubbishBinLabel setText:AMLocalizedString(@"rubbishBinLabel", @"")];
    [self.incomingSharesLabel setText:AMLocalizedString(@"incomingShares", @"")];
    
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    [_pieChartView.layer setCornerRadius:CGRectGetWidth(self.pieChartView.frame)/2];
    [_pieChartView.layer setMasksToBounds:YES];
    [self changePieChartText:_usagePageControl.currentPage];
    
    NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:0] longLongValue]];
    NSNumber *freeSizeNumber = [[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize];
    [_localSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_localProgressView setProgress:([[self.sizesArray objectAtIndex:0] floatValue] / [freeSizeNumber floatValue]) animated:NO];
    
    stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:1] longLongValue]];
    [_cloudDriveSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_cloudDriveProgressView setProgress:([[self.sizesArray objectAtIndex:1] floatValue] / [[self.sizesArray objectAtIndex:5] floatValue]) animated:NO];
    
    stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:2] longLongValue]];
    [_rubbishBinSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_rubbishBinProgressView setProgress:([[self.sizesArray objectAtIndex:2] floatValue] / [[self.sizesArray objectAtIndex:5] floatValue]) animated:NO];
     
    stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:3] longLongValue]];
    [_incomingSharesSizeLabel setAttributedText:[self textForSizeLabels:stringFromByteCount]];
    [_incomingSharesProgressView setProgress:([[self.sizesArray objectAtIndex:3] floatValue] / [[self.sizesArray objectAtIndex:5] floatValue]) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"usage", nil)];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)changePieChartText:(NSInteger)currentPage {
    
    [_pieChartMainLabel setAttributedText:[self textForMainLabel:currentPage]];
    
    NSString *textSecondaryLabel;
    switch (currentPage) {
        case 0: {
            textSecondaryLabel = [NSString stringWithFormat:AMLocalizedString(@"of %@", @"Sentece showed under the used space percentage to complete the info with the maximum storage."), [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:5] longLongValue]]];
            break;
        }
            
        case 1: {
            textSecondaryLabel = [NSString stringWithFormat:AMLocalizedString(@"used of %@", @"Sentece showed under the used space to complete the info with the maximum storage."), [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:5] longLongValue]]];
            break;
        }
            
        case 2: {
            textSecondaryLabel = [NSString stringWithFormat:AMLocalizedString(@"available of %@", @"Sentece showed under the available space to complete the info with the maximum storage."), [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:5] longLongValue]]];
            break;
        }
    }
    [_pieChartSecondaryLabel setText:textSecondaryLabel];
}

- (NSMutableAttributedString *)textForMainLabel:(NSInteger)currentPage {
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setLocale:[NSLocale currentLocale]];
    [numberFormatter setMaximumFractionDigits:0];
    
    NSMutableAttributedString *firstPartMutableAttributedString;
    NSMutableAttributedString *secondPartMutableAttributedString;
    NSString *stringFromByteCount;
    NSRange firstPartRange;
    NSRange secondPartRange;
    
    switch (currentPage) {
        case 0: {
            NSNumber *number = [NSNumber numberWithFloat:(([[self.sizesArray objectAtIndex:4] floatValue] / [[self.sizesArray objectAtIndex:5] floatValue]) * 100)];
            NSString *firstPartString = [numberFormatter stringFromNumber:number];
            firstPartRange = [firstPartString rangeOfString:firstPartString];
            firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
            
            NSString *secondPartString = @"%";
            secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
            secondPartRange = [secondPartString rangeOfString:secondPartString];
            break;
        }
            
        case 1: {
            stringFromByteCount = [byteCountFormatter stringFromByteCount:[[self.sizesArray objectAtIndex:4] longLongValue]];
            break;
        }
            
        case 2: {
            stringFromByteCount = [byteCountFormatter stringFromByteCount:([[self.sizesArray objectAtIndex:5] longLongValue] - [[self.sizesArray objectAtIndex:4] longLongValue])];
            break;
        }
    }
    
    if (currentPage == 1 || currentPage == 2) {
        NSString *firstPartString = [self stringWithoutUnit:stringFromByteCount];;
        NSNumber *number = [numberFormatter numberFromString:firstPartString];
        firstPartString = [numberFormatter stringFromNumber:number];
        firstPartRange = [firstPartString rangeOfString:firstPartString];
        firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
        
        NSString *secondPartString = [self stringWithoutCount:stringFromByteCount];
        secondPartRange = [secondPartString rangeOfString:secondPartString];
        secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
    }
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:60.0]
                                             range:firstPartRange];
    
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                              value:[UIFont fontWithName:@"HelveticaNeue-Thin" size:30.0]
                                              range:secondPartRange];

    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (NSMutableAttributedString *)textForSizeLabels:(NSString *)stringFromByteCount {
    
    NSMutableAttributedString *firstPartMutableAttributedString;
    NSMutableAttributedString *secondPartMutableAttributedString;
    
    NSString *firstPartString = [self stringWithoutUnit:stringFromByteCount];
    NSRange firstPartRange = [firstPartString rangeOfString:firstPartString];
    firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
    
    NSString *secondPartString = [NSString stringWithFormat:@" %@", [self stringWithoutCount:stringFromByteCount]];
    NSRange secondPartRange = [secondPartString rangeOfString:secondPartString];
    secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
    
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont fontWithName:kFont size:18.0]
                                             range:firstPartRange];
    
    [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                              value:[UIFont fontWithName:kFont size:12.0]
                                              range:secondPartRange];
    [secondPartMutableAttributedString addAttribute:NSForegroundColorAttributeName
                                              value:megaMediumGray
                                              range:secondPartRange];
    
    [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    
    return firstPartMutableAttributedString;
}

- (NSString *)stringWithoutUnit:(NSString *)stringFromByteCount {
    NSString *string = [[stringFromByteCount componentsSeparatedByString:@" "] objectAtIndex:0];
    if ([string isEqualToString:@"Zero"]) {
        string = @"0";
    }
    return string;
}

- (NSString *)stringWithoutCount:(NSString *)stringFromByteCount {
    NSString *string = [[stringFromByteCount componentsSeparatedByString:@" "] objectAtIndex:1];
    if ([string isEqualToString:@"bytes"]) {
        string = @"KB";
    }
    return string;
}

#pragma mark - IBActions

- (IBAction)logoutTouchUpInside:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachable]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    } else {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noInternetConnection", @"No Internet Connection")];
    }
}


- (IBAction)leftSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 2) {
        return;
    }
    
    [self changePieChartText:(page+1)];
    [_usagePageControl setCurrentPage:(page+1)];
}

- (IBAction)rightSwipeGestureRecognizer:(UISwipeGestureRecognizer *)sender {
    NSInteger page = _usagePageControl.currentPage;
    if (page == 0) {
        return;
    }
    
    [self changePieChartText:(page-1)];
    [_usagePageControl setCurrentPage:(page-1)];
}


#pragma mark - PieChartViewDelegate

- (CGFloat)centerCircleRadius {
    return 88.f;
}

#pragma mark - PieChartViewDataSource

- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView {
    return 4;
}

- (UIColor *)pieChartView:(PieChartView *)pieChartView colorForSliceAtIndex:(NSUInteger)index {
    switch (index+1) {
        case 1: //Cloud Drive
            return megaBlue;
            break;
            
        case 2: //Rubbish Bin
            return megaGreen;
            break;
            
        case 3: //Incoming Shares
            return megaOrange;
            break;
            
        default: //Available space
            return [UIColor whiteColor];
            break;
    }
}

- (double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index {
    double valueForSlice;
    switch (index+1) {
        case 1: //Cloud Drive
            valueForSlice = [[self.sizesArray objectAtIndex:(index+1)] doubleValue];
            break;
            
        case 2: //Rubbish Bin
            valueForSlice = [[self.sizesArray objectAtIndex:(index+1)] doubleValue];
            break;
            
        case 3: //Incoming Shares
            valueForSlice = [[self.sizesArray objectAtIndex:(index+1)] doubleValue];
            break;
            
        default: //Available space
            valueForSlice = ([[self.sizesArray objectAtIndex:5] doubleValue] - [[self.sizesArray objectAtIndex:4] doubleValue]);
            break;
    }
    if (valueForSlice == 0) {
        valueForSlice = 1;
    }
    return valueForSlice;
}

@end
