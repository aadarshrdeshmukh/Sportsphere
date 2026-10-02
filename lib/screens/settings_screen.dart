import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../state/auth_controller.dart';
import '../state/favorites_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/account_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.themeController,
    this.auth,
    this.favorites,
  });

  final ThemeController themeController;
  final AuthController? auth;
  final FavoritesController? favorites;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Account Section ──
            if (auth != null && favorites != null) ...[
              const _SectionTitle(title: 'Account'),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Iconsax.user,
                title: 'Account & Sync',
                subtitle: auth!.isSignedIn && !auth!.isAnonymous
                    ? auth!.email ?? 'Signed In'
                    : 'Not signed in',
                onTap: () => AccountSheet.show(
                  context,
                  auth: auth!,
                  favorites: favorites!,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Appearance Section ──
            const _SectionTitle(title: 'Appearance'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  _ThemeOptionTile(
                    icon: Iconsax.monitor,
                    title: 'System Default',
                    subtitle: 'Follows your device setting',
                    value: ThemeMode.system,
                    groupValue: themeController.mode,
                    onChanged: (mode) => themeController.setMode(mode),
                    isFirst: true,
                  ),
                  Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.4)),
                  _ThemeOptionTile(
                    icon: Iconsax.sun_1,
                    title: 'Light',
                    subtitle: 'Always use light theme',
                    value: ThemeMode.light,
                    groupValue: themeController.mode,
                    onChanged: (mode) => themeController.setMode(mode),
                  ),
                  Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.4)),
                  _ThemeOptionTile(
                    icon: Iconsax.moon,
                    title: 'Dark',
                    subtitle: 'Always use dark theme',
                    value: ThemeMode.dark,
                    groupValue: themeController.mode,
                    onChanged: (mode) => themeController.setMode(mode),
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── About Section ──
            const _SectionTitle(title: 'About'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Iconsax.info_circle,
                    title: 'App Version',
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.4)),
                  const _SettingsTile(
                    icon: Iconsax.cup,
                    title: 'SportSphere',
                    subtitle: 'Your Game, Your Score',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Section title ──
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      );
}

// ── Generic settings tile ──
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Theme option radio tile ──
class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
