import 'package:flutter/material.dart';

import '../../features/auth/data/local_auth.dart';
import '../../features/auth/presentation/pages/access_flow.dart';
import '../di/app_dependencies.dart';
import 'portfolio_shell.dart';

class AssetOneRoot extends StatefulWidget {
  const AssetOneRoot({required this.dependencies, super.key});
  final AppDependencies dependencies;

  @override
  State<AssetOneRoot> createState() => _AssetOneRootState();
}

class _AssetOneRootState extends State<AssetOneRoot> {
  static const _introKey = 'intro.v1';
  LocalProfile? _profile;
  bool _loading = true;
  bool _seenIntro = false;
  String? _error;
  AppDependencies get _deps => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _perform(() async {
      final seen = await _deps.storage.read(_introKey) == 'seen';
      final restored = await _deps.auth.restore();
      if (restored != null) await _deps.portfolio.open(restored.id);
      if (!mounted) return;
      setState(() {
        _seenIntro = seen;
        _profile = restored;
      });
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể mở hoặc lưu dữ liệu AssetOne.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishIntro() => _perform(() async {
    await _deps.storage.write(_introKey, 'seen');
    if (mounted) setState(() => _seenIntro = true);
  });

  Future<void> _enter(LocalProfile profile) => _perform(() async {
    await _deps.portfolio.open(
      profile.isGuest && !_deps.config.useDemoData ? 'guest-local' : profile.id,
      seedDemo: profile.isGuest && _deps.config.useDemoData,
    );
    if (mounted) setState(() => _profile = profile);
  });

  Future<void> _openAccess(AccessMode mode) async {
    final profile = await Navigator.of(context).push<LocalProfile>(
      MaterialPageRoute(
        builder: (_) => AssetOneAccessPage(auth: _deps.auth, initialMode: mode),
      ),
    );
    if (profile != null && mounted) await _enter(profile);
  }

  Future<void> _signOut() => _perform(() async {
    await _deps.auth.signOut();
    _deps.portfolio.close();
    if (mounted) setState(() => _profile = null);
  });

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: Brand()));
    if (_error case final error?) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Brand(),
                const SizedBox(height: 24),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _start, child: const Text('Thử lại')),
              ],
            ),
          ),
        ),
      );
    }
    if (_profile case final profile?) {
      return PortfolioShell(
        key: ValueKey(profile.id),
        store: _deps.portfolio,
        profile: profile,
        demo: _deps.portfolio.isDemo,
        onSignOut: _signOut,
      );
    }
    return _seenIntro
        ? AssetOneWelcome(
            onLogin: () => _openAccess(AccessMode.login),
            onRegister: () => _openAccess(AccessMode.register),
            onExplore: () => _enter(LocalProfile.guest),
          )
        : AssetOneIntro(onFinish: _finishIntro);
  }
}
