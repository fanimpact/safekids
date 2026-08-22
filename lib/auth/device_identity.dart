import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Jeton aléatoire propre à cet appareil, généré une seule fois et
/// conservé localement. Sert à reconnaître un appareil déjà vérifié
/// (voir `appareils_reconnus` côté Supabase) sans jamais transmettre
/// le jeton en clair à la base — seule son empreinte SHA-256 y est
/// envoyée et comparée.
class DeviceIdentity {
  DeviceIdentity._();

  static const _tokenKey = 'kidsrelay_device_token';

  static String? _cachedToken;

  static Future<String> _rawToken() async {
    if (_cachedToken != null) {
      return _cachedToken!;
    }

    final prefs = await SharedPreferences.getInstance();

    var token = prefs.getString(_tokenKey);

    if (token == null) {
      token = _generateToken();
      await prefs.setString(_tokenKey, token);
    }

    _cachedToken = token;
    return token;
  }

  static String _generateToken() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    return base64Url.encode(bytes);
  }

  /// Empreinte SHA-256 du jeton d'appareil, sous forme hexadécimale —
  /// c'est cette valeur, jamais le jeton lui-même, qui est envoyée aux
  /// Edge Functions et comparée côté serveur.
  static Future<String> tokenHash() async {
    final token = await _rawToken();
    return sha256.convert(utf8.encode(token)).toString();
  }

  /// Vide le cache en mémoire — usage tests uniquement, pour simuler
  /// un appareil différent au sein d'un même process de test.
  static void resetForTesting() {
    _cachedToken = null;
  }
}
