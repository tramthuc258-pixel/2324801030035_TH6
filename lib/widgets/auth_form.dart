import 'package:flutter/material.dart';

import '../services/playlist_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.library,
    required this.register,
    required this.onSwitch,
  });
  final PlaylistService library;
  final bool register;
  final VoidCallback onSwitch;
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool get _register => widget.register;
  bool _hidePassword = true;
  bool _submitting = false;
  bool _googleSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting ||
        widget.library.busy ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final success = await runMusicAction(
      context,
      () => _register
          ? widget.library.register(
              _name.text.trim(),
              _email.text.trim(),
              _password.text,
            )
          : widget.library.signIn(_email.text.trim(), _password.text),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.pop(context);
  }

  Future<void> _submitGoogle() async {
    if (_submitting || widget.library.busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _googleSubmitting = true;
    });
    var authenticated = false;
    final requestSucceeded = await runMusicAction(context, () async {
      authenticated = await widget.library.signInWithGoogle();
    });
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _googleSubmitting = false;
    });
    if (requestSucceeded && authenticated) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.library,
    builder: (context, _) {
      final busy = widget.library.busy || _submitting;
      final palette = MusicPalette.of(context);
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [palette.primary, palette.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        size: 22,
                        color: palette.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'DYN MUSIC',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Đóng',
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.muted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _register ? 'Tạo tài khoản' : 'Chào bạn trở lại',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _register
                      ? 'Bắt đầu lưu những giai điệu của riêng bạn.'
                      : 'Bài yêu thích và playlist, luôn ở bên bạn.',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  key: const ValueKey('google-sign-in'),
                  onPressed: busy ? null : _submitGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: palette.surface,
                    foregroundColor: palette.text,
                    disabledBackgroundColor: palette.raised,
                    disabledForegroundColor: palette.muted,
                    side: BorderSide(color: palette.border),
                    minimumSize: const Size(48, 50),
                  ),
                  icon: _googleSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4285F4),
                          ),
                        )
                      : Image.asset(
                          'assets/logo/logo_google.jpg',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          semanticLabel: 'Google',
                        ),
                  label: const Text('Tiếp tục với Google'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'hoặc dùng email',
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                if (_register) ...[
                  TextFormField(
                    controller: _name,
                    enabled: !busy,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: 'Tên của bạn',
                      hintText: 'Bạn muốn được gọi là gì?',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: palette.primary,
                      ),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Nhập tên của bạn.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'ban@example.com',
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: palette.primary,
                    ),
                  ),
                  validator: (value) =>
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Nhập địa chỉ email hợp lệ.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  enabled: !busy,
                  obscureText: _hidePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: [
                    _register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: _register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_register) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: palette.primary,
                    ),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      onPressed: busy
                          ? null
                          : () =>
                                setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nhập mật khẩu.';
                    if (_register && value.length < 6) {
                      return 'Mật khẩu cần ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                ),
                if (_register) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmation,
                    enabled: !busy,
                    obscureText: _hidePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: palette.primary,
                      ),
                    ),
                    validator: (value) => value != _password.text
                        ? 'Hai mật khẩu chưa khớp.'
                        : null,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                  ),
                  child: _submitting && !_googleSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_register ? 'Tạo tài khoản' : 'Đăng nhập'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          widget.library.clearError();
                          widget.onSwitch();
                        },
                  child: Text(
                    _register
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
