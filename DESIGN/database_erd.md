# Sơ đồ Thực thể - Liên kết (Entity-Relationship Diagram) - EduTrack Database (Firestore NoSQL)

Dưới đây là sơ đồ thiết kế cơ sở dữ liệu (ERD) thể hiện cấu trúc các Bộ sưu tập (Collections) và sự liên kết giữa các thực thể trong hệ thống EduTrack. Mặc dù sử dụng Cloud Firestore (NoSQL), chúng ta vẫn có thể ánh xạ và liên kết chúng thông qua các khóa ngoại (Foreign Keys) như `uid`, `courseId`, `studentId`, `lecturerId`.

```mermaid
erDiagram
    USERS {
        string uid PK "Mã định danh (UID từ Firebase Auth)"
        string email "Email nội bộ"
        string name "Họ và tên"
        string role "Vai trò: student, lecturer, admin"
        string phone "Số điện thoại"
        string avatarUrl "Đường dẫn ảnh đại diện"
        timestamp createdAt "Ngày tạo tài khoản"
    }

    COURSES {
        string courseId PK "Mã học phần"
        string courseName "Tên học phần"
        string lecturerId FK "UID của Giảng viên"
        int credits "Số tín chỉ"
        float price "Đơn giá/tín chỉ"
        string schedule "Lịch học (T2, T3...)"
        string semester "Học kỳ"
    }

    REGISTRATIONS {
        string regId PK "Mã đăng ký (Document ID)"
        string courseId FK "Mã học phần"
        string studentId FK "UID của Sinh viên"
        float attendanceScore "Điểm chuyên cần (10%)"
        float midtermScore "Điểm giữa kỳ (30%)"
        float finalScore "Điểm cuối kỳ (60%)"
        float totalScore "Điểm tổng kết"
        string status "Trạng thái (Đang học, Hoàn thành)"
    }

    TUITION_FEES {
        string feeId PK "Mã hóa đơn học phí"
        string courseId FK "Mã học phần"
        string studentId FK "UID của Sinh viên"
        int credits "Số tín chỉ"
        float totalAmount "Tổng tiền (= credits * price)"
        string status "Trạng thái: unpaid, pending, paid"
        string receiptBase64 "Chuỗi Base64 của ảnh biên lai"
    }

    ELEARNING_QUIZZES {
        string quizId PK "Mã bài thi trắc nghiệm"
        string courseId FK "Mã học phần"
        string title "Tiêu đề bài thi"
        int timeLimit "Thời gian làm bài (Phút)"
        timestamp deadline "Ngày hết hạn"
        array questions "Mảng chứa [Câu hỏi, A, B, C, D, Đáp án đúng]"
    }

    QUIZ_RESULTS {
        string resultId PK "Mã kết quả bài thi"
        string quizId FK "Mã bài thi"
        string studentId FK "UID của Sinh viên"
        float score "Điểm số (Thang 10)"
        timestamp submitTime "Thời gian nộp bài"
        array answers "Mảng các câu trả lời của sinh viên"
    }

    POSTS {
        string postId PK "Mã bài viết"
        string courseId FK "Mã lớp học phần (Nơi đăng)"
        string senderId FK "UID của người gửi"
        string content "Nội dung bài đăng / bình luận"
        timestamp timestamp "Thời gian đăng bài"
    }

    MAILS {
        string mailId PK "Mã thư điện tử"
        string senderEmail "Email người gửi"
        string receiverEmail "Email người nhận"
        string subject "Tiêu đề thư"
        string content "Nội dung văn bản"
        boolean isRead "Trạng thái đọc (true/false)"
        timestamp timestamp "Thời gian gửi"
    }

    %% Relationships Definition
    USERS ||--o{ COURSES : "giảng dạy (Lecturer)"
    USERS ||--o{ REGISTRATIONS : "đăng ký (Student)"
    COURSES ||--o{ REGISTRATIONS : "chứa"
    
    USERS ||--o{ TUITION_FEES : "đóng học phí (Student)"
    COURSES ||--o{ TUITION_FEES : "phát sinh"
    
    COURSES ||--o{ ELEARNING_QUIZZES : "tổ chức"
    ELEARNING_QUIZZES ||--o{ QUIZ_RESULTS : "lưu trữ"
    USERS ||--o{ QUIZ_RESULTS : "làm bài (Student)"
    
    COURSES ||--o{ POSTS : "có diễn đàn"
    USERS ||--o{ POSTS : "viết bài"
    
    USERS ||--o{ MAILS : "gửi/nhận"
```

### Chú thích:
- `PK` (Primary Key): Khóa chính định danh tài liệu trong Collection.
- `FK` (Foreign Key): Tham chiếu đến một tài liệu ở Collection khác để thiết lập mối quan hệ.
- Mặc dù đây là CSDL NoSQL (Cloud Firestore), sơ đồ ERD vẫn giúp hình dung rõ sự phân bổ dữ liệu và mối quan hệ logic giữa các thực thể, hỗ trợ cho việc thiết kế các truy vấn (`where`, `orderBy`).
