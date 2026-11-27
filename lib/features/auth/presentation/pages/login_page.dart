import 'package:flutter/material.dart';
import 'package:assetone/shared/widgets/feature_scaffold.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: "Đăng nhập",
      description: "Truy cập tài khoản AssetOne của bạn.",
      sections: [
        "Email và mật khẩu",
        "Ghi nhớ phiên đăng nhập",
        "Quên mật khẩu",
        "Google, Facebook hoặc đi đến đăng ký",
      ],
    );
  }
}
