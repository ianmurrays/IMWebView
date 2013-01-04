//
//  IMWebView.m
//  IMWebView
//
//  Created by Ian Murray on 03-01-13.
//  Copyright (c) 2013 Ian Murray. All rights reserved.
//

#import "IMWebView.h"

@interface IMWebView () <UIWebViewDelegate>

@property (nonatomic,strong) UIWebView *webView;

@property (nonatomic,copy) IMWebViewCallback callbackBlock;

@end

@implementation IMWebView

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.webView = [[UIWebView alloc] init];
        self.webView.delegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    self.webView.delegate = nil;
}

#pragma mark - Navigation

- (void)goToURL:(NSURL *)url withCallback:(IMWebViewCallback)callback
{
    self.callbackBlock = callback;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - DOM Manipulation / Interaction

- (void)injectScriptWithName:(NSString *)name
{
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:name ofType:@"js"];
    NSAssert(scriptPath != nil, @"scriptPath %@.js should not have been nil", name);
    NSString *scriptToInject = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView stringByEvaluatingJavaScriptFromString:scriptToInject];
}

- (void)pollForState:(NSString *)state withCallback:(IMWebViewCallback)callback
{
    // FIXME: if we never inject jquery we'll get trapped in a recursion loop.
    if ([@"true" caseInsensitiveCompare:[self.webView stringByEvaluatingJavaScriptFromString:state]] == NSOrderedSame)
    {
        callback();
    }
    else
    {
        // Poll in .5 seconds more
        int64_t delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self pollForState:state withCallback:callback];
        });
    }
}

- (void)injectJqueryWithCallBack:(IMWebViewCallback)callback
{
    [self injectScriptWithName:@"inject-jquery"];
    
    // Wait until jQuery is loaded and then poll for document readiness.
    [self pollForState:@"document.IMWebViewJqueryLoaded" withCallback:^{
        [self injectDocumentReadinessScriptWithCallback:callback];
    }];
}

- (void)injectDocumentReadinessScriptWithCallback:(IMWebViewCallback)callback
{
    [self injectScriptWithName:@"document-readiness"];
    [self pollForState:@"document.IMWebViewDocumentReady" withCallback:callback];
}

#pragma mark - Other Methods

- (BOOL)loading
{
    return self.webView.loading;
}

- (NSURL *)currentURL
{
    return self.webView.request.URL;
}

- (void)setCallbackBlock:(IMWebViewCallback)callbackBlock
{
    if (callbackBlock == nil)
    {
        _callbackBlock = ^{};
    }
    else
    {
        _callbackBlock = [callbackBlock copy];
    }
}

#pragma mark - UIWebView Delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"IMWebView failed loading with error: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"IMWebView finished loading %@", self.currentURL);
    [self injectJqueryWithCallBack:^{
        self.callbackBlock();
    }];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"IMWebView stared loading");
}

@end
