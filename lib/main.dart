import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.subscribeToTopic('public_msg');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sarhaan',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: const ColorScheme.light()
            .copyWith(primary: const Color(0xFFf09b30)),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool progressLoading = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _setupInteractedMessage();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..loadRequest(Uri.parse('https://sarhaan.com'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _handleNavigationRequest,
        onPageStarted: (_) => setState(() => progressLoading = true),
        onPageFinished: (_) => setState(() => progressLoading = false),
      ));
  }

  Future<NavigationDecision> _handleNavigationRequest(
      NavigationRequest request) async {
    if (request.url.contains('.pdf')) {
      if (await Permission.storage.isGranted) {
        await _downloadFile(request.url);
        return NavigationDecision.prevent;
      } else {
        await Permission.storage.request();
      }
    }
    return NavigationDecision.navigate;
  }

  Future<void> _downloadFile(String url) async {
    FileDownloader.downloadFile(
        url:url
    );
  }

  Future<void> _setupInteractedMessage() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.denied) {
      await FirebaseMessaging.instance.getInitialMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFf09b30),
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_outlined),
          ),
          title: const Text('Sarhaan'),
          actions: [
            IconButton(
              onPressed: _controller.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: progressLoading
            ? const LoadingIndicator()
            : WebViewWidget(
                controller: _controller, layoutDirection: TextDirection.rtl),
      ),
    );
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LinearProgressIndicator(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.4),
        const CircularProgressIndicator(),
      ],
    );
  }
}
