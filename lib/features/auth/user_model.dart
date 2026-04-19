class UserModel {
  final String username;
  final String role; // 'Ketua' atau 'Anggota'
  final String teamId;

  UserModel({required this.username, required this.role, required this.teamId});
}
