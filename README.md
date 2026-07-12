# EduTrack - Hệ thống Quản lý Giáo dục Thông minh

EduTrack là một nền tảng quản lý giáo dục toàn diện được xây dựng bằng **Flutter Web** kết hợp với **Firebase**. Dự án cung cấp môi trường tương tác trực tuyến cho Sinh viên, Giảng viên và Quản trị viên (Admin) nhằm theo dõi tiến độ học tập, quản lý học phí, và vận hành hệ thống E-Learning một cách trực quan, hiện đại.

## 🌟 Tính năng nổi bật

### 1. Hệ thống Phân quyền (Role-based Access)
- **Quản trị viên (Admin):** Quản lý tổng thể người dùng, phê duyệt tài khoản mới, duyệt biên lai học phí, theo dõi trạng thái hoạt động và lịch sử đăng nhập (real-time).
- **Giảng viên (Lecturer):** Quản lý lớp học, đăng tải tài liệu, tạo bài kiểm tra (Quiz) trên hệ thống E-Learning, chấm điểm và đánh giá tiến độ của sinh viên.
- **Sinh viên (Student):** Đăng ký tín chỉ, thanh toán học phí (hỗ trợ thanh toán từng phần), tham gia khóa học, làm bài kiểm tra và theo dõi kết quả học tập.

### 2. Bảo mật & Xác thực (Firebase Auth)
- Đăng nhập/Đăng ký an toàn với mã hóa dữ liệu.
- Tính năng **Khóa tài khoản tạm thời** (tự động khóa và hiển thị đếm ngược nếu nhập sai mật khẩu 5 lần).
- Hỗ trợ thao tác phím Enter để đăng nhập trên nền tảng Web.

### 3. Quản lý Học phí Nâng cao
- Tự động tính toán học phí dư nợ khi đăng ký/hủy môn học.
- Hỗ trợ tải lên (upload) ảnh chụp biên lai giao dịch thông qua cơ chế mã hóa **Base64** giúp tối ưu lưu trữ và vượt qua các giới hạn CORS của trình duyệt.
- Quản trị viên kiểm duyệt, thay đổi trạng thái (Pending -> Paid -> Unpaid) trực tiếp trên Dashboard.

### 4. Môi trường E-Learning Tích hợp
- Tích hợp Forum (Diễn đàn) trao đổi.
- Thư viện điện tử (e-Lib) và Hệ thống Email nội bộ (Mail Client).
- Chức năng Export dữ liệu điểm số, thông tin môn học.

## 🛠 Nền tảng Công nghệ
- **Frontend:** Flutter (tối ưu hóa cho môi trường Web - `flutter build web`).
- **Backend & Database:** Firebase Authentication, Cloud Firestore (NoSQL).
- **State Management & UI:** Cấu trúc Stateful/Stateless Widget tiêu chuẩn, tích hợp hệ thống Animation mượt mà.
- **CI/CD:** Sử dụng GitHub Actions để tự động build lỗi và cảnh báo qua Webhook khi có commit mới trên các nhánh.

---

## 🚀 Hướng dẫn cài đặt và chạy dự án

### Yêu cầu hệ thống
- Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản `stable`, khuyến nghị từ bản 3.22 trở lên).
- Trình duyệt Google Chrome, Edge hoặc trình duyệt hỗ trợ Web/Wasm.
- Visual Studio Code hoặc Android Studio.

### Các bước chạy cục bộ (Local Development)

1. **Clone kho lưu trữ về máy:**
   ```bash
   git clone https://github.com/tranhongminh055/edutrack.git
   cd edutrack
   ```

2. **Cài đặt các gói thư viện (Dependencies):**
   Mở terminal trong thư mục dự án và chạy lệnh:
   ```bash
   flutter pub get
   ```

3. **Chạy dự án ở chế độ phát triển (Debug Mode):**
   Do EduTrack được định hướng là ứng dụng Web, hãy chọn thiết bị chạy là `Chrome`:
   ```bash
   flutter run -d chrome
   ```
   *(Hệ thống sẽ tự động mở một tab mới trên trình duyệt hiển thị giao diện dự án)*.

4. **Biên dịch dự án ra phiên bản Web (Production Build):**
   Để xuất bản ứng dụng lên các host (như Firebase Hosting, Vercel, GitHub Pages), chạy lệnh:
   ```bash
   flutter build web
   ```
   Thư mục chứa kết quả build sẽ nằm tại `build/web/`.

### 💡 Lưu ý về Quy trình Git
Dự án được phân chia thành 4 nhánh chính: `main`, `backend`, `frontend`, `tester`. 
Để đảm bảo CI/CD hoạt động trơn tru (không bị báo lỗi đỏ), GitHub Actions đã được thiết lập để tự động chạy lệnh `flutter build web` sau mỗi commit. Vui lòng đảm bảo code của bạn không có lỗi cú pháp trước khi Push.

---
*Phát triển và duy trì bởi đội ngũ EduTrack.*
