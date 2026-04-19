import 'user_model.dart';

class LoginController {
  // Simulasi Database User (Gatekeeper Modul 5)
  final List<UserModel> _users = [
    UserModel(username: "admin", role: "Ketua", teamId: "TEAM_A"),
    UserModel(username: "andrew", role: "Anggota", teamId: "TEAM_A"),
  ];

  UserModel? login(String username, String password) {
    // Demi simulasi, password kita abaikan dulu, cek username saja
    try {
      return _users.firstWhere(
        (u) => u.username == username && password == "123",
      );
    } catch (e) {
      return null; // Login gagal
    }
  }
}
