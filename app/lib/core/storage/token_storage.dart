import 'package:shared_preferences/shared_preferences.dart';

/// Persiste a sessão (access/refresh token) entre recarregamentos da página
/// (localStorage no Flutter Web, via shared_preferences).
class TokenStorage {
  static const _chaveAccess = 'gj_access_token';
  static const _chaveRefresh = 'gj_refresh_token';

  Future<void> salvar({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveAccess, accessToken);
    await prefs.setString(_chaveRefresh, refreshToken);
  }

  Future<void> salvarAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveAccess, accessToken);
  }

  Future<String?> lerAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveAccess);
  }

  Future<String?> lerRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveRefresh);
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveAccess);
    await prefs.remove(_chaveRefresh);
  }
}

/// Instância compartilhada; não é `final` para os testes substituírem por
/// `SharedPreferences.setMockInitialValues` ou uma instância isolada.
TokenStorage tokenStorage = TokenStorage();
