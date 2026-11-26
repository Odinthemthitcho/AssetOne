import 'package:flutter/material.dart';
import 'package:assetone/shared/widgets/feature_scaffold.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: "Quên mật khẩu",
      description: "Dùng email đã đăng ký để khôi phục tài khoản.",
      sections: [
        "Nhập email đã đăng ký",
        "Yêu cầu mã xác nhận",
        "Thông báo kết quả gửi mã",
        "Trở lại đăng nhập",
      ],
    );
  }
}
