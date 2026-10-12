import 'package:flutter/material.dart';

import '../services/playlist_service.dart';
import '../widgets/auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.library, this.onLogin});
  final PlaylistService library;
  final VoidCallback? onLogin;
  @override
  Widget build(BuildContext context) => AuthForm(
    library: library,
    register: true,
    onSwitch: onLogin ?? () => Navigator.pop(context),
  );
}
