import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime? createdAt;

  factory UserModel.fromFirebase(User user) => UserModel(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? '',
  );
}
