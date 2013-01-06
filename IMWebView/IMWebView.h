//
//  IMWebView.h
//  IMWebView
//
//  Created by Ian Murray on 03-01-13.
//  Copyright (c) 2013 Ian Murray. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 When this is true, IMWebView will crash in case the internal
 web view navigated somewhere and there was no operation to perform.
 Useful for development, you should probably set this to 0 on production.
 */
#define ASSERT_OPERATION_QUEUE_NOT_EMPTY 1

@class IMWebView;

typedef void (^IMWebViewSimpleCallback)();
typedef void (^IMWebViewCallback)(IMWebView *webView);

@interface IMWebView : NSObject

@property (nonatomic,strong) UIWebView *webView;

/**
 Whether or not the web view is loading
 */
@property (nonatomic,readonly) BOOL loading;

/**
 The current URL of the web view
 */
@property (nonatomic,readonly) NSURL *currentURL;

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

/**
 Navigates forward if possible.
 */
- (void)goForward;

/**
 Navigates back if possible
 */
- (void)goBack;

/**
 Clicks the first element found using the given selector
 
 @param selector The selector of the element to click
 
 @return Whether the selector actually existed.
 */
- (BOOL)clickElementWithSelector:(NSString *)selector;

/**
 Clicks the first element found using the given selector and the specified content
 
 @param selector The selector of the element to click
 @param content The content the element should have
 
 @return Whether the selector actually existed.
 */
- (BOOL)clickElementWithSelector:(NSString *)selector andContent:(NSString *)content;

/**
 Click the first element that containts the specified content.
 
 For example, if there's a button with the content of "Login", you could call
 [imWebView clickElementWithContent:@"Login"] to click it.
 
 @param content The content the element should have
 */
- (void)clickElementWithContent:(NSString *)content;

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

/**
 Retrieves the content of the given selector on the current page.
 
 @param selector The selector to query
 
 @return The HTML content of the selector
 */
- (NSString *)getHTMLInSelector:(NSString *)selector;

@end
