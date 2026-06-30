import 'package:cloud_firestore/cloud_firestore.dart';

class ELearningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Online Class Link ---
  Stream<DocumentSnapshot> getOnlineClassLinkStream(String courseDocId) {
    return _firestore.collection('elearning_links').doc(courseDocId).snapshots();
  }

  Future<void> updateOnlineClassLink(String courseDocId, String link, String password) async {
    await _firestore.collection('elearning_links').doc(courseDocId).set({
      'meetingLink': link,
      'meetingPassword': password,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- Materials (Resources) ---
  Stream<QuerySnapshot> getMaterialsStream(String courseDocId) {
    return _firestore
        .collection('elearning_materials')
        .where('courseDocId', isEqualTo: courseDocId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addMaterial(String courseDocId, String title, String description, String fileUrl) async {
    await _firestore.collection('elearning_materials').add({
      'courseDocId': courseDocId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMaterial(String materialId) async {
    await _firestore.collection('elearning_materials').doc(materialId).delete();
  }

  // --- Assignments ---
  Stream<QuerySnapshot> getAssignmentsStream(String courseDocId) {
    return _firestore
        .collection('elearning_assignments')
        .where('courseDocId', isEqualTo: courseDocId)
        .orderBy('deadline', descending: false)
        .snapshots();
  }

  Future<void> addAssignment(String courseDocId, String title, String description, DateTime deadline) async {
    await _firestore.collection('elearning_assignments').add({
      'courseDocId': courseDocId,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> deleteAssignment(String assignmentId) async {
    await _firestore.collection('elearning_assignments').doc(assignmentId).delete();
  }

  // --- Submissions ---
  Stream<QuerySnapshot> getSubmissionsStream(String assignmentId) {
    return _firestore
        .collection('elearning_submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentSubmissionStream(String assignmentId, String studentId) {
    return _firestore
        .collection('elearning_submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  Future<void> submitAssignment(String assignmentId, String studentId, String fileUrl) async {
    // Upsert submission
    final query = await _firestore
        .collection('elearning_submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'fileUrl': fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('elearning_submissions').add({
        'assignmentId': assignmentId,
        'studentId': studentId,
        'fileUrl': fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
        'grade': null,
      });
    }
  }

  Future<void> gradeSubmission(String submissionId, double grade) async {
    await _firestore.collection('elearning_submissions').doc(submissionId).update({
      'grade': grade,
    });
  }

  // --- Quizzes ---
  Stream<QuerySnapshot> getQuizzesStream(String courseDocId) {
    return _firestore
        .collection('elearning_quizzes')
        .where('courseDocId', isEqualTo: courseDocId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addQuiz(String courseDocId, String title, int timeLimitMinutes, List<Map<String, dynamic>> questions) async {
    await _firestore.collection('elearning_quizzes').add({
      'courseDocId': courseDocId,
      'title': title,
      'timeLimitMinutes': timeLimitMinutes,
      'questions': questions,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> deleteQuiz(String quizId) async {
    await _firestore.collection('elearning_quizzes').doc(quizId).delete();
  }
  
  // Quiz attempts
  Stream<QuerySnapshot> getStudentQuizAttempts(String quizId, String studentId) {
    return _firestore
        .collection('elearning_quiz_attempts')
        .where('quizId', isEqualTo: quizId)
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  Future<void> submitQuizAttempt(String quizId, String studentId, int score, int totalQuestions) async {
    await _firestore.collection('elearning_quiz_attempts').add({
      'quizId': quizId,
      'studentId': studentId,
      'score': score,
      'totalQuestions': totalQuestions,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }
}
