# 4.4.3. Sơ đồ Tuần tự (Sequence Diagram) - Phân hệ Quản lý Lớp học & Nhập Điểm

Dưới đây là sơ đồ tuần tự thể hiện chi tiết 2 luồng xử lý chính của phân hệ Quản lý Lớp học và Nhập điểm dành cho Giảng viên:
1. **Luồng xem danh sách lớp:** Giảng viên xem các lớp được phân công và danh sách sinh viên trong một lớp cụ thể.
2. **Luồng nhập điểm:** Giảng viên nhập điểm thành phần, hệ thống tự động tính điểm tổng kết và cập nhật dữ liệu lên Firestore.

```mermaid
sequenceDiagram
    autonumber
    actor Lecturer as Giảng viên
    participant UI as EduTrack UI
    participant Firestore as Cloud Firestore

    rect rgb(240, 248, 255)
        note right of Lecturer: Luồng 1: Xem danh sách lớp
        Lecturer->>UI: Truy cập mục "Lớp học của tôi"
        UI->>UI: Lấy lecturerId từ tài khoản đăng nhập
        UI->>Firestore: Truy vấn COURSES where('lecturerId', '==', currentUid)
        Firestore-->>UI: Trả về danh sách các lớp học phần
        UI-->>Lecturer: Hiển thị danh sách lớp học
        Lecturer->>UI: Chọn một lớp học cụ thể
        UI->>Firestore: Truy vấn REGISTRATIONS (theo courseId)
        Firestore-->>UI: Trả về danh sách sinh viên đăng ký
        UI->>UI: Sắp xếp danh sách theo bảng chữ cái (Tên)
        UI-->>Lecturer: Hiển thị bảng danh sách sinh viên
    end

    rect rgb(255, 245, 238)
        note right of Lecturer: Luồng 2: Nhập điểm và tính toán
        UI-->>Lecturer: Cung cấp Data Grid (Chuyên cần, Giữa kỳ, Cuối kỳ)
        Lecturer->>UI: Nhập điểm cho sinh viên
        Lecturer->>UI: Nhấn phím Tab (hoặc click ra ngoài)
        UI->>UI: Tính Điểm tổng kết = (CC*0.1) + (GK*0.3) + (CK*0.6)
        UI->>Firestore: Cập nhật document trong REGISTRATIONS (điểm TP, điểm tổng kết)
        Firestore-->>UI: Xác nhận lưu thành công
        UI-->>Lecturer: Hiển thị điểm tổng kết vừa tính toán
    end
```
