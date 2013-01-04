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
- (void)goToURL:(NSURL *)url withCallback:(IMWebViewCallback)callback;

// TODO: Document these methods!
- (void)goForwardWithCallback:(IMWebViewCallback)callback;
- (void)goBackWithCallback:(IMWebViewCallback)callback;
- (void)stop;
- (void)reloadWithCallback:(IMWebViewCallback)callback;
- (BOOL)clickElementWithSelector:(NSString *)selector withCallback:(IMWebViewCallback)callback;
- (BOOL)clickLabel:(NSString *)label withCallback:(IMWebViewCallback)callback;
- (BOOL)clickLabel:(NSString *)label withTag:(NSString *)tag withCallback:(IMWebViewCallback)callback;
- (BOOL)fillFieldWithSelector:(NSString *)selector withValue:(NSString *)string;
- (BOOL)fillFormWithSelector:(NSString *)selector options:(NSDictionary *)options submit:(BOOL)submit withCallback:(IMWebViewCallback)callback;
- (NSString *)getHTMLInSelector:(NSString *)selector;

@end
