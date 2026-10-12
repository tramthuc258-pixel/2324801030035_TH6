import 'package:flutter/material.dart';

import '../services/playlist_service.dart';
import '../widgets/auth_form.dart';
import 'register_screen.dart';

Future<void> showMusicAuth(BuildContext context, PlaylistService library) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LoginScreen(library: library),
    );

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.library});
  final PlaylistService library;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _registering = false;
  @override
  Widget build(BuildContext context) => _registering
      ? RegisterScreen(
          library: widget.library,
          onLogin: () => setState(() => _registering = false),
        )
      : AuthForm(
          library: widget.library,
          register: false,
          onSwitch: () => setState(() => _registering = true),
        );
}
