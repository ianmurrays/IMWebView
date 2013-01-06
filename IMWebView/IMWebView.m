//
//  IMWebView.m
//  IMWebView
//
//  Created by Ian Murray on 03-01-13.
//  Copyright (c) 2013 Ian Murray. All rights reserved.
//

#import "IMWebView.h"

#define CleanCallback() callback = (callback == nil ? ^(IMWebView *webView){} : callback);

/**
 Defines operation types to enqueue
 */
typedef enum
{
    IMWebViewOperationNavigate,
    IMWebViewOperationExecuteBlock,
    IMWebViewOperationRun
} IMWebViewOperation;

/**
 Defines the different form fields
 */
typedef enum
{
    IMWebViewInputTypeUnknown,
    IMWebViewInputTypeText,
    IMWebViewInputTypeTextarea,
    IMWebViewInputTypeCheckbox,
    IMWebViewInputTypeRadio,
    IMWebViewInputTypeSelect
} IMWebViewInputType;

@interface IMWebView () <UIWebViewDelegate>

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
        self.operationsQueue = [NSMutableArray array];
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

- (void)startWithURL:(NSURL *)url withCallback:(IMWebViewCallback)callback
{
    // Create an empty block in case we're passed nil.
    CleanCallback();
    
    [self enqueueOperation:IMWebViewOperationNavigate withOptions:@{@"url" : url, @"block" : [callback copy]}];
}

- (void)thenExecuteBlock:(IMWebViewCallback)callback
{
    CleanCallback();
    
    [self enqueueOperation:IMWebViewOperationExecuteBlock withOptions:@{@"block" : [callback copy]}];
}

- (void)runWithCallback:(IMWebViewCallback)callback
{
    // Create an empty block in case we're passed nil.
    CleanCallback();
    
    [self enqueueOperation:IMWebViewOperationRun withOptions:@{@"block" : [callback copy]}];
    
    NSDictionary *operation = self.operationsQueue[0];
    NSURLRequest *request = [NSURLRequest requestWithURL:operation[@"options"][@"url"]];
    [self.webView loadRequest:request]; 
}

- (void)goBack
{
    [self.webView goBack];
}

- (void)goForward
{
    [self.webView goForward];
}

#pragma mark - Public DOM Manipulation / Interaction Methods

- (BOOL)selectorExists:(NSString *)selector
{
    NSString *stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@').length", selector];
    NSString *response = [self.webView stringByEvaluatingJavaScriptFromString:stringToEvaluate];
    
    return response.integerValue > 0;
}

- (IMWebViewInputType)inputTypeForSelector:(NSString *)selector
{
    NSString *stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@')[0].tagName", selector];
    NSString *response = [self.webView stringByEvaluatingJavaScriptFromString:stringToEvaluate];
    
    if ([response caseInsensitiveCompare:@"input"] == NSOrderedSame)
    {
        // text input, checkbox or radio?
        stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@').first().attr('type')", selector];
        response = [self.webView stringByEvaluatingJavaScriptFromString:stringToEvaluate];
        
        if ([response caseInsensitiveCompare:@"text"] == NSOrderedSame ||
            [response caseInsensitiveCompare:@"password"] == NSOrderedSame ||
            [response caseInsensitiveCompare:@"email"] == NSOrderedSame ||
            [response caseInsensitiveCompare:@"number"] == NSOrderedSame)
        {
            return IMWebViewInputTypeText;
        }
        else if ([response caseInsensitiveCompare:@"checkbox"] == NSOrderedSame)
        {
            return IMWebViewInputTypeCheckbox;
        }
        else if ([response caseInsensitiveCompare:@"radio"] == NSOrderedSame)
        {
            return IMWebViewInputTypeRadio;
        }
        else
        {
            NSLog(@"Unkown input field: %@ (jquery: %@)", response, stringToEvaluate);
            return IMWebViewInputTypeUnknown;
        }
    }
    else if ([response caseInsensitiveCompare:@"select"] == NSOrderedSame)
    {
        return IMWebViewInputTypeSelect;
    }
    else if ([response caseInsensitiveCompare:@"textarea"] == NSOrderedSame)
    {
        return IMWebViewInputTypeTextarea;
    }
    else
    {
        return IMWebViewInputTypeUnknown;
    }
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

- (BOOL)clickElementWithSelector:(NSString *)selector andContent:(NSString *)content
{
    if ([self selectorExists:selector])
    {
        NSString *stringToEvaluate = [NSString stringWithFormat:@"$imWebViewJquery('%@').each(function(){if ($(this).text().match('%@') || $(this).val().match('%@')) $(this)[0].click(); });", selector, content, content];
        [self.webView stringByEvaluatingJavaScriptFromString:stringToEvaluate];
        
        return YES;
    }
    
    return NO;
}

- (void)clickElementWithContent:(NSString *)content
{
    [self clickElementWithSelector:@"a, button, input[type=button], input[type=submit]" andContent:content];
}

- (BOOL)fillFieldWithSelector:(NSString *)selector withValue:(NSString *)string
{
    if ([self selectorExists:selector])
    {
        // First, let's check what kind of field it is
        IMWebViewInputType inputType = [self inputTypeForSelector:selector];
        NSString *setValueStatement;
        
        switch (inputType)
        {
            case IMWebViewInputTypeText:
                setValueStatement = [NSString stringWithFormat:@"$imWebViewJquery('%@').val('%@');", selector, string];
                break;
            
            case IMWebViewInputTypeTextarea:
                setValueStatement = [NSString stringWithFormat:@"$imWebViewJquery('%@').html('%@')", selector, string];
                break;
                
            default:
                return NO;
                break;
        }
        
        NSAssert([self.webView stringByEvaluatingJavaScriptFromString:setValueStatement], @"stringByEvaluatingJavaScriptFromString (%@) failed", setValueStatement);
        return YES;
    }
    
    return NO;
}

- (BOOL)setCheckboxWithSelector:(NSString *)selector checked:(BOOL)checked
{
    if ([self selectorExists:selector] &&
        [self inputTypeForSelector:selector] == IMWebViewInputTypeCheckbox)
    {
        NSString *setCheckboxString = [NSString stringWithFormat:@"$imWebViewJquery('%@').first().attr('checked', %@')", selector, (checked ? @"true" : @"false")];
        NSAssert([self.webView stringByEvaluatingJavaScriptFromString:setCheckboxString], @"stringByEvaluatingJavaScriptFromString (%@) failed", setCheckboxString);

        return YES;
    }
    
    return NO;
}

- (BOOL)setSelectWithSelector:(NSString *)selector toValue:(NSString *)value
{
    if ([self selectorExists:selector] &&
        [self inputTypeForSelector:selector] == IMWebViewInputTypeSelect)
    {
        NSString *setSelectString = [NSString stringWithFormat:@"$imWebViewJquery('%@').first().val('%@')", selector, value];
        NSAssert([self.webView stringByEvaluatingJavaScriptFromString:setSelectString], @"stringByEvaluatingJavaScriptFromString (%@) failed", setSelectString);
        
        return YES;
    }
    
    return NO;
}

- (NSString *)getHTMLInSelector:(NSString *)selector
{
    NSString *selectorString = [NSString stringWithFormat:@"$imWebViewJquery('%@').html()", selector];
    return [self.webView stringByEvaluatingJavaScriptFromString:selectorString];
}

#pragma mark - Private DOM Manipulation / Interaction Methods

- (void)injectScriptWithName:(NSString *)name
{
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:name ofType:@"js"];
    NSAssert(scriptPath != nil, @"scriptPath %@.js should not have been nil", name);
    NSString *scriptToInject = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView stringByEvaluatingJavaScriptFromString:scriptToInject];
}

- (void)pollForState:(NSString *)state withCallback:(IMWebViewSimpleCallback)callback
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

- (void)injectJqueryWithCallBack:(IMWebViewSimpleCallback)callback
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

#pragma mark - UIWebView Delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"IMWebView failed loading %@ with error: %@", self.currentURL, error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"IMWebView finished loading %@", self.currentURL);
    [self injectJqueryWithCallBack:^{
        if (ASSERT_OPERATION_QUEUE_NOT_EMPTY)
            NSAssert1(self.operationsQueue.count > 0, @"The operation queue was empty when the web view navigated to %@.", self.currentURL);
        
        if (self.operationsQueue.count > 0)
        {
            // Execute the first operation on the queue
            NSDictionary *operation = self.operationsQueue[0];
            [self.operationsQueue removeObjectAtIndex:0];
            
            IMWebViewCallback callback = operation[@"options"][@"block"];
            callback(self);
        }
    }];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"IMWebView started loading");
}

@end
