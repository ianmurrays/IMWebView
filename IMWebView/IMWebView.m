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

- (void)injectJqueryWithCallBack:(IMWebViewCallback)callback
{
    NSString *jqueryInjectorPath = [[NSBundle mainBundle] pathForResource:@"inject-jquery" ofType:@"js"];
    NSAssert(jqueryInjectorPath != nil, @"jqueryInjectorPath should not have been nil");
    NSString *jqueryInjector = [NSString stringWithContentsOfFile:jqueryInjectorPath encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView stringByEvaluatingJavaScriptFromString:jqueryInjector];
    
    [self pollForJqueryWithCallback:callback];
}

- (void)pollForJqueryWithCallback:(IMWebViewCallback)callback
{
    // FIXME: if we never inject jquery we'll get trapped in a recursion loop.
    NSString *checkJquery = @"document.IMWebViewJqueryLoaded";
    if ([@"true" caseInsensitiveCompare:[self.webView stringByEvaluatingJavaScriptFromString:checkJquery]] == NSOrderedSame)
    {
        callback();
    }
    else
    {
        // Poll in .5 seconds more
        [self performSelector:@selector(pollForJqueryWithCallback:) withObject:callback afterDelay:0.5];
    }
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
    [self injectJqueryWithCallBack:^{
        // Did we actually inject the thing?
        
        NSLog(@"html? \n\n%@", [self.webView stringByEvaluatingJavaScriptFromString:@"$imWebViewJquery('body').html()"]);
        
        self.callbackBlock();
    }];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"IMWebView stared loading URL: %@", webView.request.URL);
}

@end
