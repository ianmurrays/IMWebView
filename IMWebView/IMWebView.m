//
//  IMWebView.m
//  IMWebView
//
//  Created by Ian Murray on 03-01-13.
//  Copyright (c) 2013 Ian Murray. All rights reserved.
//

#import "IMWebView.h"

typedef enum
{
    IMWebViewOperationNavigate,
    IMWebViewOperationExecuteBlock,
    IMWebViewOperationRun
} IMWebViewOperation;

@interface IMWebView () <UIWebViewDelegate>

@property (nonatomic,strong) UIWebView *webView;

@property (nonatomic,copy) IMWebViewCallback callbackBlock;

/**
 Unlike what the name might suggest, this holds a list of operations,
 (as in open this page, then click this link, then fill this form), 
 in order to perform them when calling -run.
 */
@property (nonatomic,strong) NSMutableArray *operationsQueue;

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

/**
 Enqueues an operation into the operationsQueue to be run later
 
 @param operation The operation type
 @param options The necessary options to run the operation
 */
- (void)enqueueOperation:(IMWebViewOperation)operation withOptions:(NSDictionary *)options
{
    [self.operationsQueue addObject:@{@"operation" : @(operation), @"options" : options}];
}

#pragma mark - Navigation

- (void)goToURL:(NSURL *)url withCallback:(IMWebViewCallback)callback DEPRECATED_ATTRIBUTE
{
    self.callbackBlock = callback;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)startWithURL:(NSURL *)url withCallback:(IMWebViewCallback)callback
{
    [self enqueueOperation:IMWebViewOperationNavigate withOptions:@{@"url" : url}];
}

- (void)thenExecuteBlock:(IMWebViewCallback)callback
{
    [self enqueueOperation:IMWebViewOperationExecuteBlock withOptions:@{@"block" : [callback copy]}];
}

- (void)runWithCallback:(IMWebViewCallback)callback
{
    [self enqueueOperation:IMWebViewOperationRun withOptions:@{@"callback" : [callback copy]}];
}

#pragma mark - Public DOM Manipulation / Interaction Methods

- (BOOL)selectorExists:(NSString *)selector
{
    NSString *stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@').length;", selector];
    NSString *response = [self.webView stringByEvaluatingJavaScriptFromString:stringToEvaluate];
    
    return response.integerValue > 0;
}

- (BOOL)clickElementWithSelector:(NSString *)selector
{
    if ([self selectorExists:selector])
    {
        NSString *stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@')[0].click();", selector];
        [self.webView stringByEvaluatingJavaScriptFromString:stringToEvaluate];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)fillFieldWithSelector:(NSString *)selector withValue:(NSString *)string
{
    if ([self selectorExists:selector])
    {
        // FIXME: Need to escape `string`
        NSString *stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@').val('%@');", selector, string];
    }
    
    return NO;
}

#pragma mark - Private DOM Manipulation / Interaction Methods

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
