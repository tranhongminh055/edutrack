# 4.3.3. Sơ đồ Tuần tự (Sequence Diagram) - Phân hệ Quản lý & Thanh toán Học phí

Dưới đây là sơ đồ tuần tự thể hiện chi tiết 3 luồng xử lý chính của phân hệ Quản lý và Thanh toán học phí:
1. **Luồng tạo hóa đơn:** Hệ thống tự động tính học phí và tạo bản ghi sau khi sinh viên đăng ký môn học.
2. **Luồng nộp biên lai:** Sinh viên tải ảnh biên lai, ứng dụng chuyển thành chuỗi Base64 và lưu lên Cloud Firestore.
3. **Luồng phê duyệt:** Kế toán xem ảnh biên lai đã giải mã, đối chiếu và phê duyệt. Trạng thái cập nhật realtime tới sinh viên.

```mermaid
sequenceDiagram
    autonumber
    actor Student as Sinh viên
    participant UI_Student as EduTrack UI (Student)
    participant Firestore as Cloud Firestore
    participant UI_Admin as EduTrack UI (Admin)
    actor Admin as Admin/Kế toán

    rect rgb(240, 248, 255)
        note right of Student: Luồng 1: Tạo hóa đơn học phí (Tự động)
        Firestore->>Firestore: Kích hoạt hàm tính TotalAmount = sum(tín chỉ) * đơn giá
        Firestore->>Firestore: Tạo document trong TUITION_FEES (status = 'unpaid')
    end

    rect rgb(255, 245, 238)
        note right of Student: Luồng 2: Sinh viên nộp biên lai
        Student->>Student: Chuyển khoản ngân hàng & Chụp màn hình
        Student->>UI_Student: Nhấn nút "Tải lên biên lai"
        UI_Student-->>Student: Mở trình chọn tệp (File Picker)
        Student->>UI_Student: Chọn tệp ảnh (.png/.jpg)
        UI_Student->>UI_Student: Chuyển đổi tệp ảnh thành chuỗi Base64
        UI_Student->>Firestore: Update document (receiptBase64 = [chuỗi], status = 'pending')
        Firestore-->>UI_Student: Xác nhận cập nhật thành công
        UI_Student-->>Student: Báo cáo "Biên lai đã tải lên, đang chờ duyệt"
    end

    rect rgb(240, 255, 240)
        note right of Admin: Luồng 3: Phê duyệt của Admin/Kế toán
        Admin->>UI_Admin: Truy cập phân hệ "Duyệt học phí"
        UI_Admin->>Firestore: Truy vấn documents có status = 'pending'
        Firestore-->>UI_Admin: Trả về danh sách học phí chờ duyệt
        Admin->>UI_Admin: Nhấn chọn 1 dòng (bản ghi học phí)
        UI_Admin->>UI_Admin: Giải mã chuỗi receiptBase64
        UI_Admin-->>Admin: Hiển thị Popup hình ảnh biên lai rõ nét
        Admin->>Admin: Đối chiếu mã giao dịch với tài khoản ngân hàng
        Admin->>UI_Admin: Nhấn nút "Phê duyệt"
        UI_Admin->>Firestore: Update document (status = 'paid')
        Firestore-->>UI_Admin: Xác nhận cập nhật thành công
        Firestore-->>UI_Student: Real-time Stream: thông báo thay đổi dữ liệu
        UI_Student-->>Student: Cập nhật giao diện: chữ "Đã thanh toán" màu xanh
    end
```
