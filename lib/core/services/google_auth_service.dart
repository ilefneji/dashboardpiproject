import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final String googleIdToken;
  final String firebaseToken;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const GoogleAuthResult({
    required this.googleIdToken,
    required this.firebaseToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

class GoogleAuthService {
  GoogleAuthService._();

  static const String _webClientId =
      '272451779584-k60dr2nllicm1kjn93ro0kfku5u6k8id.apps.googleusercontent.com';

  static const List<String> _scopes = <String>['email', 'profile'];

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;
  static bool _isSigningIn = false;

  static Future<void> _initialize() {
    return _initialization ??= _googleSignIn.initialize(
      clientId: _webClientId,
      serverClientId: _webClientId,
    );
  }

  static Future<GoogleAuthResult> signIn() async {
    if (_isSigningIn) {
      throw Exception('Connexion Google deja en cours.');
    }

    _isSigningIn = true;

    try {
      await _initialize();

      debugPrint('[GOOGLE AUTH] Starting Google authenticate');

      final googleUser = await _googleSignIn.authenticate(scopeHint: _scopes);

      final googleAuth = googleUser.authentication;
      final googleAuthorization =
          await googleUser.authorizationClient.authorizationForScopes(
            _scopes,
          ) ??
          await googleUser.authorizationClient.authorizeScopes(_scopes);

      final googleIdToken = googleAuth.idToken;
      final googleAccessToken = googleAuthorization.accessToken;

      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw Exception('Impossible de recuperer le token Google.');
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleIdToken,
        accessToken: googleAccessToken,
      );

      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Connexion Firebase impossible.');
      }

      final firebaseToken = await firebaseUser.getIdToken(true);

      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception('Impossible de recuperer le token Firebase.');
      }

      return GoogleAuthResult(
        googleIdToken: googleIdToken,
        firebaseToken: firebaseToken,
        email: firebaseUser.email ?? googleUser.email,
        displayName: firebaseUser.displayName ?? googleUser.displayName,
        photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
      );
    } finally {
      _isSigningIn = false;
    }
  }

  static Future<void> signOut() async {
    await _initialize();
    await _googleSignIn.signOut();
    await firebase_auth.FirebaseAuth.instance.signOut();
  }
}
