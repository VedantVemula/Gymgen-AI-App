import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MongoApiService {
  MongoApiService._();
  static final MongoApiService instance = MongoApiService._();

  // You can still override this when running via terminal:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000
  static const _override = String.fromEnvironment('API_BASE_URL');
  static const _timeout = Duration(seconds: 60);

  String get baseUrl {
    if (_override.isNotEmpty) return _override;
    
    // Changed: Defaults to the deployed server so it works on physical APKs.
    // If you are testing on the Emulator and want to use your local Node.js server,
    // you can uncomment the line below and comment out the Render URL.
    // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    //   return 'http://10.0.2.2:3000'; 
    // }
    
    return 'https://gymgen-api.onrender.com';
  }

  Future<Map<String, String>> _headers(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) {
      throw StateError('Sign in with this account before syncing its data.');
    }
    
    // Force refresh token to ensure Firebase Auth and App Check are valid
    final token = await user.getIdToken(true); 
    
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) => Uri.parse('$baseUrl/api$path');

  /// Returns the stored value, or null if nothing is stored for [key].
  Future<Object?> get(String uid, String key) async {
    final res = await http
        .get(_uri('/data/${Uri.encodeComponent(key)}'),
            headers: await _headers(uid))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('GET $key failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['exists'] == true ? body['value'] : null;
  }

  Future<void> put(String uid, String key, Object value,
      {bool merge = false}) async {
    final res = await http
        .put(_uri('/data/${Uri.encodeComponent(key)}'),
            headers: await _headers(uid),
            body: jsonEncode({'value': value, 'merge': merge}))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('PUT $key failed (${res.statusCode})');
    }
  }

  Future<void> deleteAll(String uid) async {
    final res = await http
        .delete(_uri('/data'), headers: await _headers(uid))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('DELETE failed (${res.statusCode})');
    }
  }
}