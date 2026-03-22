import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Returns a SHA-256 hash of the password
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
