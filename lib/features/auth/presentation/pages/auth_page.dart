import 'package:flutter/material.dart';
import 'package:assetone/shared/widgets/feature_scaffold.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: "Đăng nhập và bảo mật",
      description: "Quản lý truy cập tài khoản và khôi phục mật khẩu của bạn.",
      sections: [
        "Đăng nhập bằng email và mật khẩu",
        "Đăng ký tài khoản",
        "Quên mật khẩu, xác nhận mã và mật khẩu mới",
        "Liên kết Google/Facebook và quản lý phiên",
      ],
    );
  }
}
