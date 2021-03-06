#import "MEGASdkManager.h"

@implementation MEGASdkManager

static NSString *_appKey = nil;
static NSString *_userAgent = nil;
static MEGASdk *_megaSDK = nil;
static MEGASdk *_megaSDKFolder = nil;

MEGAChatSdk *_MEGAChatSdk = nil;


+ (void)setAppKey:(NSString *)appKey {
    _appKey = appKey;
}

+ (void)setUserAgent:(NSString *)userAgent {
    _userAgent = userAgent;
}

+ (MEGASdk *)sharedMEGASdk {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSAssert(_appKey != nil, @"setAppKey: should be called first");
        NSAssert(_userAgent != nil, @"setUserAgent: should be called first");
        NSError *error;
        NSURL *applicationSupportDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        if (error) {
            MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
        }
        NSString *basePath = applicationSupportDirectoryURL.path;
        _megaSDK = [[MEGASdk alloc] initWithAppKey:_appKey userAgent:_userAgent basePath:basePath];
        [_megaSDK retrySSLErrors:YES];
    });
    return _megaSDK;
}

+ (MEGAChatSdk *)sharedMEGAChatSdk {
    return _MEGAChatSdk;
}

+ (void)createSharedMEGAChatSdk {
    _MEGAChatSdk = [[MEGAChatSdk alloc] init:_megaSDK];
    [_MEGAChatSdk addChatDelegate:(id<MEGAChatDelegate>)[[UIApplication sharedApplication] delegate]];
    [_MEGAChatSdk addChatRequestDelegate:(id<MEGAChatRequestDelegate>)[[UIApplication sharedApplication] delegate]];
    MEGALogDebug(@"_MEGAChatSdk created: %@", _MEGAChatSdk);
    [MEGASdk setLogToConsole:NO];
    [MEGAChatSdk setLogToConsole:YES];
}

+ (void)destroySharedMEGAChatSdk {
    [_MEGAChatSdk removeChatDelegate:(id<MEGAChatDelegate>)[[UIApplication sharedApplication] delegate]];
    [_MEGAChatSdk removeChatRequestDelegate:(id<MEGAChatRequestDelegate>)[[UIApplication sharedApplication] delegate]];
    _MEGAChatSdk = nil;
    MEGALogDebug(@"_MEGAChatSdk destroyed: %@", _MEGAChatSdk);
    [MEGAChatSdk setLogToConsole:NO];
    [MEGASdk setLogToConsole:YES];
}

+ (MEGASdk *)sharedMEGASdkFolder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSAssert(_appKey != nil, @"setAppKey: should be called first");
        NSAssert(_userAgent != nil, @"setUserAgent: should be called first");
        NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _megaSDKFolder = [[MEGASdk alloc] initWithAppKey:_appKey userAgent:_userAgent basePath:basePath];
        [_megaSDKFolder retrySSLErrors:YES];
    });
    return _megaSDKFolder;
}

@end
