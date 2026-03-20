import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../domain/bridge_startup_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    unawaited(_restoreStartup());
  }

  Future<void> _restoreStartup() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final result = await ref.read(bridgeStartupControllerProvider).restore();
    ref.read(bridgeStartupErrorProvider.notifier).state = result.message;

    if (!mounted) {
      return;
    }

    switch (result.destination) {
      case AppStartupDestination.bridgeSetup:
        context.go('/bridge-setup');
        return;
      case AppStartupDestination.healthVerification:
        context.go('/health-verification');
        return;
      case AppStartupDestination.home:
        context.go('/home/chat');
        return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('splashScreen'),
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/branding/recursor_logo_dark.svg',
                width: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Restore Bridge Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Checking for a saved bridge pairing…',
                style: TextStyle(color: Color(0xFF9CDCFE)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
