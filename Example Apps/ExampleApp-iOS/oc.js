
(function(){
var getCurrentUsrInfo = function(callback){
    var data = { 'id': '1', 'value': '123456'}
    window.WebViewJavascriptBridge.callHandler('getCurrentUsrInfoNative', data,callback);
}

var isValidURL=function(callback){
    var data = { 'id': '1', 'value': '123456'}
    window.WebViewJavascriptBridge.callHandler('isValidURLNative', data,callback);
}

var sendByDefault = function(callback){
    var data = 'Hello from JS button'
    window.WebViewJavascriptBridge.send(data, callback);
 }

var AppClient = {
    getCurrentUsrInfo:getCurrentUsrInfo,
    isValidURL:isValidURL,
    sendByDefault:sendByDefault
}
 window.AppClient = AppClient;
 }());


function testIfJSLoaded(){
    alert('恭喜,JS与OC可以正常通讯了');
}

function testMethodInvoked(){
    alert('testMethodInvoked');
}


var uniqueId = 1
function log(message, data) {
    var log = document.getElementById('log')
    var el = document.createElement('div')
    el.className = 'logLine'
    el.innerHTML = uniqueId++ + '. ' + message + ':<br/>' + JSON.stringify(data)
    if (log.children.length) { log.insertBefore(el, log.children[0]) }
    else { log.appendChild(el) }
}


function connectWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) {
        callback(WebViewJavascriptBridge)
    } else {
        document.addEventListener('WebViewJavascriptBridgeReady', function() {
                                  callback(WebViewJavascriptBridge)
                                  }, false)
    }
}
connectWebViewJavascriptBridge(function(bridge) {
                               bridge.init(function(message, responseCallback) {
                                           log('JS000000 ----- OC调用JS，来自OC的输入参数', message)
                                           var data = { '000000JS返回来的结果':'我来自JS!' }
                                           log('JS000000 ----- OC调用JS 用send方法 返回给OC的输出参数', data)
                                           responseCallback(data)
                                           })
                               
                               bridge.registerHandler('testJavascriptHandler', function(data, responseCallback) {
                                                      log('JS222222 ----- OC调用JS  用handle方法  来自OC的输入参数:', data)
                                                      var responseData = { 'JS222222 JS返回的字符串':'同步调用立马返回啦!' }
                                                      log('JS222222 ----- OC调用JS  用handle方法 JS返给OC的输出参数', responseData)
                                                      responseCallback(responseData)
                                                      })
                               })