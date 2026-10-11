import 'dart:async';
import 'package:flutter/services.dart';

/// Servicio ligero y unificado para capturar deep links entrantes.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static const MethodChannel _methodChannel =
      MethodChannel('com.example.mi_app/deeplink/method');
  static const EventChannel _eventChannel =
      EventChannel('com.example.mi_app/deeplink/events');

  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  StreamSubscription<dynamic>? _nativeSubscription;
  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    try {
      _nativeSubscription = _eventChannel
          .receiveBroadcastStream()
          .where((event) => event != null)
          .listen(
        (event) {
          try {
            final uri = Uri.parse(event.toString());
            _controller.add(uri);
          } catch (_) {}
        },
        onError: (err) {
          _controller.addError(err);
        },
      );
    } catch (_) {}
  }

  /// Flujo continuo de deep links recibidos por la aplicación.
  Stream<Uri> get uriLinkStream {
    _ensureInitialized();
    return _controller.stream;
  }

  /// Inyecta manualmente una URI recibida (por ejemplo, interceptada por el enrutador de Flutter).
  void handleIncomingUri(Uri uri) {
    _controller.add(uri);
  }

  /// Obtiene el deep link inicial con el que se abrió la aplicación, si existe.
  Future<Uri?> getInitialUri() async {
    try {
      final initialString =
          await _methodChannel.invokeMethod<String>('getInitialLink');
      if (initialString != null && initialString.isNotEmpty) {
        return Uri.parse(initialString);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _nativeSubscription?.cancel();
    _controller.close();
  }
}

