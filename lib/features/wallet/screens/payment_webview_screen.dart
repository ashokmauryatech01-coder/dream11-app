import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderNo;
  final double amount;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderNo,
    required this.amount,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('PaymentWebViewScreen: initState called, creating WebViewController...');
    debugPrint('PaymentWebViewScreen: Loading URL: ${widget.paymentUrl}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            debugPrint('Payment WebView - Page started: $url');
            
            // Inject JavaScript IMMEDIATELY when page starts loading
            // This catches early redirects before onPageFinished
            _controller.runJavaScript('''
              console.log('DEBUG: Page starting: ' + location.href);
              
              // Immediate override of window.open
              if (window.open !== window.__originalOpen) {
                window.__originalOpen = window.open;
                window.open = function(url, target, features) {
                  console.log('DEBUG: BLOCKED window.open: ' + url);
                  if (url && typeof url === 'string' && (url.startsWith('http://') || url.startsWith('https://'))) {
                    window.location.href = url;
                    return window;
                  }
                  return null;
                };
              }
            ''');
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            debugPrint('Payment WebView - Page finished: $url');
            
            // Set up console message logging
            _controller.setOnConsoleMessage((JavaScriptConsoleMessage message) {
              debugPrint('Payment WebView Console [${message.level.name}]: ${message.message}');
            });
            
            // Inject comprehensive JavaScript to prevent ANY external navigation
            _controller.runJavaScript('''
              (function() {
                'use strict';
                
                // Store original methods
                var originalOpen = window.open;
                var originalAssign = window.location.assign;
                var originalReplace = window.location.replace;
                
                // Override window.open completely
                window.open = function(url, target, features) {
                  console.log('BLOCKED window.open: ' + url);
                  if (url && typeof url === 'string') {
                    // Only allow http/https URLs, stay in WebView
                    if (url.startsWith('http://') || url.startsWith('https://')) {
                      window.location.href = url;
                    }
                  }
                  return null;
                };
                
                // Override location methods
                window.location.assign = function(url) {
                  console.log('BLOCKED location.assign: ' + url);
                  if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
                    window.location.href = url;
                  }
                };
                
                window.location.replace = function(url) {
                  console.log('BLOCKED location.replace: ' + url);
                  if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
                    window.location.href = url;
                  }
                };
                
                // Intercept all link clicks
                document.addEventListener('click', function(e) {
                  var target = e.target;
                  var depth = 0;
                  while (target && target.tagName !== 'A' && depth < 10) {
                    target = target.parentElement;
                    depth++;
                  }
                  
                  if (target && target.tagName === 'A') {
                    var href = target.getAttribute('href') || '';
                    var targetAttr = target.getAttribute('target') || '';
                    
                    console.log('Link clicked: href=' + href + ', target=' + targetAttr);
                    
                    // Block external links and _blank targets
                    if (targetAttr === '_blank' || targetAttr === '_new') {
                      e.preventDefault();
                      e.stopPropagation();
                      console.log('BLOCKED external link (target): ' + href);
                      if (href.startsWith('http://') || href.startsWith('https://')) {
                        window.location.href = href;
                      }
                      return false;
                    }
                    
                    // Block intent:// and other external schemes
                    if (href.startsWith('intent://') || href.startsWith('upi://') || 
                        href.startsWith('tel://') || href.startsWith('mailto:')) {
                      e.preventDefault();
                      e.stopPropagation();
                      console.log('BLOCKED external scheme: ' + href);
                      return false;
                    }
                  }
                }, true);
                
                // Override form submissions that might open new windows
                document.addEventListener('submit', function(e) {
                  var form = e.target;
                  if (form && form.tagName === 'FORM') {
                    var target = form.getAttribute('target');
                    if (target === '_blank' || target === '_new') {
                      form.setAttribute('target', '_self');
                      console.log('Changed form target from ' + target + ' to _self');
                    }
                  }
                }, true);
                
                console.log('Payment WebView - All external navigation BLOCKED');
              })();
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Payment WebView - Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Payment WebView - Navigation: ${request.url}');
            
            // Keep all navigation within the WebView (in-app)
            final url = request.url.toLowerCase();
            
            // Block any intent:// URLs that try to open external apps
            if (url.startsWith('intent://') || url.startsWith('upi://')) {
              debugPrint('Payment WebView - Blocking external intent: $url');
              // Try to handle UPI intent within WebView by converting to https
              return NavigationDecision.prevent;
            }
            
            // Allow all payment-related URLs in WebView
            debugPrint('Payment WebView - Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        debugPrint('Payment WebView Console [${message.level.name}]: ${message.message}');
      })
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PaymentWebViewScreen: build() called - rendering WebView');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Order: ${widget.orderNo}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(
            controller: _controller,
          ),
          
          // Loading indicator
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading payment page... ${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
