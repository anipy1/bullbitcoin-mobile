import 'dart:convert';
import 'dart:io';

import 'package:bb_mobile/core/themes/app_theme.dart';
import 'package:bb_mobile/core/utils/constants.dart';
import 'package:bb_mobile/core/utils/logger.dart';
import 'package:bb_mobile/core/widgets/navbar/top_bar.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_bloc.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_event.dart';
import 'package:bb_mobile/features/bringin/presentation/bloc/bringin_sell_state.dart';
import 'package:bb_mobile/features/bringin/ui/bringin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class BringinSellWebviewScreen extends StatefulWidget {
  const BringinSellWebviewScreen({super.key});

  @override
  State<BringinSellWebviewScreen> createState() =>
      _BringinSellWebviewScreenState();
}

class _BringinSellWebviewScreenState extends State<BringinSellWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final bringinState = context.read<BringinSellBloc>().state;
    final apiKey = ApiServiceConstants.bringinApiKey;
    const host = 'dev-connect.bringin.xyz';

    // Build URL with pre-filled IBAN/BIC/name from the input form
    final queryParams = <String, String>{
      'apiKey': apiKey,
      'direction': 'CRYPTO_TO_FIAT',
    };

    // Pre-fill bank account details if entered in the native form
    if (bringinState.ibanInput.isNotEmpty) {
      queryParams['iban'] = bringinState.ibanInput;
    }
    if (bringinState.bicInput.isNotEmpty) {
      queryParams['bic'] = bringinState.bicInput;
    }
    if (bringinState.beneficiaryNameInput.isNotEmpty) {
      queryParams['beneficiaryName'] = bringinState.beneficiaryNameInput;
    }

    final uri = Uri.https(host, '/', queryParams);

    log.info('[Bringin Sell] Opening widget');
    log.info('[Bringin Sell] iban: ${bringinState.ibanInput}');
    log.info('[Bringin Sell] bic: ${bringinState.bicInput}');
    log.info('[Bringin Sell] beneficiaryName: ${bringinState.beneficiaryNameInput}');
    log.info('[Bringin Sell] URL: $uri');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'BringinBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBringinMessage(message.message, bringinState);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            log.info('[Bringin Sell] Page started: $url');
          },
          onPageFinished: (url) {
            log.info('[Bringin Sell] Page finished: $url');
            setState(() => _isLoading = false);
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
              '[Bringin Sell] HTTP error: ${error.response?.statusCode} '
              'url=${error.request?.uri}',
            );
          },
          onWebResourceError: (WebResourceError error) {
            log.severe(
              '[Bringin Sell] Web error: ${error.errorCode} '
              '${error.description} url=${error.url}',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.contains('bringin.xyz')) {
              return NavigationDecision.navigate;
            }
            log.warning('[Bringin Sell] Blocked navigation to: $url');
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

  void _handleBringinMessage(String rawMessage, BringinSellState initialState) {
    try {
      log.info('[Bringin Sell] Received message: $rawMessage');
      final event = jsonDecode(rawMessage) as Map<String, dynamic>;
      final type = event['type'] as String?;

      if (type == 'bringin:success') {
        final depositAddress = event['depositAddress'] as String?;
        final bringinLinkId = event['bringinLinkId'] as String?;
        // Use IBAN from event if available, otherwise from form input
        final iban = event['iban'] as String? ??
            (initialState.ibanInput.isNotEmpty ? initialState.ibanInput : null);

        log.info(
          '[Bringin Sell] Success! depositAddress=$depositAddress '
          'linkId=$bringinLinkId',
        );

        if (depositAddress != null && bringinLinkId != null) {
          context.read<BringinSellBloc>().add(
            BringinSellEvent.connectionCreated(
              depositAddress: depositAddress,
              bringinLinkId: bringinLinkId,
              walletId: '',
              iban: iban,
              bic: initialState.bicInput.isNotEmpty
                  ? initialState.bicInput
                  : null,
              beneficiaryName: initialState.beneficiaryNameInput.isNotEmpty
                  ? initialState.beneficiaryNameInput
                  : null,
            ),
          );
        }
      } else if (type == 'bringin:close') {
        log.info('[Bringin Sell] Widget closed by user');
        if (mounted) context.pop();
      } else if (type == 'bringin:error') {
        final error = event['error'] as String? ?? 'Unknown error';
        log.severe('[Bringin Sell] Widget error: $error');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      log.warning('[Bringin Sell] Failed to parse message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BringinSellBloc, BringinSellState>(
      listenWhen: (prev, curr) =>
          prev.selectedConnection == null && curr.selectedConnection != null,
      listener: (context, state) {
        context.goNamed(BringinRoute.bringinSellDashboard.name);
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
          flexibleSpace: TopBar(
            title: 'Sell Bitcoin for EUR',
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
