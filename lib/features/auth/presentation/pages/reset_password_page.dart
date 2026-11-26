import 'package:flutter/material.dart';
import 'package:assetone/shared/widgets/feature_scaffold.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: "Mật khẩu mới",
      description: "Đặt mật khẩu mới sau khi xác nhận yêu cầu khôi phục.",
      sections: [
        "Nhập mật khẩu mới",
        "Xác nhận mật khẩu",
        "Hiển thị yêu cầu về mật khẩu",
        "Hoàn tất và trở lại đăng nhập",
      ],
    );
  }
}
