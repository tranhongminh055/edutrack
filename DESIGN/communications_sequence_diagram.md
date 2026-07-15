# 4.6.3. Sơ đồ Tuần tự (Sequence Diagram) - Phân hệ Hệ thống Giao tiếp: Diễn đàn & Thư điện tử

Dưới đây là sơ đồ tuần tự thể hiện chi tiết 2 luồng xử lý chính của phân hệ Giao tiếp nội bộ (Diễn đàn và Thư điện tử):
1. **Luồng hoạt động của Diễn đàn (Forum):** Thể hiện khả năng viết bài mới và tự động cập nhật dữ liệu (Timeline) theo thời gian thực dựa trên luồng dữ liệu (Stream) của Firestore.
2. **Luồng hoạt động của Thư điện tử nội bộ (Mail):** Thể hiện việc gửi thư giữa các tài khoản EduTrack và hệ thống cảnh báo thư mới chưa đọc (Chấm đỏ).

```mermaid
sequenceDiagram
    autonumber
    actor User as Giảng viên/Sinh viên
    actor Recipient as Người nhận
    participant UI as EduTrack UI
    participant Firestore as Cloud Firestore
    participant RecipientUI as EduTrack UI (Người nhận)

    rect rgb(240, 248, 255)
        note right of User: Luồng 1: Hành vi Diễn đàn (Forum) - Cập nhật Realtime
        User->>UI: Truy cập Diễn đàn lớp học
        UI->>Firestore: Lắng nghe Stream (Realtime snapshot) từ collection POSTS
        Firestore-->>UI: Trả về danh sách bài viết hiện tại
        UI-->>User: Hiển thị Timeline bài viết
        User->>UI: Viết bài mới / Bình luận & Nhấn "Gửi"
        UI->>Firestore: Thêm document vào POSTS (Nội dung, timestamp, courseId)
        Firestore-->>UI: Xác nhận gửi thành công
        Firestore-->>UI: Kích hoạt Stream (Có dữ liệu mới)
        UI-->>User: Tự động cập nhật Timeline lên đầu trang (Không cần tải lại)
    end

    rect rgb(255, 245, 238)
        note right of User: Luồng 2: Hành vi Thư điện tử nội bộ (Mail Client)
        User->>UI: Mở chức năng "Soạn thư mới"
        User->>UI: Nhập Email người nhận, Tiêu đề, Nội dung
        User->>UI: Nhấn "Gửi"
        UI->>Firestore: Tạo document trong MAILS (isRead: false, receiverEmail)
        Firestore-->>UI: Xác nhận gửi thư thành công
        UI-->>User: Hiển thị thông báo "Đã gửi thư"
        
        note right of Firestore: Lắng nghe Realtime từ phía Người nhận
        Firestore-->>RecipientUI: Kích hoạt thay đổi state (Có thư mới trong MAILS)
        RecipientUI->>RecipientUI: Kiểm tra có document mang isRead: false
        RecipientUI-->>Recipient: Hiển thị cảnh báo chấm đỏ ở biểu tượng Hộp thư
    end
```
