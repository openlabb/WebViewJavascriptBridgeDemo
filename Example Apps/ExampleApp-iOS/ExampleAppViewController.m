//
//  ExampleAppViewController.m
//  ExampleApp-iOS
//
//  Created by Marcus Westin on 1/13/14.
//  Copyright (c) 2014 Marcus Westin. All rights reserved.
//

//Modified by Openlab openlib@126.com 2015-05-19
#import "ExampleAppViewController.h"
#import "WebViewJavascriptBridge.h"
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ExampleAppViewController(){
}
@property (strong, nonatomic) UIWebView *webView;
@end
@interface ExampleAppViewController ()<UIWebViewDelegate>
@property WebViewJavascriptBridge* bridge;
@end

@implementation ExampleAppViewController
- (void)viewDidLoad{
    self.title = @"OC与JS相互调用的例子";
    [super viewDidLoad];
    CGRect rect = [UIScreen mainScreen].bounds;
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectInset(rect, 0, 40)];
    webView.delegate = self;
    [self.view addSubview:webView];
    self.webView = webView;
    [self renderButtons:self.webView];

}

- (void)renderButtons:(UIWebView*)webView {
    
    int h = kScreenHeight - 40;
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    UIButton *messageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [messageButton setTitle:@"OC调用JS" forState:UIControlStateNormal];
    [messageButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:messageButton aboveSubview:webView];
    messageButton.frame = CGRectMake(0, h, 70, 35);
    messageButton.titleLabel.font = font;
    messageButton.backgroundColor =[UIColor blueColor];
    [messageButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"OC调用JS中的testJavascriptHandler方法" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(72, h, 222, 35);
    [callbackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    callbackButton.titleLabel.font = font;
        callbackButton.backgroundColor =[UIColor blueColor];
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"清除" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.backgroundColor =[UIColor blueColor];
    [reloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    reloadButton.frame = CGRectMake(295, h, 25, 35);
    reloadButton.titleLabel.font = font;
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadBridgeSample];
}


#pragma mark ---OC调用JS
- (void)sendMessage:(id)sender {
    [_bridge send:@"我是输入参数 －OC调用JS" responseCallback:^(id response) {
        NSLog(@"OC调用后 从JS返回值: %@", response);
    }];
}

- (void)callHandler:(id)sender {
    id data = @{ @"来自OC": @"JS你好，我是OC!" };
    [_bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"OC调用JS的testJavascriptHandler函数值返回: %@", response);
    }];
}

#pragma mark --初始化bridge
- (void)loadBridgeSample {
    if (_bridge) { return; }
    
    [WebViewJavascriptBridge enableLogging];
    
    //JS调用OC send方法时的默认回调
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"OCAAAAAA ==== JS调用OC send方法: %@", data);
        responseCallback(@"OCAAAAAA ==== ObjC 返回信息给JS");
    }];
    
    //JS调用OC用 要暴露给js的方法getCurrentUsrInfoNative注册
    [_bridge registerHandler:@"getCurrentUsrInfoNative" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"OCBBBBBB ==== JS调用OC --callHandle方法--getCurrentUsrInfoNative called: %@", data);
        NSString *retString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{ @"从OC取到的当前用户":@"openlab" } options:0 error:nil] encoding:NSUTF8StringEncoding];
        responseCallback(retString);
        NSLog(@"OCBBBBBB ====  JS调用OC ---callHandle方法-- getCurrentUsrInfoNative 返回值: %@", retString);
    }];
    
    [self loadWithLocalHtmlFileName:@"cccccc" ToWebView:self.webView];
    //    [self loadWithRemoteHtmlWithURL:@"http://openlab.net3v.net/11.html" toWebView:self.webView];
    //    [self loadWithRemoteURL:@"http://openlab.net3v.net/11.html"  ToWebView:self.webView];
    
}


#pragma mark--- webview加载事件
- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");
    
    [self injectJSCodeFromLocalJSFile:webView];
////    [self injectJSWithLocalFile:webView];
//
    [webView stringByEvaluatingJavaScriptFromString:@"testIfJSLoaded();"];
    return ;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    [self injectJSCodeFromLocalJSFile:webView];
//    [self injectJSWithLocalFile:webView];
//    [webView stringByEvaluatingJavaScriptFromString:@"testIfJSLoaded();"];
    return true;
}


#pragma mark ---加载html
//1,从本地加载
//2,远程加载－－－两种（1）url直接请求，（1）下载完html字符串加载

/**
 *  加载html的字符串内容到UIWebView,先把远程的html字符串内容down下来
 *
 *  @param url     url字符串
 *  @param webView
 */
- (void)loadWithRemoteHtmlWithURL:(NSString *)url toWebView:(UIWebView *)webView{
//    //先把整个html文件下载下来
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
////    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
//    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
////    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
////    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//
//    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject: @"text/html"];
////@"http://openlab.net3v.net/11.html"
////    @"https://www.e10066.com/shop/view/id/157"
//    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        [self loadWithHtmlString:[operation responseString] ToWebView:webView];
//    
//        NSLog(@"JSON: %@", responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
}

/**
 *  加载本地文件到UIWebView
 *
 *  @param fileName 本地文件名，需要放在mainBundle路径
 *  @param webView
 */
- (void)loadWithLocalHtmlFileName:(NSString *)fileName ToWebView:(UIWebView *)webView{
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

/**
 *  加载html字符串到UIWebView
 *
 *  @param html    html字符串
 *  @param webView
 */
- (void)loadWithHtmlString:(NSString *)html ToWebView:(UIWebView *)webView{
    NSURL *baseURL = [NSURL URLWithString:@"http://openlab.net3v.net/"];
    //baseURL需要更改
    //如果是本地，那么是本地html所在文件夹路径
    //如果是远程，那么是远程服务器地址

    [webView loadHTMLString:html baseURL:baseURL];
}

/**
 *  加载网页内容到UIWebView
 *
 *  @param url     网页地址 如：
 http://openlab.net3v.net/11.html
 https://www.e10066.com/shop/view/id/157
 *  @param webView
 */
- (void)loadWithRemoteURL:(NSString *)url ToWebView:(UIWebView *)webView{
     //url ＝ @"https://www.e10066.com/shop/view/id/157"；
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [webView loadRequest:request];
}

#pragma mark --注入JS
//1,代码注入
//2,文件注入

//从本地加载js文件的代码打散加到html中
- (void)injectJSCodeFromLocalJSFile:(UIWebView *)webView{
    BOOL isJSSupported = [self jsSupported];
    if (isJSSupported == YES) {
        return;
    }
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:@"oc" ofType:@"js"];
    NSString *jsstring = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
   // NSLog(@"打印出来看看js什么样%@",jsstring);
    jsstring = [self filterString:jsstring];
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var script = document.createElement('script');\
    script.type = 'text/javascript';\
    script.appendChild(document.createTextNode(\"%@\"));\
    document.body.appendChild(script);",jsstring]];
}

//从本地加载js文件引入html中
- (void)injectJSWithLocalFile:(UIWebView *)webView{
    NSString *jsFileName = @"http://openlab.net3v.net/oc.js";
    jsFileName = @"oc.js";
    NSString *jsInjection = [NSString stringWithFormat:@"var headElement = document.getElementsByTagName('head')[0]; var script = document.createElement('script'); script.setAttribute('src','%@'); script.setAttribute('type','text/javascript'); headElement.appendChild(script);",jsFileName];;
    jsInjection = [self filterString:jsInjection];
//    [self injectJSCodeAndPerform:jsInjection toWebView:webView];
    [webView stringByEvaluatingJavaScriptFromString:jsInjection];
    [self jsSupported];
}


- (void)injectJSCodeAndPerform:(NSString *)code toWebView:(UIWebView *)webView{
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var script = document.createElement('script');"
     "script.type = 'text/javascript';"
     "script.text = \"function myFunction() { "
     "%@"
     "}\";"
     "document.getElementsByTagName('head')[0].appendChild(script);",code]];
    [webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];
}

/**
 *  判断JS是否注入
 *
 *  @return
 */
-(BOOL) jsSupported {
    UIWebView *theWebView = self.webView;
    NSString *html = [theWebView stringByEvaluatingJavaScriptFromString: @"document.documentElement.innerHTML"];
    NSLog(@"打印出来看看js是否被注入 %@",html);
    BOOL isJSSupported = [html rangeOfString:@"oc.js"].location != NSNotFound;
    if (isJSSupported == NO) {
        isJSSupported = [html rangeOfString:@"WebViewJavascriptBridgeReady"].location != NSNotFound;
    }
    return isJSSupported;
}

//JS代码转义
- (NSString *)filterString:(NSString *)str{
    str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    str = [str stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    str = [str stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    str = [str stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    str = [str stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    return str;
}

@end
