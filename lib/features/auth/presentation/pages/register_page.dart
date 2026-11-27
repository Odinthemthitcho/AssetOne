import 'package:flutter/material.dart';
import 'package:assetone/shared/widgets/feature_scaffold.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: "Tạo tài khoản",
      description: "Bắt đầu quản lý tài sản và danh mục đầu tư.",
      sections: [
        "Họ và tên, email",
        "Mật khẩu và xác nhận mật khẩu",
        "Kiểm tra thông tin đăng ký",
        "Google, Facebook hoặc trở lại đăng nhập",
      ],
    );
  }
}
