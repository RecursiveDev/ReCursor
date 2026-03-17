import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/auth/auth_state.dart';
import '../widgets/auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _patController = TextEditingController();
  bool _showPat = false;
  bool _patMode = false;

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGithub() async {
    // OAuth flow: start flow to get auth URL, then exchange code.
    // For now sign in with empty code to trigger the OAuth redirect flow.
    await ref.read(authStateProvider.notifier).signInWithOAuth('');
  }

  Future<void> _signInWithPat() async {
    final pat = _patController.text.trim();
    if (pat.isEmpty) return;
    await ref.read(authStateProvider.notifier).signInWithPAT(pat);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (_, next) {
      if (next.status == AuthStatus.authenticated && context.mounted) {
        context.go('/home');
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/branding/ReCursor_Darklogo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),
              const Text(
                'Welcome to ReCursor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to connect your AI coding agents',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CDCFE), fontSize: 14),
              ),
              const SizedBox(height: 40),
              if (!_patMode) ...[
                AuthButton(
                  label: 'Sign in with GitHub',
                  icon: Icons.code,
                  onPressed: isLoading ? null : _signInWithGithub,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _patMode = true),
                  child: const Text(
                    'Use Personal Access Token',
                    style: TextStyle(color: Color(0xFF4EC9B0)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _patController,
                  obscureText: !_showPat,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Personal Access Token',
                    labelStyle: const TextStyle(color: Color(0xFF9CDCFE)),
                    filled: true,
                    fillColor: const Color(0xFF252526),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPat ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF9CDCFE),
                      ),
                      onPressed: () => setState(() => _showPat = !_showPat),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AuthButton(
                  label: 'Sign In',
                  icon: Icons.login,
                  onPressed: isLoading ? null : _signInWithPat,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _patMode = false),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Color(0xFF9CDCFE)),
                  ),
                ),
              ],
              if (authState.status == AuthStatus.error)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authState.errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
