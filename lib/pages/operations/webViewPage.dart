 import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Webviewpage extends StatefulWidget {
  const Webviewpage({super.key});

  @override
  State<Webviewpage> createState() => _WebviewpageState();
}

class _WebviewpageState extends State<Webviewpage> {
  WebViewController? controller;
   var loadingPercentage = 0;

@override
 void initState() {
    super.initState();
    //  controller = WebViewController()
    //   ..loadRequest(
    //     Uri.parse('https://gtinfiniti.com/linkpages?companyid=99883345&linkid=354'),
    //   );
       controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            loadingPercentage = 0;
          });
        },
        onProgress: (progress) {
          setState(() {
            loadingPercentage = progress;
          });
        },
        onPageFinished: (url) {
          setState(() {
            loadingPercentage = 100;
          });
        },
      ))
      // ..loadRequest(
      //   Uri.parse('https://flutter.dev'),
      // );
      ..loadRequest(
        Uri.parse('https://gtinfiniti.com/linkpages?companyid=99883345&linkid=354'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("WebView Page"),
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller!,
          ),
          loadingPercentage < 100
              ? LinearProgressIndicator(
                  color: Colors.red,
                  value: loadingPercentage / 100.0,
                )
              : Container()
        ],
      ),
    );
  }
}