//
//  IMWebViewTests.m
//  IMWebViewTests
//
//  Created by Ian Murray on 03-01-13.
//  Copyright (c) 2013 Ian Murray. All rights reserved.
//

#import "IMWebViewTests.h"
#import "IMWebView.h"

@interface IMWebViewTests ()

@property (nonatomic,strong) IMWebView *webView;

@end

@implementation IMWebViewTests

- (void)setUp
{
    [super setUp];
    
    self.webView = [[IMWebView alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    
    self.webView = nil;
}

- (void)testJqueryInjection
{
    [self.webView goToURL:[NSURL URLWithString:@"https://dl.dropbox.com/u/1916643/SkoutLandingPage/index.html"] withCallback:^{
        NSLog(@"impressive");
    }];
}

@end
