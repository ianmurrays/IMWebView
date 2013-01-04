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

@property (nonatomic,strong) UIWebView *webView;
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

/**
 Fills a textfield or textarea with the given text.
 
 @param selector The field's selector
 @param string The value to set on the field
 
 @return Whether or not the value was set. It returns NO for invalid selectors or if a field is not a text or textarea.
 */
- (BOOL)fillFieldWithSelector:(NSString *)selector withValue:(NSString *)string;

/**
 Sets a checkbox to the specified state (checked or not checked).
 
 @param selector The checkbox' selector
 @param checked Checked or not checked
 
 @return Whether the checkbox was actually changed.
 */
- (BOOL)setCheckboxWithSelector:(NSString *)selector checked:(BOOL)checked;

/**
 Sets a select tag to the given value. For example, if there's a select like this:
 
 <select class="the-select">
    <option value="first">First Value!</option>
    <option value="second">Second Value!</option>
 </select>
 
 Calling setSelectWithSelector with value "second" will select the second option.
 If the option does not have the value tag set, then the content becomes its value.
 
 Fiddle with this jsfiddle (pun intended) to test that out: http://jsfiddle.net/nick_craver/RB5wU/
 
 @param selector The select's selector
 @param value The value of the option to set
 
 @return Whether or not the select was actually performed.
 */
- (BOOL)setSelectWithSelector:(NSString *)selector toValue:(NSString *)value;

- (BOOL)fillFormWithSelector:(NSString *)selector options:(NSDictionary *)options submit:(BOOL)submit;

- (NSString *)getHTMLInSelector:(NSString *)selector;

@end
