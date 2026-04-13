import 'dart:convert';
import 'dart:io';

import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/utils/constants.dart';
import 'package:bb_mobile/core/utils/logger.dart';
import 'package:bb_mobile/core/widgets/navbar/top_bar.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_state.dart';
import 'package:bb_mobile/features/bringin/ui/bringin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class BringinWebviewScreen extends StatefulWidget {
  const BringinWebviewScreen({super.key});

  @override
  State<BringinWebviewScreen> createState() => _BringinWebviewScreenState();
}

class _BringinWebviewScreenState extends State<BringinWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final bringinState = context.read<BringinBloc>().state;
    final btcAddress = bringinState.btcAddress;
    final walletSignature = bringinState.walletSignature;
    final walletId = bringinState.walletId ?? '';

    final apiKey = ApiServiceConstants.bringinApiKey;

    // Build URL — matching exactly what Bringin dev showed
    // TODO: switch to production URL when ready
    // final host = isTestnet ? 'dev-connect.bringin.xyz' : 'connect.bringin.xyz';
    const host = 'dev-connect.bringin.xyz';

    final Uri uri;
    if (btcAddress != null && walletSignature != null) {
      // Mode 3a: pre-fill address with BIP-137 wallet signature
      uri = Uri.https(host, '/', {
        'apiKey': apiKey,
        'direction': 'FIAT_TO_CRYPTO',
        'btcAddress': btcAddress,
        'currency': 'BTC',
        'network': 'BTC',
        'walletSignature': walletSignature,
      });
      log.info('[Bringin] Opening widget (Mode 3a — wallet signature)');
    } else {
      // Mode 1: user enters address in widget
      uri = Uri.https(host, '/', {
        'apiKey': apiKey,
        'direction': 'FIAT_TO_CRYPTO',
      });
      log.info('[Bringin] Opening widget (Mode 1 — no signing)');
    }

    log.info('[Bringin] btcAddress: $btcAddress');
    log.info('[Bringin] walletSignature: $walletSignature');
    log.info('[Bringin] Full URL: $uri');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'BringinBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBringinMessage(message.message, btcAddress ?? '', walletId);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            log.info('[Bringin] Page started: $url');
          },
          onPageFinished: (url) {
            log.info('[Bringin] Page finished: $url');
            setState(() => _isLoading = false);
            // Inject JS bridge to forward postMessage events to the Flutter channel
            _controller.runJavaScript('''
              (function() {
                window.addEventListener('message', function(event) {
                  if (event.data && typeof event.data === 'object') {
                    var type = event.data.type;
                    if (type === 'bringin:success' ||
                        type === 'bringin:close' ||
                        type === 'bringin:error') {
                      BringinBridge.postMessage(JSON.stringify(event.data));
                    }
                  }
                });
              })();
            ''');
          },
          onHttpError: (HttpResponseError error) {
            log.severe(
              '[Bringin] HTTP error: ${error.response?.statusCode} '
              'url=${error.request?.uri}',
            );
          },
          onWebResourceError: (WebResourceError error) {
            log.severe(
              '[Bringin] Web error: ${error.errorCode} '
              '${error.description} url=${error.url}',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.contains('bringin.xyz')) {
              return NavigationDecision.navigate;
            }
            log.warning('[Bringin] Blocked navigation to: $url');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 '
        'Mobile/15.0 Safari/604.1',
      )
      ..loadRequest(uri);

    if (Platform.isAndroid) {
      AndroidWebViewController.enableDebugging(false);
      final platformController = _controller.platform;
      if (platformController is AndroidWebViewController) {
        platformController.setMediaPlaybackRequiresUserGesture(false);
      }
    } else if (Platform.isIOS) {
      final platformController = _controller.platform;
      if (platformController is WebKitWebViewController) {
        platformController.setAllowsBackForwardNavigationGestures(true);
      }
    }
  }

  void _handleBringinMessage(
    String rawMessage,
    String btcAddress,
    String walletId,
  ) {
    try {
      log.info('[Bringin] Received message: $rawMessage');
      final event = jsonDecode(rawMessage) as Map<String, dynamic>;
      final type = event['type'] as String?;

      if (type == 'bringin:success') {
        final depositIban = event['depositIban'] as String?;
        final bringinLinkId = event['bringinLinkId'] as String?;
        final eventBtcAddress = event['btcAddress'] as String? ?? btcAddress;

        log.info('[Bringin] Success! IBAN=$depositIban linkId=$bringinLinkId');

        if (depositIban != null && bringinLinkId != null) {
          context.read<BringinBloc>().add(
            BringinEvent.connectionCreated(
              depositIban: depositIban,
              bringinLinkId: bringinLinkId,
              btcAddress: eventBtcAddress,
              walletId: walletId,
            ),
          );
        }
      } else if (type == 'bringin:close') {
        log.info('[Bringin] Widget closed by user');
        if (mounted) context.pop();
      } else if (type == 'bringin:error') {
        final error = event['error'] as String? ?? 'Unknown error';
        log.severe('[Bringin] Widget error: $error');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      log.warning('[Bringin] Failed to parse message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BringinBloc, BringinState>(
      listenWhen: (prev, curr) =>
          prev.connection == null && curr.connection != null,
      listener: (context, state) {
        context.goNamed(BringinRoute.bringinDashboard.name);
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
          flexibleSpace: TopBar(
            title: 'Buy Bitcoin with EUR',
            onBack: () => context.pop(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
