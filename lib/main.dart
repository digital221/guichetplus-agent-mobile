import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const _agentUrl = 'https://gplus.digitalfactory.sn/login-counter';
const _allowedHost = 'gplus.digitalfactory.sn';
const _brand = Color(0xFF078D87);
const _ink = Color(0xFF0F2A31);
const _permissions = MethodChannel(
  'sn.digitalfactory.guichetplus.agent/permissions',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuichetPlusAgentApp());
}

class GuichetPlusAgentApp extends StatelessWidget {
  const GuichetPlusAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guichet+ Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _brand),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AgentPortalScreen(),
    );
  }
}

class AgentPortalScreen extends StatefulWidget {
  const AgentPortalScreen({super.key});

  @override
  State<AgentPortalScreen> createState() => _AgentPortalScreenState();
}

class _AgentPortalScreenState extends State<AgentPortalScreen> {
  late final WebViewController _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _progress = 0;
  bool _offline = false;
  bool _mainFrameFailed = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress:
                  (value) => mounted ? setState(() => _progress = value) : null,
              onPageStarted: (_) {
                if (mounted) setState(() => _mainFrameFailed = false);
              },
              onPageFinished: (_) {
                if (mounted) setState(() => _progress = 100);
              },
              onWebResourceError: (error) {
                if (error.isForMainFrame == true && mounted) {
                  setState(() => _mainFrameFailed = true);
                }
              },
              onNavigationRequest: _handleNavigation,
            ),
          )
          ..loadRequest(Uri.parse(_agentUrl));

    if (Platform.isAndroid &&
        _controller.platform is AndroidWebViewController) {
      final android = _controller.platform as AndroidWebViewController;
      android
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setOnPlatformPermissionRequest((request) async {
          final granted =
              await _permissions.invokeMethod<bool>('requestCamera') ?? false;
          if (granted) {
            await request.grant();
          } else {
            await request.deny();
          }
        });
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final offline =
          results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none);
      if (!mounted) return;
      final wasOffline = _offline;
      setState(() => _offline = offline);
      if (wasOffline && !offline) _controller.reload();
    });
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == _allowedHost) {
      return NavigationDecision.navigate;
    }
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _handleBack() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: _controller)),
              if (_progress < 100)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    color: _brand,
                    backgroundColor: const Color(0xFFE5F2F1),
                  ),
                ),
              if (_offline || _mainFrameFailed)
                _ConnectionOverlay(onRetry: _controller.reload),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionOverlay extends StatelessWidget {
  const _ConnectionOverlay({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F6F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 38,
                    color: _brand,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Connexion indisponible',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vérifiez Internet puis réessayez. Votre session agent sera conservée.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Color(0xFF607076),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Réessayer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
