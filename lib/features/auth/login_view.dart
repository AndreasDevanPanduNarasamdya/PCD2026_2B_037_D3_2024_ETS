import 'package:flutter/material.dart';
import 'dart:async';
import 'login_controller.dart';
import '../logbook/log_view.dart';
import '../auth/user_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isObscured = true;
  int _failedAttempts = 0;
  bool _isLocked = false;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password tidak boleh kosong!"),
        ),
      );
      return;
    }

    // --- BARIS YANG DIPERBAIKI: Gunakan UserModel?, bukan bool ---
    UserModel? loggedInUser = _controller.login(user, pass);

    if (loggedInUser != null) {
      _failedAttempts = 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(currentUser: loggedInUser),
        ),
      );
    } else {
      setState(() {
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        _lockLoginButton();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login Gagal! Sisa percobaan: ${3 - _failedAttempts}",
            ),
          ),
        );
      }
    }
  }

  void _lockLoginButton() {
    setState(() {
      _isLocked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terlalu banyak percobaan. Tunggu 10 detik."),
      ),
    );

    Timer(const Duration(seconds: 10), () {
      setState(() {
        _isLocked = false;
        _failedAttempts = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: _isObscured,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLocked ? null : _handleLogin,
              child: Text(_isLocked ? "Terkunci..." : "Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}
