
#import "MEGAQuerySignupLinkRequestDelegate.h"

#import "SVProgressHUD.h"

#import "CreateAccountViewController.h"
#import "LoginViewController.h"
#import "MEGALinkManager.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGASdkManager.h"
#import "OnboardingViewController.h"
#import "UIApplication+MNZCategory.h"

#import "SAMKeychain.h"

@interface MEGAQuerySignupLinkRequestDelegate ()

@property (nonatomic, copy) void (^completion)(MEGARequest *request, MEGAError *error);
@property (nonatomic) URLType urlType;

@property (nonatomic) NSString *email;

@end

@implementation MEGAQuerySignupLinkRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))requestCompletion urlType:(URLType)urlType {
    self = [super init];
    if (self) {
        _completion = requestCompletion;
        _urlType = urlType;
    }
    
    return self;
}

#pragma mark - Private

- (void)manageQuerySignupLinkRequest:(MEGARequest *)request {
    if (self.urlType == URLTypeConfirmationLink) {
        if (request.flag) {
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionId"]) {
                if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
                    [MEGASdkManager createSharedMEGAChatSdk];
                }
                
                MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:nil];
                if (chatInit != MEGAChatInitWaitingNewSession) {
                    MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
                    [[MEGASdkManager sharedMEGAChatSdk] logout];
                }
                
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                loginRequestDelegate.confirmAccountInOtherClient = YES;
                NSString *base64pwkey = [SAMKeychain passwordForService:@"MEGA" account:@"base64pwkey"];
                NSString *stringHash = [[MEGASdkManager sharedMEGASdk] hashForBase64pwkey:base64pwkey email:request.email];
                [[MEGASdkManager sharedMEGASdk] fastLoginWithEmail:request.email stringHash:stringHash base64pwKey:base64pwkey delegate:loginRequestDelegate];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
                    if ([rootViewController isKindOfClass:OnboardingViewController.class]) {
                        UINavigationController *loginNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginNavigationControllerID"];
                        LoginViewController *loginVC = loginNC.viewControllers.firstObject;
                        loginVC.emailString = request.email;
                        
                        [UIApplication.mnz_presentingViewController presentViewController:loginNC animated:YES completion:nil];
                    }
                }]];
                
                [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
                
                [MEGALinkManager resetLinkAndURLType];
            }
        } else {
            [MEGALinkManager presentConfirmViewWithURLType:URLTypeConfirmationLink link:MEGALinkManager.linkURL.absoluteString email:self.email];
        }
    } else if (self.urlType == URLTypeNewSignUpLink && MEGALinkManager.emailOfNewSignUpLink)  {
        UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
        if ([rootViewController isKindOfClass:OnboardingViewController.class]) {
            UINavigationController *createNC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CreateAccountNavigationControllerID"];
            CreateAccountViewController *createAccountVC = createNC.viewControllers.firstObject;
            createAccountVC.emailString = MEGALinkManager.emailOfNewSignUpLink;
            
            [UIApplication.mnz_presentingViewController presentViewController:createNC animated:YES completion:nil];
            
            MEGALinkManager.emailOfNewSignUpLink = nil;
        }
        
        [MEGALinkManager resetLinkAndURLType];
    }
    
    self.email = nil;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEArgs:
            case MEGAErrorTypeApiEIncomplete:
                [MEGALinkManager showLinkNotValid];
                break;
                
                
            case MEGAErrorTypeApiENoent: {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:AMLocalizedString(@"accountAlreadyConfirmed", @"Message shown when the user clicks on a confirm account link that has already been used") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
                break;
            }
                
            default: {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
                break;
            }
        }
        
        [MEGALinkManager resetLinkAndURLType];
    } else {
        self.email = request.email;
        MEGALinkManager.linkURL = [NSURL URLWithString:request.link];
        MEGALinkManager.emailOfNewSignUpLink = request.email;
        
        [self manageQuerySignupLinkRequest:request];
    }
}

@end
