//
//  IMWebView.h
//  IMWebView
//
//  Created by Ian Murray on 03-01-13.
//  Copyright (c) 2013 Ian Murray. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^IMWebViewCallback)();

@interface IMWebView : NSObject

@property (nonatomic,readonly) BOOL loading;
@property (nonatomic,readonly) NSURL *currentURL;

/**
 Navigates to the specified URL.
 
 @param url The url to navigate to
 @param callback Block to be invoked when the page is ready to be interacted with.
 */
- (void)goToURL:(NSURL *)url withCallback:(IMWebViewCallback)callback DEPRECATED_ATTRIBUTE;

// TODO: Document these methods!

/**
 Starts a new request and calls the callback when the request is done.
 
 @param url The url from where to start
 @param callback The callback to invoke when the DOM is ready.
 */
- (void)startWithURL:(NSURL *)url withCallback:(IMWebViewCallback)callback;

/**
 You can call this consecutively to enqueue operations. You should call this
 after having performed an operation that makes the internal web view load another
 site.
 
 @param callback The callback to invoke when the DOM is ready.
 */
- (void)thenExecuteBlock:(IMWebViewCallback)callback;

/**
 Call this when all your operations have been enqueued. This will
 run them all and call the callback when finished.
 
 @param callback Invoked when all operations have finished executing.
 */
- (void)runWithCallback:(IMWebViewCallback)callback;


- (void)goForward;
- (void)goBack;
- (BOOL)clickElementWithSelector:(NSString *)selector;
//- (BOOL)clickLabel:(NSString *)label;
//- (BOOL)clickLabel:(NSString *)label withTag:(NSString *)tag;
- (BOOL)fillFieldWithSelector:(NSString *)selector withValue:(NSString *)string;
- (BOOL)fillFormWithSelector:(NSString *)selector options:(NSDictionary *)options submit:(BOOL)submit;
- (NSString *)getHTMLInSelector:(NSString *)selector;

@end
