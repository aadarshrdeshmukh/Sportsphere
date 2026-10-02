import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../screens/auth_screen.dart';
import '../state/auth_controller.dart';
import '../state/favorites_controller.dart';
import '../theme/app_theme.dart';

class AccountSheet extends StatelessWidget {
  const AccountSheet({
    super.key,
    required this.auth,
    required this.favorites,
  });

  final AuthController auth;
  final FavoritesController favorites;

  static Future<void> show(
    BuildContext context, {
    required AuthController auth,
    required FavoritesController favorites,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AccountSheet(auth: auth, favorites: favorites),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([auth, favorites]),
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.paleGreen,
                    child: Icon(
                      auth.isSignedIn && !auth.isAnonymous
                          ? Iconsax.user_copy
                          : Iconsax.user,
                      size: 28,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isSignedIn && !auth.isAnonymous
                              ? auth.displayName ?? 'SportSphere Fan'
                              : (auth.isAnonymous ? 'Guest User' : 'Not Signed In'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.isSignedIn && !auth.isAnonymous
                              ? auth.email ?? ''
                              : 'Favorites are saved on this device only',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Iconsax.heart, color: AppTheme.primary),
                title: const Text('Followed Teams'),
                trailing: Text(
                  '${favorites.teams.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  auth.isSignedIn && !auth.isAnonymous
                      ? Iconsax.cloud_connection
                      : Iconsax.cloud_cross,
                  color: auth.isSignedIn && !auth.isAnonymous
                      ? AppTheme.primary
                      : AppTheme.muted,
                ),
                title: const Text('Cloud Sync (Firestore)'),
                subtitle: Text(
                  auth.isSignedIn && !auth.isAnonymous
                      ? 'Favorites backed up automatically'
                      : 'Sign in to sync across devices',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.setting_2, color: AppTheme.primary),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
              const SizedBox(height: 20),
              if (auth.isSignedIn && !auth.isAnonymous)
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await auth.signOut();
                    await favorites.syncWithUser(null);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Iconsax.logout, size: 18),
                  label: const Text('Sign Out'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(auth: auth),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.login, size: 18),
                  label: const Text('Sign In / Create Account'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
