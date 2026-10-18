# Mini-Project 3: Receipt OCR & Expense Tracker

> **Ứng dụng Quản lý Chi tiêu & Quét Hóa đơn OCR cho Sinh viên và Ban chủ nhiệm CLB VKU**

---

## 📌 1. Giới thiệu Bài toán (Scenario)
Sinh viên và các nhà quản lý câu lạc bộ tại VKU phải xử lý nhiều hóa đơn tiền mặt hàng ngày (mua văn phòng phẩm, sự kiện CLB, ăn uống, di chuyển,...). Việc nhập thủ công các con số vào bảng tính rất tốn thời gian và dễ xảy ra sai sót.

Dự án này mang đến giải pháp di động toàn diện **production-ready**, tự động hóa chu trình: **Chụp ảnh ➔ OCR Offline trên thiết bị ➔ Bóc tách Regex ➔ Màn hình đối soát (Review) ➔ Lưu SQLite ➔ Vẽ biểu đồ thống kê bằng Canvas**.

---

## 🚀 2. Luồng Kiến Trúc Kỹ Thuật (Pipeline Architecture)

```
[Camera / Gallery Capture]  (image_picker)
            │
            ▼
[Google ML Kit OCR]         (google_mlkit_text_recognition - Offline on-device)
            │
            ▼
[Dart Regex Parser Engine]  (Bóc tách thông minh: Total, Date, Merchant, Category)
            │
            ▼
[Review & Verification]     (Màn hình đối soát & chỉnh sửa trước khi lưu)
            │
            ▼
[Local SQLite Storage]      (sqflite DB: CRUD, lịch sử, lọc danh mục)
            │
            ▼
[Custom Canvas Charts]      (CustomPainter: Donut Chart & 7-Day Bar Chart)
```

---

## 🛠️ 3. Công nghệ & Thư viện Sử dụng

* **Framework**: Flutter 3.x / Dart 3.x (Material 3)
* **Camera Capture**: `image_picker`
* **On-device OCR**: `google_mlkit_text_recognition` (Latin Script tối ưu tiếng Việt và tiếng Anh)
* **Local Database**: `sqflite`, `path`
* **Date & Currency Formatter**: `intl`
* **Canvas Graphics**: `CustomPainter` vẽ biểu đồ trực tiếp trên Canvas Flutter (Donut Chart & Bar Chart)

---

## 📂 4. Cấu trúc Thư mục Dự án

```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart      # SQLite DB: Tạo bảng, CRUD, truy vấn thống kê, seed data
│   └── utils/
│       ├── currency_format.dart      # Format tiền tệ VNĐ (₫, VND)
│       └── date_format.dart          # Format ngày tháng (dd/MM/yyyy)
├── models/
│   ├── expense_category.dart         # Enum danh mục: Ăn uống, Sự kiện CLB, Văn phòng phẩm,...
│   └── expense_item.dart             # Model ExpenseItem & SQLite serialization
├── services/
│   ├── receipt_parser.dart           # Regex Engine bóc tách Total, Date, Merchant, gợi ý danh mục
│   └── ocr_service.dart              # On-device ML Kit Text Recognition wrapper
├── presentation/
│   ├── screens/
│   │   ├── home_dashboard_screen.dart # Dashboard tổng chi tiêu tháng, danh sách gần đây
│   │   ├── scan_receipt_screen.dart   # Màn hình ngắm quét camera, thư viện, demo scan
│   │   ├── review_receipt_screen.dart # Màn hình xác nhận, chỉnh sửa, chọn danh mục
│   │   ├── expense_list_screen.dart   # Sổ quỹ đầy đủ, tìm kiếm, lọc danh mục, xóa
│   │   └── statistics_screen.dart     # Báo cáo phân tích chi tiêu
│   └── widgets/
│       ├── custom_donut_chart.dart    # Biểu đồ tròn Donut vẽ bằng CustomPainter
│       ├── custom_bar_chart.dart      # Biểu đồ cột 7 ngày vẽ bằng CustomPainter
│       └── expense_card.dart          # Card giao diện từng hóa đơn
└── main.dart                          # App Entrypoint
```

---

## 🧪 5. Kiểm thử & Đảm bảo Chất lượng

Chạy toàn bộ Unit & Widget Tests:
```bash
flutter test
```
* **Regex Engine Tests**: Đã kiểm tra bóc tách chính xác các hóa đơn thực tế (Nhà sách Fahasa, Highlands Coffee, Thiết bị sự kiện).
* **Custom Canvas Widget Tests**: Kiểm tra CustomPaint vẽ Donut & Bar chart hoàn hảo.

---

## 📱 6. Hướng dẫn Chạy Ứng dụng

1. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```
2. **Trải nghiệm các tính năng chính**:
   * **Quét Hóa Đơn**: Nhấn nút "Quét Hóa Đơn" trên màn hình chính ➔ Chụp ảnh hóa đơn thực tế từ Camera hoặc chọn từ Thư viện ảnh (hoặc bấm **Demo Quét** để kiểm tra ngay lập tức).
   * **Xác Nhận (Review Screen)**: Kiểm tra thông tin đã trích xuất (Tên cửa hàng, Số tiền, Ngày tháng, Danh mục gợi ý tự động), có thể mở rộng xem văn bản OCR gốc ➔ Nhấn **Lưu Hóa Đơn Vào Sổ Quỹ**.
   * **Sổ Quỹ**: Xem toàn bộ lịch sử, tìm kiếm theo từ khóa, lọc theo từng danh mục chi tiêu, vuốt để xóa.
   * **Biểu Đồ**: Xem phân bổ chi tiêu bằng **Donut Chart** và xu hướng 7 ngày gần nhất bằng **Bar Chart** được vẽ bằng Custom Canvas.
