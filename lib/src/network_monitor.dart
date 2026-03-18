import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a single network call with request and response data
class NetworkCall {
  final String id;
  final DateTime timestamp;
  final String method;
  final Uri url;
  final Map<String, dynamic> requestHeaders;
  final String? requestBody;

  int? statusCode;
  String? responseBody;
  Map<String, dynamic>? responseHeaders;
  Duration? duration;
  String? error;
  bool isCompleted;

  NetworkCall({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.responseHeaders,
    this.duration,
    this.error,
    this.isCompleted = false,
  });

  String get displayUrl {
    final path = url.path.isEmpty ? '/' : url.path;
    return '${url.host}$path';
  }

  String get statusDisplay {
    if (error != null) return 'ERROR';
    if (!isCompleted) return 'PENDING...';
    return statusCode?.toString() ?? 'UNKNOWN';
  }

  String get durationDisplay {
    if (duration == null) return '-';
    final ms = duration!.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }
}

/// Network monitoring service that tracks HTTP calls
class NetworkMonitor extends ChangeNotifier {
  final List<NetworkCall> _calls = [];
  static NetworkMonitor? _instance;

  static NetworkMonitor get instance {
    _instance ??= NetworkMonitor._();
    return _instance!;
  }

  NetworkMonitor._();

  List<NetworkCall> get calls => List.unmodifiable(_calls);

  void addCall(NetworkCall call) {
    _calls.insert(0, call); 
    if (_calls.length > 50) {
      _calls.removeLast(); 
    }
    notifyListeners();
  }

  void updateCall(String id, {
    int? statusCode,
    String? responseBody,
    Map<String, dynamic>? responseHeaders,
    Duration? duration,
    String? error,
    bool? isCompleted,
  }) {
    final index = _calls.indexWhere((call) => call.id == id);
    if (index != -1) {
      final call = _calls[index];
      if (statusCode != null) call.statusCode = statusCode;
      if (responseBody != null) call.responseBody = responseBody;
      if (responseHeaders != null) call.responseHeaders = responseHeaders;
      if (duration != null) call.duration = duration;
      if (error != null) call.error = error;
      if (isCompleted != null) call.isCompleted = isCompleted;
      notifyListeners();
    }
  }

  void clear() {
    _calls.clear();
    notifyListeners();
  }
}

/// Custom HTTP client that wraps requests for monitoring
class MonitoredHttpClient implements HttpClient {
  final HttpClient _inner;
  final NetworkMonitor _monitor = NetworkMonitor.instance;

  MonitoredHttpClient(this._inner);

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) async {
    final request = await _inner.open(method, host, port, path);
    return _wrapRequest(request, method);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return _wrapRequest(request, method);
  }

  HttpClientRequest _wrapRequest(HttpClientRequest request, String method) {
    return MonitoredHttpClientRequest(request, method, _monitor);
  }

  // Delegate all other methods to inner client
  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) =>
      _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  set connectionFactory(
          Future<ConnectionTask<Socket>> Function(
                  Uri url, String? proxyHost, int? proxyPort)?
              f) =>
      _inner.connectionFactory = f;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
          String host, int port, String realm, HttpClientCredentials credentials) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _inner.authenticate = f;

  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _inner.authenticateProxy = f;

  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)?
              callback) =>
      _inner.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
}

/// Wrapped HTTP request that monitors the call
class MonitoredHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final String _method;
  final NetworkMonitor _monitor;
  late final String _callId;
  late final DateTime _startTime;

  MonitoredHttpClientRequest(this._inner, this._method, this._monitor) {
    _callId = DateTime.now().millisecondsSinceEpoch.toString();
    _startTime = DateTime.now();
  }

  @override
  Future<HttpClientResponse> close() async {
    // Create network call entry
    final call = NetworkCall(
      id: _callId,
      timestamp: _startTime,
      method: _method,
      url: _inner.uri,
      requestHeaders: Map.fromEntries(
        _inner.headers
            .toString()
            .split('\n')
            .where((line) => line.contains(':'))
            .map((line) {
          final parts = line.split(':');
          return MapEntry(parts[0].trim(), parts.sublist(1).join(':').trim());
        }),
      ),
    );
    _monitor.addCall(call);

    try {
      final response = await _inner.close();
      final wrappedResponse = MonitoredHttpClientResponse(
        response,
        _callId,
        _startTime,
        _monitor,
      );
      return wrappedResponse;
    } catch (e) {
      _monitor.updateCall(
        _callId,
        error: e.toString(),
        isCompleted: true,
        duration: DateTime.now().difference(_startTime),
      );
      rethrow;
    }
  }

  // Delegate all other methods
  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<HttpClientResponse> get done => _inner.done;

  @override
  Future flush() => _inner.flush();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  void write(Object? object) => _inner.write(object);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => _inner.writeln(object);

  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  int get contentLength => _inner.contentLength;

  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;
}

/// Wrapped HTTP response that captures response data
class MonitoredHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final HttpClientResponse _inner;
  final String _callId;
  final DateTime _startTime;
  final NetworkMonitor _monitor;
  final List<int> _responseBytes = [];

  MonitoredHttpClientResponse(
      this._inner, this._callId, this._startTime, this._monitor) {
    // Update with initial response data
    _monitor.updateCall(
      _callId,
      statusCode: _inner.statusCode,
      responseHeaders: _extractHeaders(_inner.headers),
    );
  }

  Map<String, dynamic> _extractHeaders(HttpHeaders headers) {
    final map = <String, dynamic>{};
    headers.forEach((name, values) {
      map[name] = values.join(', ');
    });
    return map;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner.listen(
      (data) {
        // Capture response data
        _responseBytes.addAll(data);
        // Pass through to app
        onData?.call(data);
      },
      onError: (error) {
        _monitor.updateCall(
          _callId,
          error: error.toString(),
          isCompleted: true,
          duration: DateTime.now().difference(_startTime),
        );
        onError?.call(error);
      },
      onDone: () {
        // Decode and store response body
        try {
          final responseBody = utf8.decode(_responseBytes);
          _monitor.updateCall(
            _callId,
            responseBody: responseBody,
            duration: DateTime.now().difference(_startTime),
            isCompleted: true,
          );
        } catch (e) {
          // If decode fails, store raw bytes as string
          _monitor.updateCall(
            _callId,
            responseBody: '<Binary data: ${_responseBytes.length} bytes>',
            duration: DateTime.now().difference(_startTime),
            isCompleted: true,
          );
        }
        onDone?.call();
      },
      cancelOnError: cancelOnError,
    );
  }

  // Delegate all other methods
  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      _inner.redirect(method, url, followLoops);

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;

  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;
}

/// HTTP overrides to enable network monitoring
class NetworkMonitorHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MonitoredHttpClient(super.createHttpClient(context));
  }
}
