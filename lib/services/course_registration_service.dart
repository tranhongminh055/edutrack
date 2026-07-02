import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====== STREAMS (Real-time cho tất cả roles) ======

  /// Stream tất cả môn mở đăng ký theo học kỳ & năm học (có filter theo ngành nếu có)
  Stream<QuerySnapshot> getAvailableCoursesStream(String semester, String academicYear, {String? major}) {
    Query query = _firestore
        .collection('available_courses')
        .where('semester', isEqualTo: semester)
        .where('academicYear', isEqualTo: academicYear)
        .where('status', isEqualTo: 'open');
    if (major != null && major.isNotEmpty) {
      query = query.where('major', isEqualTo: major);
    }
    return query.snapshots();
  }

  /// Stream tất cả môn mở đăng ký (không filter - cho Admin)
  Stream<QuerySnapshot> getAllCoursesStream() {
    return _firestore.collection('available_courses').snapshots();
  }

  /// Stream cho Admin: filter theo semester + year nhưng KHÔNG filter status
  Stream<QuerySnapshot> getAdminCoursesStream(String semester, String academicYear) {
    return _firestore
        .collection('available_courses')
        .where('semester', isEqualTo: semester)
        .where('academicYear', isEqualTo: academicYear)
        .snapshots();
  }

  /// Stream môn đã đăng ký của 1 sinh viên
  Stream<QuerySnapshot> getMyRegistrationsStream(String userId, String semester, String academicYear) {
    return _firestore
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('semester', isEqualTo: semester)
        .where('academicYear', isEqualTo: academicYear)
        .snapshots();
  }

  /// Stream tất cả đăng ký (cho Admin theo dõi)
  Stream<QuerySnapshot> getAllRegistrationsStream({String? semester, String? academicYear}) {
    Query query = _firestore.collection('registrations');
    if (semester != null) query = query.where('semester', isEqualTo: semester);
    if (academicYear != null) query = query.where('academicYear', isEqualTo: academicYear);
    return query.snapshots();
  }

  /// Stream đăng ký theo giảng viên (GV thấy SV đăng ký lớp mình dạy)
  Stream<QuerySnapshot> getRegistrationsByLecturer(String lecturerEmail, {String? semester, String? academicYear}) {
    Query query = _firestore
        .collection('registrations')
        .where('lecturerEmail', isEqualTo: lecturerEmail);
    if (semester != null) query = query.where('semester', isEqualTo: semester);
    if (academicYear != null) query = query.where('academicYear', isEqualTo: academicYear);
    return query.snapshots();
  }

  /// Stream môn mở đăng ký mà GV phụ trách
  Stream<QuerySnapshot> getCoursesByLecturer(String lecturerEmail) {
    return _firestore
        .collection('available_courses')
        .where('lecturerEmail', isEqualTo: lecturerEmail)
        .snapshots();
  }

  // ====== ĐĂNG KÝ MÔN HỌC (Transaction) ======

  /// Đăng ký môn học - sử dụng transaction để tránh race condition
  Future<String> registerCourse({
    required String userId,
    required String studentId,
    required String studentName,
    required String studentEmail,
    required Map<String, dynamic> courseData,
  }) async {
    final courseDocId = courseData['docId'] as String;
    final courseRef = _firestore.collection('available_courses').doc(courseDocId);

    return await _firestore.runTransaction<String>((transaction) async {
      final courseSnapshot = await transaction.get(courseRef);

      if (!courseSnapshot.exists) {
        throw Exception('Môn học không tồn tại');
      }

      final data = courseSnapshot.data()!;
      final currentSlots = (data['currentSlots'] as num?)?.toInt() ?? 0;
      final maxSlots = (data['maxSlots'] as num?)?.toInt() ?? 40;

      if (currentSlots >= maxSlots) {
        throw Exception('Môn học đã đầy slot');
      }

      if (data['status'] != 'open') {
        throw Exception('Môn học đã đóng đăng ký');
      }

      final deadline = data['registrationDeadline'] as Timestamp?;
      if (deadline != null && deadline.toDate().isBefore(DateTime.now())) {
        throw Exception('Đã quá hạn đăng ký môn học này');
      }

      // Tạo registration document
      final regRef = _firestore.collection('registrations').doc();
      transaction.set(regRef, {
        'userId': userId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'courseDocId': courseDocId,
        'courseId': data['courseId'],
        'courseName': data['courseName'],
        'major': data['major'] ?? '',
        'credits': data['credits'],
        'classGroup': data['classGroup'],
        'lecturerName': data['lecturerName'],
        'lecturerEmail': data['lecturerEmail'],
        'semester': data['semester'],
        'academicYear': data['academicYear'],
        'dayOfWeek': data['dayOfWeek'],
        'startHour': data['startHour'],
        'duration': data['duration'],
        'room': data['room'],
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'registered',
      });

      // Tăng currentSlots
      transaction.update(courseRef, {
        'currentSlots': currentSlots + 1,
      });

      return regRef.id;
    });
  }

  /// Hủy đăng ký
  Future<void> cancelRegistration(String registrationId, String courseDocId) async {
    final regRef = _firestore.collection('registrations').doc(registrationId);
    final courseRef = _firestore.collection('available_courses').doc(courseDocId);

    await _firestore.runTransaction((transaction) async {
      final courseSnapshot = await transaction.get(courseRef);

      if (courseSnapshot.exists) {
        final currentSlots = (courseSnapshot.data()!['currentSlots'] as num?)?.toInt() ?? 0;
        transaction.update(courseRef, {
          'currentSlots': (currentSlots - 1).clamp(0, 9999),
        });
      }

      transaction.delete(regRef);
    });
  }

  // ====== KIỂM TRA TRÙNG LỊCH ======

  bool checkTimeConflict({
    required int dayOfWeek,
    required double startHour,
    required double duration,
    required List<Map<String, dynamic>> existingRegistrations,
  }) {
    final newEnd = startHour + duration;
    for (final reg in existingRegistrations) {
      if (reg['dayOfWeek'] == dayOfWeek) {
        final existStart = (reg['startHour'] as num).toDouble();
        final existDuration = (reg['duration'] as num).toDouble();
        final existEnd = existStart + existDuration;
        // Overlap check
        if (startHour < existEnd && newEnd > existStart) {
          return true; // Có xung đột
        }
      }
    }
    return false;
  }

  /// Kiểm tra đã đăng ký môn này chưa
  bool isAlreadyRegistered(String courseDocId, List<Map<String, dynamic>> existingRegistrations) {
    return existingRegistrations.any((reg) => reg['courseDocId'] == courseDocId);
  }

  // ====== ADMIN: Quản lý môn đăng ký ======

  /// Thêm môn mở đăng ký
  Future<void> addAvailableCourse(Map<String, dynamic> courseData) async {
    await _firestore.collection('available_courses').add(courseData);
  }

  /// Đóng/Mở môn đăng ký
  Future<void> toggleCourseStatus(String docId, String newStatus) async {
    await _firestore.collection('available_courses').doc(docId).update({
      'status': newStatus,
    });
  }

  /// Xóa môn đăng ký
  Future<void> deleteCourse(String docId) async {
    // Xóa tất cả registrations liên quan
    final regs = await _firestore
        .collection('registrations')
        .where('courseDocId', isEqualTo: docId)
        .get();
    final batch = _firestore.batch();
    for (var doc in regs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('available_courses').doc(docId));
    await batch.commit();
  }

  // ====== QUẢN LÝ ĐIỂM SỐ (GRADING SYSTEM) ======

  /// Giảng viên lưu nháp hoặc cập nhật điểm thành phần (chuyên cần, giữa kỳ, cuối kỳ)
  Future<void> updateStudentGrade({
    required String regDocId,
    double? attendanceScore,
    double? midtermScore,
    double? finalScore,
    String? status,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (attendanceScore != null) updateData['attendanceScore'] = attendanceScore;
    if (midtermScore != null) updateData['midtermScore'] = midtermScore;
    if (finalScore != null) updateData['finalScore'] = finalScore;
    if (status != null) updateData['gradeStatus'] = status;

    if (updateData.isNotEmpty) {
      await _firestore.collection('registrations').doc(regDocId).update(updateData);
    }
  }

  /// Giảng viên gửi toàn bộ điểm của 1 lớp (môn học) lên cho Admin phê duyệt
  Future<void> submitCourseGradesToAdmin(String courseDocId) async {
    final regs = await _firestore
        .collection('registrations')
        .where('courseDocId', isEqualTo: courseDocId)
        .get();

    final batch = _firestore.batch();
    for (var doc in regs.docs) {
      batch.update(doc.reference, {'gradeStatus': 'lecturer_submitted'});
    }
    await batch.commit();
  }

  /// Tính điểm chữ và hệ 4 từ hệ 10
  Map<String, dynamic> _convertGrade(double total10) {
    if (total10 >= 8.5) return {'letter': 'A', 'gpa4': 4.0};
    if (total10 >= 7.0) return {'letter': 'B', 'gpa4': 3.0};
    if (total10 >= 5.5) return {'letter': 'C', 'gpa4': 2.0};
    if (total10 >= 4.0) return {'letter': 'D', 'gpa4': 1.0};
    return {'letter': 'F', 'gpa4': 0.0};
  }

  /// Admin tính toán điểm tổng hợp và công bố cho sinh viên
  Future<void> calculateAndPublishCourseGrades(String courseDocId) async {
    final regs = await _firestore
        .collection('registrations')
        .where('courseDocId', isEqualTo: courseDocId)
        .get();

    final batch = _firestore.batch();
    for (var doc in regs.docs) {
      final data = doc.data();
      final att = (data['attendanceScore'] as num?)?.toDouble() ?? 0.0;
      final mid = (data['midtermScore'] as num?)?.toDouble() ?? 0.0;
      final fin = (data['finalScore'] as num?)?.toDouble() ?? 0.0;

      // Công thức: 10% Chuyên cần + 20% Giữa kỳ + 70% Cuối kỳ
      final total10 = (att * 0.1) + (mid * 0.2) + (fin * 0.7);
      final totalRounded = double.parse(total10.toStringAsFixed(1));

      final converted = _convertGrade(totalRounded);

      batch.update(doc.reference, {
        'total10': totalRounded,
        'letterGrade': converted['letter'],
        'gpa4': converted['gpa4'],
        'gradeStatus': 'admin_published',
      });
    }
    await batch.commit();
  }

}
