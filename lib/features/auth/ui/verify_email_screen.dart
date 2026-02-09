import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers.dart';
import '../../../core/theme_extensions.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _status;

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _status = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _status = 'Verification email sent.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to send email: $error';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _checking = true;
      _status = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (!mounted) return;
      if (user?.emailVerified == true) {
        setState(() => _status = 'Email verified. Loading dashboard...');
      } else {
        setState(() => _status = 'Not verified yet. Check your inbox.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Failed to refresh: $error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread,
                  size: 56, color: context.lockInAccent),
              const SizedBox(height: 16),
              Text(
                'Check your inbox',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification email to ${widget.email}.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.lockInMuted),
              ),
              const SizedBox(height: 16),
              if (_status != null)
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: context.lockInMuted),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checking ? null : _refresh,
                  child: Text(_checking ? 'Checking...' : 'I verified my email'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _sending ? null : _resend,
                  child: Text(_sending ? 'Sending...' : 'Resend email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
