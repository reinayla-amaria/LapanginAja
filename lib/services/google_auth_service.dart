import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '456444985147-c4g2j2402jv9f0mb067v1qhl8k9klaem.apps.googleusercontent.com',
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account != null) {
        print("Nama: ${account.displayName}");
        print("Email: ${account.email}");
        print("Foto: ${account.photoUrl}");
      }

      return account;
    } catch (e) {
      print("Error login Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
