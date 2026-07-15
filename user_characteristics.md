# Sơ đồ Đặc điểm Người dùng (User Characteristics)

Sơ đồ dưới đây thể hiện 3 nhóm người dùng chính trong hệ thống EduTrack và quyền hạn/chức năng tương ứng của họ. Bạn có thể sử dụng mã Mermaid này cho các trình hiển thị Markdown chuẩn.

```mermaid
mindmap
  root((EduTrack Users))
    Admin["Quản trị viên (Admin)"]
      ::icon(fa fa-shield)
      QuanLyHeThong["Quản lý toàn bộ hệ thống"]
      KiemDuyetTaiKhoan["Phê duyệt/Khóa tài khoản"]
      DuyetHocPhi["Kiểm duyệt biên lai học phí"]
      PhanQuyen["Phân quyền người dùng"]
    Lecturer["Giảng viên (Lecturer)"]
      ::icon(fa fa-graduation-cap)
      QuanLyLop["Quản lý lớp học & Sinh viên"]
      TaiLieu["Đăng tải tài liệu học tập"]
      BaiKiemTra["Tạo bài tập / Quiz (E-Learning)"]
      ChamDiem["Chấm điểm & Đánh giá"]
    Student["Sinh viên (Student)"]
      ::icon(fa fa-user)
      HocTap["Tham gia các khóa học"]
      DangKy["Đăng ký môn học / Tín chỉ"]
      ThanhToan["Thanh toán & Nộp biên lai học phí"]
      LamBai["Làm bài kiểm tra & Xem điểm"]
```

### Hướng dẫn:
Sơ đồ dạng Mindmap này rất phù hợp để minh họa các đặc tả chức năng phân quyền. 
Vì bạn yêu cầu lưu trực tiếp ra file `.md`, bạn có thể mở file này bằng Visual Studio Code (hoặc các phần mềm đọc Markdown) và cài thêm Extension có tên là **Markdown Preview Mermaid Support** để xem ảnh vẽ ngay lập tức nhé! Hoặc copy đoạn code vào `mermaid.live` để tải ảnh PNG.
