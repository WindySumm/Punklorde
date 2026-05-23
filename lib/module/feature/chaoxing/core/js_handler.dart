import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChaoxingJSHandler {
  // ignore: unused_field
  final InAppWebViewController _controller;
  final Future<void> Function(String url)? onOpenUrl;

  ChaoxingJSHandler(this._controller, {this.onOpenUrl});

  Future<void> handle(String name, dynamic payload) async {
    try {
      switch (name) {
        case 'CLIENT_OPEN_URL':
          if (payload is Map) {
            await opOpenUrl(Map<String, dynamic>.from(payload)["webUrl"]);
          }
          break;
        default:
          await opOther(name, payload);
          break;
      }
    } catch (e) {
      print(e);
    }
  }

  /// Push 新路由打开 URL，而非在当前 WebView 内替换
  Future<void> opOpenUrl(String url) async {
    if (onOpenUrl != null) {
      await onOpenUrl!(url);
    }
  }

  Future<void> opOther(String name, dynamic payload) async {}
}
