import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Chiede al browser di non cancellare i dati dell'app (StorageManager.persist).
Future<bool> requestPersistentStorage() async {
  try {
    final r = await web.window.navigator.storage.persist().toDart;
    return r.toDart;
  } catch (_) {
    return false;
  }
}

/// True se aperta come app installata (Aggiungi a Home).
bool isStandalone() {
  try {
    return web.window.matchMedia('(display-mode: standalone)').matches;
  } catch (_) {
    return false;
  }
}

bool isIOSBrowser() {
  final ua = web.window.navigator.userAgent;
  return ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
}
