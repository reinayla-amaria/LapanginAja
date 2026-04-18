import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../user/main_nav_screen.dart';
import '/services/google_auth_service.dart';
import '/services/google_user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleAuthService _authService = GoogleAuthService(); // ✅ FIX
  final GoogleUserService _googleUserService = GoogleUserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                Image.asset('assets/logo_blue.png', height: 120),

                const SizedBox(height: 60),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Login to your account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Masuk ke akun anda untuk melanjutkan.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Email wajib diisi" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Password wajib diisi" : null,
                ),

                const SizedBox(height: 20),

                Text(
                  "atau gunakan akun google anda untuk login",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 10),

                // ✅ GOOGLE LOGIN
                InkWell(
                  onTap: () async {
                    final user = await _authService.signIn();

                    if (user != null) {
                      print("Login berhasil: ${user.email}");

                      try {
                        await _googleUserService.registerGoogleUser(
                          name: user.displayName ?? "",
                          email: user.email,
                          googleId: user.id,
                          photoUrl: user.photoUrl ?? "",
                        );
                      } catch (e) {
                        print("Error backend: $e");
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Gagal login dengan Google"),
                        ),
                      );
                    }
                  },
                  child: Image.asset('assets/google_logo.png', width: 60),
                ),

                const SizedBox(height: 20),

                // LOGIN MANUAL
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainNavScreen(),
                          ),
                        );
                      }
                    },
                    child: const Text("Login", style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color(0xFF093FB4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
