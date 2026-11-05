import 'package:admob_flutter_plus/admob_flutter_plus.dart';
import 'package:flutter/foundation.dart';

/// Identificador de unidad publicitaria de prueba de Google AdMob para
/// el formato Picture-in-Picture (PiP) en Android.
const String _kPipAdUnitId = 'ca-app-pub-3940256099942544/9657123429';

/// Estados posibles del anuncio PiP.
enum AdmobPipState {
  idle,
  loading,
  loaded,
  showing,
  failed,
}

/// Servicio centralizado que gestiona el ciclo de vida completo del
/// anuncio Picture-in-Picture de Google AdMob (Next-Gen SDK 1.4.0+).
///
/// Diseñado para ser instanciado dentro del Estado de [HomeScreen] y
/// coordinado con [RouteAware], garantizando que el anuncio se oculte
/// al transicionar a otras pantallas y se destruya al salir de la sesión.
class AdmobPipService extends ChangeNotifier {
  PictureInPictureAd? _pipAd;
  AdmobPipState _state = AdmobPipState.idle;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Estado actual del anuncio.
  AdmobPipState get state => _state;

  /// Mensaje de error del último fallo (si aplica).
  String? get errorMessage => _errorMessage;

  /// Verdadero cuando el anuncio está cargado y listo para mostrarse.
  bool get isAdLoaded => _state == AdmobPipState.loaded;

  /// Verdadero cuando el anuncio está actualmente visible en pantalla.
  bool get isAdShowing => _state == AdmobPipState.showing;

  /// Inicializa el SDK de AdMob una sola vez. Debe llamarse antes de [loadAd()].
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdmobPip] SDK inicializado.');
    } catch (e) {
      debugPrint('[AdmobPip] Error al inicializar SDK: $e');
      _errorMessage = e.toString();
    }
  }

  /// Carga el anuncio PiP de forma asíncrona si no está ya en memoria o en proceso.
  Future<void> loadAd() async {
    if (_isDisposed) return;
    if (_state == AdmobPipState.loading ||
        _state == AdmobPipState.loaded ||
        _state == AdmobPipState.showing) {
      return; // Evitar cargas duplicadas innecesarias
    }

    _setState(AdmobPipState.loading);
    _errorMessage = null;

    try {
      final ad = await PictureInPictureAd.load(
        adUnitId: _kPipAdUnitId,
        request: const AdRequest(),
      );

      if (_isDisposed) {
        // Si el widget se destruyó mientras descargaba el anuncio, liberamos inmediatamente.
        ad.dispose();
        return;
      }

      // Configurar los listeners del ciclo de vida nativo.
      ad.listener = PictureInPictureAdListener(
        onAdShown: () {
          debugPrint('[AdmobPip] Anuncio mostrado.');
          _setState(AdmobPipState.showing);
        },
        onAdHidden: () {
          debugPrint('[AdmobPip] Anuncio ocultado/descartado.');
          _setState(AdmobPipState.loaded);
        },
        onAdImpression: () {
          debugPrint('[AdmobPip] Impresión registrada.');
        },
        onAdClicked: () {
          debugPrint('[AdmobPip] Anuncio pulsado.');
        },
        onAdDismissedFullScreenContent: () {
          debugPrint('[AdmobPip] Contenido fullscreen descartado.');
          _setState(AdmobPipState.showing);
        },
        onAdFailedToShowFullScreenContent: (AdError error) {
          debugPrint('[AdmobPip] Fallo al mostrar fullscreen: $error');
        },
      );

      _pipAd = ad;
      _setState(AdmobPipState.loaded);
      debugPrint('[AdmobPip] Anuncio cargado correctamente.');
    } catch (e) {
      debugPrint('[AdmobPip] Error al cargar: $e');
      _errorMessage = e.toString();
      _setState(AdmobPipState.failed);
    }
  }

  /// Muestra el anuncio PiP flotante si está cargado y no se está mostrando ya.
  Future<void> showAd() async {
    if (_isDisposed) return;
    if (_pipAd != null && _state == AdmobPipState.loaded) {
      try {
        await _pipAd!.show();
        _setState(AdmobPipState.showing);
        debugPrint('[AdmobPip] Anuncio mostrado.');
      } catch (e) {
        debugPrint('[AdmobPip] Error al mostrar: $e');
        _errorMessage = e.toString();
        _setState(AdmobPipState.failed);
      }
    } else {
      debugPrint('[AdmobPip] showAd() omitido (estado actual: $_state).');
    }
  }

  /// Oculta el anuncio PiP si está activo, manteniéndolo en memoria para reanudarlo después.
  Future<void> hideAd() async {
    if (_isDisposed) return;
    if (_pipAd != null && _state == AdmobPipState.showing) {
      try {
        await _pipAd!.hide();
        _setState(AdmobPipState.loaded);
        debugPrint('[AdmobPip] Anuncio ocultado programáticamente.');
      } catch (e) {
        debugPrint('[AdmobPip] Error al ocultar: $e');
      }
    }
  }

  /// Libera todos los recursos nativos del anuncio.
  void disposeAd() {
    if (_pipAd != null) {
      _pipAd!.dispose();
      _pipAd = null;
      _setState(AdmobPipState.idle);
      debugPrint('[AdmobPip] Recursos del anuncio liberados.');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    disposeAd();
    super.dispose();
  }

  // ── Privado ─────────────────────────────────────────────────────────────

  void _setState(AdmobPipState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }
}
