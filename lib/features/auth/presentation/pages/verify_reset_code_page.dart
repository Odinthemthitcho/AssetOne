import 'package:flutter/material.dart';
import 'package:assetone/shared/widgets/feature_scaffold.dart';

class VerifyResetCodePage extends StatelessWidget {
  const VerifyResetCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: "Xác nhận mã",
      description: "Xác nhận yêu cầu khôi phục mật khẩu.",
      sections: [
        "Nhập mã nhận qua email",
        "Thời gian còn hiệu lực",
        "Gửi lại mã và thời gian chờ",
        "Tiếp tục đến mật khẩu mới",
      ],
    );
  }
}
