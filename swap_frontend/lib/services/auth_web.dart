// Web-specific auth helpers using package:web.
import 'package:web/web.dart' as web;

void redirectTo(String url) {
  web.window.location.assign(url);
}

String? getAuthCode() {
  final uri = Uri.parse(web.window.location.href);
  return uri.queryParameters['code'];
}

void clearUrlParams() {
  final base = web.window.location.origin + web.window.location.pathname;
  web.window.history.replaceState(null, '', base);
}

void storeVerifier(String verifier) {
  web.window.localStorage.setItem('entra_code_verifier', verifier);
}

String? readVerifier() {
  return web.window.localStorage.getItem('entra_code_verifier');
}

void clearVerifier() {
  web.window.localStorage.removeItem('entra_code_verifier');
}
