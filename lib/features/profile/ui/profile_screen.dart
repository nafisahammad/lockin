import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme_extensions.dart';
import '../../../core/leveling.dart';
import '../../../shared/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    if (auth == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view profile.')),
      );
    }
    final profileAsync = ref.watch(userProfileProvider(auth.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile loading...'));
          }
          final levelTitle = Leveling.titleForLevel(profile.level);
          final themeMode = ref.watch(themeModeProvider);
          final isDark = themeMode == ThemeMode.dark;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                levelTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: context.lockInMuted),
              ),
              const SizedBox(height: 24),
              _StatTile(
                label: 'Discipline Score',
                value: profile.disciplineScore.toString(),
              ),
              _StatTile(
                label: 'Current Streak',
                value: '${profile.currentStreak} days',
              ),
              _StatTile(
                label: 'Longest Streak',
                value: '${profile.longestStreak} days',
              ),
              _StatTile(
                label: 'Total Focus',
                value: '${profile.totalFocusMinutes} min',
              ),
              const SizedBox(height: 12),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                title: 'Change Name',
                subtitle: profile.name,
                onTap: () => _showChangeNameDialog(
                  context,
                  ref,
                  auth,
                  profile.name,
                ),
              ),
              _SettingsTile(
                title: 'Change Email',
                subtitle: auth.email ?? 'No email on file',
                onTap: () => _showChangeEmailDialog(context, ref, auth),
              ),
              _SettingsTile(
                title: 'Change Password',
                subtitle: 'Requires current password',
                onTap: () => _showChangePasswordDialog(context, ref, auth),
              ),
              SwitchListTile(
                value: isDark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).state =
                      value ? ThemeMode.dark : ThemeMode.light;
                },
                title: const Text('Dark Theme'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _showChangeEmailDialog(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) async {
    if (!_supportsPasswordProvider(user)) {
      _showSnackBar(
        context,
        'Email updates require a password-based account.',
      );
      return;
    }
    final emailController = TextEditingController(text: user.email ?? '');
    final passwordController = TextEditingController();
    String? errorText;
    bool isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change Email'),
          scrollable: true,
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'New email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newEmail = emailController.text.trim();
                      final password = passwordController.text;
                      if (newEmail.isEmpty || password.isEmpty) {
                        setState(() => errorText = 'All fields are required.');
                        return;
                      }
                      setState(() {
                        errorText = null;
                        isSaving = true;
                      });
                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.reauthenticateWithPassword(
                          email: user.email ?? '',
                          password: password,
                        );
                        await authRepo.sendEmailChangeVerification(newEmail);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _showSnackBar(
                          context,
                          'Verification email sent to $newEmail.',
                        );
                      } on FirebaseAuthException catch (error) {
                        if (!dialogContext.mounted) return;
                        setState(() {
                          errorText = error.message;
                          isSaving = false;
                        });
                        return;
                      }
                      if (!dialogContext.mounted) return;
                      setState(() => isSaving = false);
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeNameDialog(
    BuildContext context,
    WidgetRef ref,
    User user,
    String currentName,
  ) async {
    if (!_supportsPasswordProvider(user)) {
      _showSnackBar(
        context,
        'Name updates require a password-based account.',
      );
      return;
    }
    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    String? errorText;
    bool isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change Name'),
          scrollable: true,
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'New name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newName = nameController.text.trim();
                      final password = passwordController.text;
                      if (newName.isEmpty || password.isEmpty) {
                        setState(() => errorText = 'All fields are required.');
                        return;
                      }
                      setState(() {
                        errorText = null;
                        isSaving = true;
                      });
                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.reauthenticateWithPassword(
                          email: user.email ?? '',
                          password: password,
                        );
                        await user.updateDisplayName(newName);
                        await ref
                            .read(userProfileRepositoryProvider)
                            .updateName(userId: user.uid, name: newName);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _showSnackBar(context, 'Name updated.');
                      } on FirebaseAuthException catch (error) {
                        if (!dialogContext.mounted) return;
                        setState(() {
                          errorText = error.message;
                          isSaving = false;
                        });
                        return;
                      }
                      if (!dialogContext.mounted) return;
                      setState(() => isSaving = false);
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) async {
    if (!_supportsPasswordProvider(user)) {
      _showSnackBar(
        context,
        'Password updates require a password-based account.',
      );
      return;
    }
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;
    bool isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change Password'),
          scrollable: true,
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final currentPassword = currentController.text;
                      final newPassword = newController.text;
                      final confirmPassword = confirmController.text;
                      if (currentPassword.isEmpty ||
                          newPassword.isEmpty ||
                          confirmPassword.isEmpty) {
                        setState(() => errorText = 'All fields are required.');
                        return;
                      }
                      if (newPassword != confirmPassword) {
                        setState(() => errorText = 'Passwords do not match.');
                        return;
                      }
                      setState(() {
                        errorText = null;
                        isSaving = true;
                      });
                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.reauthenticateWithPassword(
                          email: user.email ?? '',
                          password: currentPassword,
                        );
                        await authRepo.updatePassword(newPassword);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _showSnackBar(context, 'Password updated.');
                      } on FirebaseAuthException catch (error) {
                        if (!dialogContext.mounted) return;
                        setState(() {
                          errorText = error.message;
                          isSaving = false;
                        });
                        return;
                      }
                      if (!dialogContext.mounted) return;
                      setState(() => isSaving = false);
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool _supportsPasswordProvider(User user) {
    return user.providerData.any((info) => info.providerId == 'password');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
