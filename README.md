# AssetOne

Ứng dụng Flutter tiếng Việt để theo dõi danh mục tài sản, tài khoản tiền và dư nợ. Bản này lưu dữ liệu trên thiết bị. Hồ sơ đăng ký bắt đầu với danh mục trống; **Khám phá ngay** mở danh mục khách có dữ liệu minh họa trong bản phát triển.

## Chạy ứng dụng

1. Giải nén và mở cả thư mục `AssetOne` trong Android Studio. Thư mục cần có `pubspec.yaml`, `lib/` và `android/`. Trên máy đã cài Android Studio có thể bấm đúp `Mo_AssetOne_Android_Studio.cmd`.
2. Mở **Device Manager**, khởi động một Android Emulator, rồi chọn thiết bị trong thanh công cụ.
3. Chọn cấu hình **AssetOne Android** và bấm **Run**. Trong ứng dụng, chọn **Bỏ qua → Khám phá ngay** để xem dữ liệu minh họa, hoặc **Tạo tài khoản** để tự nhập dữ liệu.

Nếu chạy từ PowerShell, mở terminal ngay trong thư mục chứa `pubspec.yaml`.

```powershell
flutter pub get
flutter devices
flutter run -t lib/main_development.dart
```

Thư mục có dấu tiếng Việt có thể gây lỗi với Gradle trên Windows. Có thể dùng trình mở Android Studio đi kèm hoặc giải nén mã nguồn vào thư mục ngắn như `C:\Dev\AssetOne`.

## Các thao tác chính

- Mở **Tài khoản** từ biểu tượng ví để thêm tài khoản, ghi nhận nạp, rút, chuyển nội bộ và chọn tài khoản chính.
- Bấm **+** hoặc mở một nhóm tài sản từ tổng quan. Có 14 biểu mẫu cho 13 loại tài sản và khoản nợ. Trong chi tiết hồ sơ có thao tác phù hợp với loại đang xem như mua, bán, định giá, trả nợ hoặc tất toán sổ tiền gửi.
- **Giao dịch** có tìm kiếm và lọc dòng tiền. **Thị trường** hiển thị định giá đã lưu và thời điểm ghi nhận. **Cá nhân** có tùy chọn ẩn số dư. Mục **Nhắc hạn** lấy các mốc đã nhập trong hồ sơ.
- Trên Android, chọn chứng từ PDF, PNG hoặc JPG và mở lại từ chi tiết hồ sơ. Ứng dụng lưu quyền đọc tệp do Android cấp, nên tệp cần còn ở nơi lưu ban đầu.

Tài sản ròng bằng tổng giá trị tài khoản tiền và tài sản theo phần sở hữu, trừ dư nợ gốc. Chuyển giữa hai tài khoản không được tính thành dòng tiền vào hoặc ra toàn danh mục. Trả lãi và phí làm giảm tiền thanh toán; chỉ phần trả gốc làm giảm dư nợ. Giá trị bảo vệ của hợp đồng bảo hiểm được lưu riêng với giá trị hoàn lại.

## Mã nguồn

| Vị trí | Nội dung |
| --- | --- |
| `lib/main_development.dart` | Điểm vào bản phát triển |
| `lib/app/shell/asset_one_root.dart` | Khởi động, giới thiệu và mở phiên |
| `lib/app/shell/portfolio_shell.dart` | Tổng quan và điều hướng chính |
| `lib/features/auth/` | Tạo hồ sơ, đăng nhập, đặt lại mật khẩu trên thiết bị |
| `lib/features/portfolio/` | Biểu mẫu, danh mục, mô hình và sổ giao dịch |
| `lib/features/accounts/presentation/pages/cash_accounts_page.dart` | Tài khoản tiền và nạp, rút, chuyển |
| `lib/features/overview/auxiliary_pages.dart` | Giao dịch, định giá, nhắc hạn và cá nhân |
| `lib/core/storage/` | Lưu cục bộ trên thiết bị hoặc trong trình duyệt |
| `docs/requirements/screen-map.md` | Đối chiếu 44 trang PDF |
| `database/schema/assetone_sqlserver_fixed.sql` | Lược đồ SQL Server tham khảo |

Các README feature cũ và `THU_TU_LAM_ASSETONE.md` mô tả bộ khung ban đầu. Xem bảng trên để tìm điểm vào của ứng dụng hiện tại.

## Phạm vi tích hợp

- Đăng nhập bằng Google hoặc Facebook, gửi mã qua email, đồng bộ qua SQL Server và báo giá trực tiếp cần dịch vụ bên ngoài. Luồng đặt lại mật khẩu cục bộ hiển thị mã thử ngay trên màn hình.
- Các giao dịch là bản ghi theo dõi. Dữ liệu cập nhật định giá, mốc nhắc và thiết lập tái tục được lưu trên thiết bị. Các lệnh thị trường, chuyển tiền ngân hàng, tái tục và thông báo đẩy cần tích hợp riêng.
- Giao diện lấy bảng màu, biểu tượng và bố cục theo tài liệu, sử dụng phông hệ thống và thành phần Flutter dùng chung. Tính năng chọn tệp được triển khai trên Android.

## Kiểm tra

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
flutter test
flutter build apk --debug -t lib/main_development.dart
```
