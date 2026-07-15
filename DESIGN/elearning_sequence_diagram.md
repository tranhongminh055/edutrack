# 4.5.3. Sơ đồ Tuần tự (Sequence Diagram) - Phân hệ E-Learning & Làm Bài kiểm tra

Dưới đây là sơ đồ tuần tự thể hiện chi tiết 3 luồng xử lý chính của phân hệ E-Learning & Làm bài kiểm tra:
1. **Luồng tạo đề thi:** Giảng viên khởi tạo bài trắc nghiệm với thời gian, câu hỏi và đáp án.
2. **Luồng làm bài thi:** Sinh viên bắt đầu làm bài với đồng hồ đếm ngược được kích hoạt.
3. **Luồng nộp bài và tự động chấm điểm:** Hệ thống thu thập bài làm, so khớp đáp án, tính điểm và lưu kết quả.

```mermaid
sequenceDiagram
    autonumber
    actor Lecturer as Giảng viên
    actor Student as Sinh viên
    participant UI as EduTrack UI
    participant Firestore as Cloud Firestore

    rect rgb(240, 248, 255)
        note right of Lecturer: Luồng 1: Tạo đề thi (Giảng viên)
        Lecturer->>UI: Chọn "Tạo bài tập trắc nghiệm"
        Lecturer->>UI: Nhập tiêu đề, thời gian (vd: 45p), Deadline
        Lecturer->>UI: Thêm câu hỏi (Nội dung, 4 đáp án, Đáp án đúng)
        Lecturer->>UI: Nhấn "Lưu bài thi"
        UI->>Firestore: Đẩy dữ liệu vào collection ELEARNING_QUIZZES
        Firestore-->>UI: Xác nhận tạo bài thi thành công
        UI-->>Lecturer: Hiển thị thông báo thành công
    end

    rect rgb(255, 245, 238)
        note right of Student: Luồng 2: Làm bài thi (Sinh viên)
        Student->>UI: Click chọn bài thi
        UI-->>Student: Hiển thị Popup xác nhận
        Student->>UI: Nhấn "Bắt đầu làm bài"
        UI->>UI: Kích hoạt đồng hồ đếm ngược (Timer.periodic)
        UI-->>Student: Hiển thị giao diện bài làm & Đồng hồ đếm ngược
        loop Quá trình làm bài
            Student->>UI: Chọn các đáp án (A, B, C, D)
        end
    end

    rect rgb(240, 255, 240)
        note right of Student: Luồng 3: Nộp bài và Tự động chấm điểm
        alt Nhấn nộp bài
            Student->>UI: Nhấn "Nộp bài"
        else Hết thời gian
            UI->>UI: Đồng hồ đếm ngược về mốc 00:00
        end
        UI->>UI: Khóa quyền tương tác/chọn đáp án
        UI->>UI: Thu thập mảng câu trả lời của sinh viên
        UI->>UI: So khớp mảng câu trả lời với mảng đáp án đúng
        UI->>UI: Tính Điểm = (Số câu đúng / Tổng câu) * 10
        UI->>Firestore: Ghi nhận kết quả vào sub-collection QUIZ_RESULTS
        Firestore-->>UI: Xác nhận lưu kết quả thành công
        UI-->>Student: Hiển thị điểm số và kết quả bài làm ngay lập tức
    end
```
