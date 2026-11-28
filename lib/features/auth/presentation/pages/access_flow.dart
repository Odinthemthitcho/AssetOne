import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/api_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/local_auth.dart';


class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: large ? 24 : 17,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: Icon(Icons.layers_outlined, size: large ? 28 : 20),
      ),
      const SizedBox(width: 10),
      Text(
        'AssetOne',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: large ? 30 : 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class AssetOneIntro extends StatefulWidget {
  const AssetOneIntro({required this.onFinish, super.key});
  final Future<void> Function() onFinish;

  @override
  State<AssetOneIntro> createState() => _AssetOneIntroState();
}

class _AssetOneIntroState extends State<AssetOneIntro> {
  static const _slides = [
    (
      Icons.ssid_chart,
      'Làm chủ tài chính của bạn',
      'Theo dõi tài sản, danh mục đầu tư và tình hình tài chính cá nhân.',
    ),
    (
      Icons.grid_view_rounded,
      'Quản lý tài sản thông minh hơn',
      'Quản lý các khoản đầu tư, tài khoản và tài sản ở cùng một nơi.',
    ),
    (
      Icons.track_changes_rounded,
      'Tối ưu tài chính và lợi ích',
      'Theo dõi hiệu quả tài chính, dòng tiền và những mục tiêu bạn đã đặt.',
    ),
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (viewport.maxHeight - 32).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Brand(),
                            const Spacer(),
                            TextButton(
                              onPressed: widget.onFinish,
                              child: const Text('Bỏ qua'),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(child: _IntroArt(icon: slide.$1)),
                        const SizedBox(height: 32),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => _index == 2
                              ? widget.onFinish()
                              : setState(() => _index++),
                          child: Text(
                            _index == 2 ? 'Bắt đầu ngay' : 'Tiếp theo  →',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < _slides.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: i == _index ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? AppColors.accent
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '0${_index + 1} / 03',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroArt extends StatelessWidget {
  const _IntroArt({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 190,
    child: Stack(
      alignment: Alignment.center,
      children: [
        for (final size in [190.0, 158.0, 124.0])
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: .10),
              ),
            ),
          ),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: .10),
                blurRadius: 32,
              ),
            ],
          ),
          child: Icon(icon, size: 52, color: AppColors.accent),
        ),
      ],
    ),
  );
}

class AssetOneWelcome extends StatelessWidget {
  const AssetOneWelcome({
    required this.onLogin,
    required this.onRegister,
    required this.onExplore,
    super.key,
  });
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 5),
                const Center(child: Brand(large: true)),
                const SizedBox(height: 12),
                const Text(
                  'QUẢN LÝ TÀI SẢN TOÀN DIỆN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const Spacer(flex: 4),
                FilledButton(
                  onPressed: onLogin,
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onRegister,
                  child: const Text('Tạo tài khoản'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onExplore,
                  child: const Text('Khám phá ngay'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

enum AccessMode { login, register, forgot, verify, reset }

class AssetOneAccessPage extends StatefulWidget {
  const AssetOneAccessPage({
    required this.auth,
    required this.initialMode,
    super.key,
  });
  final ApiAuth auth;
  final AccessMode initialMode;

  @override
  State<AssetOneAccessPage> createState() => _AssetOneAccessPageState();
}

class _AssetOneAccessPageState extends State<AssetOneAccessPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _code = TextEditingController();
  late AccessMode _mode = widget.initialMode;
  ResetChallenge? _challenge;
  Timer? _timer;
  bool _readable = false;
  bool _remember = true;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_name, _email, _password, _confirmation, _code]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _show(AccessMode next, {String? notice}) {
    setState(() {
      _error = null;
      _notice = notice;
      _mode = next;
      _password.clear();
      _confirmation.clear();
      _code.clear();
      _readable = false;
    });
  }

  Future<void> _requestCode() async {
    final reset = await widget.auth.requestReset(_email.text);
    if (!mounted) return;
    _challenge = reset;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _mode != AccessMode.verify) {
        timer.cancel();
      } else {
        setState(() {});
      }
    });
    _show(AccessMode.verify);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể đọc hoặc lưu hồ sơ trên thiết bị. Thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _run(() async {
      switch (_mode) {
        case AccessMode.login:
          final profile = await widget.auth.signIn(
            _email.text,
            _password.text,
            remember: _remember,
          );
          if (mounted) Navigator.pop(context, profile);
        case AccessMode.register:
          final profile = await widget.auth.register(
            _name.text,
            _email.text,
            _password.text,
          );
          if (mounted) Navigator.pop(context, profile);
        case AccessMode.forgot:
          await _requestCode();
        case AccessMode.verify:
          widget.auth.verify(_challenge!, _code.text);
          _show(AccessMode.reset);
        case AccessMode.reset:
          await widget.auth.resetPassword(_challenge!, _password.text);
          if (mounted) {
            _show(
              AccessMode.login,
              notice: 'Đã đổi mật khẩu. Hãy đăng nhập lại.',
            );
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (title, description, button) = switch (_mode) {
      AccessMode.login => (
        'Chào mừng bạn!',
        'Đăng nhập để quản lý tài sản và danh mục đầu tư.',
        'Đăng nhập',
      ),
      AccessMode.register => (
        'Đăng ký',
        'Tạo hồ sơ trên thiết bị để bắt đầu quản lý tài sản.',
        'Tạo tài khoản',
      ),
      AccessMode.forgot => (
        'Quên mật khẩu?',
        'Nhập email của hồ sơ đã tạo trên thiết bị.',
        'Tiếp theo',
      ),
      AccessMode.verify => (
        'Mã xác nhận',
        'Nhập mã sáu chữ số để tiếp tục đặt lại mật khẩu.',
        'Xác nhận',
      ),
      AccessMode.reset => (
        'Đặt lại mật khẩu',
        'Tạo mật khẩu mới cho hồ sơ trên thiết bị.',
        'Lưu mật khẩu',
      ),
    };
    final login = _mode == AccessMode.login;
    final registration = _mode == AccessMode.register;
    final password = login || registration || _mode == AccessMode.reset;
    final challenge = _challenge;
    final wait = challenge == null
        ? 0
        : challenge.resendAt.difference(DateTime.now()).inSeconds + 1;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  const Center(child: Brand()),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 24),
                  if (registration) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                      autofillHints: const [AutofillHints.name],
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Nhập họ và tên.' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (login || registration || _mode == AccessMode.forgot) ...[
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) => LocalAuth.validEmail(value ?? '')
                          ? null
                          : 'Nhập email hợp lệ.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (password) ...[
                    TextFormField(
                      controller: _password,
                      obscureText: !_readable,
                      decoration: InputDecoration(
                        labelText: _mode == AccessMode.reset
                            ? 'Mật khẩu mới'
                            : 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _readable ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                          onPressed: () =>
                              setState(() => _readable = !_readable),
                          icon: Icon(
                            _readable
                                ? Icons.visibility_off
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      autofillHints: [
                        login
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      validator: (value) =>
                          (value!.isEmpty ||
                              (!login &&
                                  (value.length < 8 || value.length > 128)))
                          ? (login
                                ? 'Nhập mật khẩu.'
                                : 'Mật khẩu cần từ 8 đến 128 ký tự.')
                          : null,
                    ),
                    if (!login) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmation,
                        obscureText: !_readable,
                        decoration: const InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Mật khẩu xác nhận chưa khớp.',
                      ),
                    ],
                  ],
                  if (login)
                    Row(
                      children: [
                        Checkbox(
                          value: _remember,
                          onChanged: _busy
                              ? null
                              : (value) => setState(() => _remember = value!),
                        ),
                        const Text('Ghi nhớ'),
                        const Spacer(),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _show(AccessMode.forgot),
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ],
                    ),
                  if (_mode == AccessMode.verify && challenge != null) ...[
                    SelectableText(
                      'Mã thử trên thiết bị: ${challenge.demoCode}',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mã xác nhận',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) =>
                          value?.length == 6 ? null : 'Nhập đủ sáu chữ số.',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy || wait > 0
                            ? null
                            : () => _run(_requestCode),
                        child: Text(
                          wait > 0 ? 'Gửi lại sau ${wait}s' : 'Gửi lại mã',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_error case final error?) ...[
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_notice case final notice?) ...[
                    Text(
                      notice,
                      style: const TextStyle(color: AppColors.accent),
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Đang xử lý…' : button),
                  ),
                  if (login || registration) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Hồ sơ cục bộ · Google và Facebook cần cấu hình dịch vụ đăng nhập.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _show(
                            login ? AccessMode.register : AccessMode.login,
                          ),
                    child: Text(
                      login
                          ? 'Bạn chưa có tài khoản? Đăng ký'
                          : 'Trở lại đăng nhập',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
