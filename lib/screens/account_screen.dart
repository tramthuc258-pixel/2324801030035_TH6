import 'package:flutter/material.dart';

import '../services/playlist_service.dart';
import '../services/theme_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';
import '../widgets/error_notice.dart';
import 'login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.library});
  final PlaylistService library;

  @override
  Widget build(BuildContext context) {
    final palette = MusicPalette.of(context);
    final user = library.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Góc của bạn', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Một không gian riêng cho gu nhạc của bạn.',
          style: TextStyle(color: palette.muted),
        ),
        if (library.error != null)
          LibraryErrorNotice(
            message: library.error!,
            onDismiss: library.clearError,
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [palette.heroStart, palette.heroEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: palette.primary.withValues(alpha: .12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: .20),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: user == null
                        ? Icon(
                            Icons.headphones_rounded,
                            color: palette.onPrimary,
                            size: 30,
                          )
                        : Text(
                            user.displayName.isEmpty
                                ? 'D'
                                : user.displayName.characters.first
                                      .toUpperCase(),
                            style: TextStyle(
                              fontSize: 26,
                              color: palette.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user == null ? 'DYN MUSIC' : 'Thành viên DYN',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                user == null
                    ? 'Nhạc hay, theo cách của bạn'
                    : (user.displayName.isEmpty
                          ? 'Người yêu nhạc'
                          : user.displayName),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                user == null
                    ? 'Đăng nhập để lưu những bài hát yêu thích và tạo playlist của riêng bạn.'
                    : user.email,
                style: TextStyle(color: palette.muted, height: 1.5),
              ),
              if (user?.createdAt case final DateTime createdAt) ...[
                const SizedBox(height: 10),
                Text(
                  'Thành viên từ ${_formatJoinDate(createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: user == null
                    ? FilledButton.icon(
                        onPressed: () => showMusicAuth(context, library),
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: const Text('Đăng nhập / Đăng ký'),
                      )
                    : OutlinedButton.icon(
                        onPressed: library.busy
                            ? null
                            : () => _signOut(context),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Đăng xuất'),
                      ),
              ),
            ],
          ),
        ),
        if (user != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AccountStat(
                  number: '${library.favoriteIds.length}',
                  label: 'Bài yêu thích',
                  icon: Icons.favorite_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccountStat(
                  number: '${library.playlists.length}',
                  label: 'Playlist riêng',
                  icon: Icons.library_music_rounded,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        const _AppearanceCard(),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.graphic_eq_rounded, size: 18, color: palette.primary),
            const SizedBox(width: 8),
            Text(
              'DYN MUSIC',
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Giai điệu của bạn. Mỗi ngày.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Playlist và bài yêu thích vẫn được lưu trong tài khoản của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await runMusicAction(context, library.signOut);
    }
  }
}

String _formatJoinDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({
    required this.number,
    required this.label,
    required this.icon,
  });
  final String number;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = MusicPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.primary, size: 20),
              const Spacer(),
              Text(number, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final palette = MusicPalette.of(context);
    final controller = MusicThemeScope.maybeOf(context);
    final mode = controller?.mode ?? ThemeMode.system;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: palette.primary, size: 22),
              const SizedBox(width: 10),
              Text('Giao diện', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn sắc màu cho không gian nghe nhạc.',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final option in const [
                (ThemeMode.system, 'Hệ thống', Icons.brightness_auto_rounded),
                (ThemeMode.light, 'Sáng', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Tối', Icons.dark_mode_outlined),
              ]) ...[
                if (option.$1 != ThemeMode.system) const SizedBox(width: 8),
                Expanded(
                  child: _AppearanceOption(
                    key: ValueKey('theme-${option.$1.name}'),
                    label: option.$2,
                    icon: option.$3,
                    selected: mode == option.$1,
                    onTap: controller == null
                        ? null
                        : () async {
                            await runMusicAction(
                              context,
                              () => controller.setMode(option.$1),
                            );
                          },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = MusicPalette.of(context);
    final foreground = selected ? palette.primary : palette.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? palette.primaryContainer : palette.raised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? palette.primary.withValues(alpha: .45)
                    : palette.border,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
