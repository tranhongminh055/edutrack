import {
  collection,
  addDoc,
  doc,
  setDoc,
  getDoc,
  updateDoc,
  serverTimestamp,
  query,
  where,
  getDocs,
} from 'firebase/firestore';
import { db } from '../firebase';
import { getAuth } from 'firebase/auth';

// Minimal quiz service helpers. These are safe, small wrappers around Firestore
// operations. They do not modify existing components; they only provide a
// developer-friendly API for creating quizzes, saving drafts and submitting.

export async function createQuiz(quiz) {
  if (!quiz) throw new Error('quiz required');
  const creatorId = quiz.userId || getAuth().currentUser?.uid;
  if (!creatorId) throw new Error('not authenticated');

  const { userId, ...cleanQuiz } = quiz;

  const payload = {
    ...cleanQuiz,
    createdBy: creatorId,
    createdAt: serverTimestamp(),
    published: !!quiz.published,
  };

  const ref = await addDoc(collection(db, 'elearning_quizzes'), payload);
  return ref.id;
}

export async function getQuiz(quizId) {
  if (!quizId) throw new Error('quizId required');
  const ref = doc(db, 'elearning_quizzes', quizId);
  const snap = await getDoc(ref);
  return snap.exists() ? { id: snap.id, ...snap.data() } : null;
}

export async function saveDraft(quizId, userId, draft) {
  if (!quizId || !userId) throw new Error('quizId and userId required');
  const id = `${userId}_${quizId}`;
  const ref = doc(db, 'quiz_drafts', id);
  await setDoc(ref, { quizId, userId, answers: draft, updatedAt: serverTimestamp() }, { merge: true });
}

export async function startSubmission(quizId, userId) {
  if (!quizId || !userId) throw new Error('quizId and userId required');
  const ref = await addDoc(collection(db, 'quiz_submissions'), {
    quizId,
    userId,
    answers: [],
    startedAt: serverTimestamp(),
    submittedAt: null,
    timeTakenSeconds: null,
    score: null,
    graded: false,
  });
  return ref.id;
}

function computeScore(quiz, answers) {
  if (!quiz || !quiz.questions) return 0;
  const qmap = new Map();
  // Map by explicit id when present, otherwise fall back to index-based keys
  quiz.questions.forEach((q, idx) => {
    if (q && q.id) qmap.set(q.id, q);
    qmap.set(String(idx), q);
  });
  let total = 0;
  let earned = 0;
  quiz.questions.forEach(q => { total += (q.points || 1); });

  answers.forEach(a => {
    const q = qmap.get(a.questionId);
    if (!q) return;
    const points = q.points || 1;
    if (q.type === 'multiple_choice' || quiz.format === 'multiple_choice') {
      if (
        q.correctIndex !== undefined && q.correctIndex !== null &&
        String(a.answer) === String(q.correctIndex)
      ) {
        earned += points;
      }
    }
    // other types left for manual grading
  });
  // normalize to 0..100
  return total === 0 ? 0 : Math.round((earned / total) * 100);
}

const GEMINI_API_KEY = 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c';

/**
 * AI-grade essay/short_answer quizzes using Gemini 1.5 Flash with advanced analysis.
 * Returns { score (0-100), feedback, perQuestion: [{ score, comment }], plagiarismScore, qualityMetrics }
 */
export async function aiGradeQuiz(quiz, answersMap) {
  if (!quiz || !quiz.questions) return null;

  const questionsText = quiz.questions.map((q, i) => {
    const studentAnswer = answersMap[i] !== undefined ? String(answersMap[i]) : '(Không trả lời)';
    const answerLength = String(answersMap[i] || '').length;
    return `Câu ${i + 1}: ${q.text}\nĐộ dài câu trả lời: ${answerLength} ký tự\nTrả lời của sinh viên: ${studentAnswer}`;
  }).join('\n\n');

  const prompt = `Bạn là một giảng viên đại học chuyên nghiệp với kinh nghiệm chấm điểm và phát hiện đạo văn. Hãy chấm điểm bài kiểm tra sau một cách chi tiết và khách quan:

Tên bài kiểm tra: ${quiz.title}
Loại: ${quiz.format === 'essay' ? 'Tự luận' : 'Câu hỏi ngắn'}
Tổng số câu: ${quiz.questions.length}

${questionsText}

Nhiệm vụ chấm điểm:
1. Chấm điểm từng câu từ 0-10 điểm dựa trên:
   - Độ đầy đủ của câu trả lời (30%)
   - Tính chính xác của nội dung (40%)
   - Cấu trúc và logic (20%)
   - Ngôn ngữ và trình bày (10%)
   
2. Đánh giá chất lượng bài làm:
   - Mức độ hiểu bài (0-100)
   - Độ sâu phân tích (0-100)
   - Tính sáng tạo (0-100)
   
3. Phát hiện đạo văn:
   - Đánh giá mức độ độc đáo của câu trả lời (0-100, 100 là hoàn toàn độc đáo)
   - Ghi chú nếu phát hiện dấu hiệu đạo văn

4. Đưa ra nhận xét chi tiết bằng tiếng Việt:
   - Nhận xét tổng quan về bài làm
   - Điểm mạnh và điểm cần cải thiện
   - Gợi ý cải thiện

Trả về DUY NHẤT JSON (không markdown, không code block):
{
  "score": <số 0-100>,
  "feedback": "<nhận xét tổng quan chi tiết tiếng Việt>",
  "perQuestion": [
    {
      "score": <0-10>,
      "comment": "<nhận xét chi tiết tiếng Việt>",
      "strengths": ["điểm mạnh 1", "điểm mạnh 2"],
      "improvements": ["cải thiện 1", "cải thiện 2"]
    }
  ],
  "qualityMetrics": {
    "understanding": <0-100>,
    "depth": <0-100>,
    "creativity": <0-100>
  },
  "plagiarismScore": <0-100, 100 là độc đáo>,
  "plagiarismWarning": "<cảnh báo nếu có dấu hiệu đạo văn, hoặc null>"
}`;

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.3,
            topP: 0.95,
            topK: 40
          }
        })
      }
    );
    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini API error:', response.status, errorText);
      throw new Error('Gemini API request failed');
    }
    const data = await response.json();
    const rawText = data.candidates[0].content.parts[0].text;
    const parsed = JSON.parse(rawText.trim());

    // Validate and sanitize the response
    const result = {
      score: Math.min(100, Math.max(0, parsed.score || 0)),
      feedback: parsed.feedback || 'Không có nhận xét.',
      perQuestion: Array.isArray(parsed.perQuestion) ? parsed.perQuestion.map(pq => ({
        score: Math.min(10, Math.max(0, pq.score || 0)),
        comment: pq.comment || 'Không có nhận xét.',
        strengths: Array.isArray(pq.strengths) ? pq.strengths : [],
        improvements: Array.isArray(pq.improvements) ? pq.improvements : []
      })) : [],
      qualityMetrics: parsed.qualityMetrics || {
        understanding: 0,
        depth: 0,
        creativity: 0
      },
      plagiarismScore: Math.min(100, Math.max(0, parsed.plagiarismScore || 100)),
      plagiarismWarning: parsed.plagiarismWarning || null
    };

    return result;
  } catch (err) {
    console.warn('Gemini AI grading failed, using intelligent fallback:', err);

    // Intelligent fallback based on answer analysis
    const perQuestion = quiz.questions.map((q, i) => {
      const ans = answersMap[i] || '';
      const ansStr = String(ans).trim();
      const len = ansStr.length;
      const wordCount = ansStr.split(/\s+/).filter(w => w.length > 0).length;

      // Analyze answer quality
      let score = 0;
      const strengths = [];
      const improvements = [];

      if (len === 0) {
        score = 0;
        improvements.push('Chưa trả lời câu hỏi');
      } else {
        // Length-based scoring with quality factors
        if (len >= 100) {
          score = 7;
          strengths.push('Câu trả lời có độ dài tốt');
        } else if (len >= 50) {
          score = 6;
          strengths.push('Câu trả lời đầy đủ ý chính');
          improvements.push('Cần bổ sung thêm chi tiết và phân tích');
        } else if (len >= 20) {
          score = 5;
          improvements.push('Câu trả lời cơ bản, cần mở rộng hơn');
        } else {
          score = 3;
          improvements.push('Câu trả lời quá ngắn, cần bổ sung phân tích');
        }

        // Bonus for longer, detailed answers
        if (len >= 200) {
          score = Math.min(10, score + 1);
          strengths.push('Câu trả lời chi tiết và đầy đủ');
        }

        // Check for question keywords (simple relevance check)
        const questionWords = q.text.toLowerCase().split(/\s+/).filter(w => w.length > 3);
        const answerLower = ansStr.toLowerCase();
        const matchedKeywords = questionWords.filter(word => answerLower.includes(word));

        if (matchedKeywords.length > questionWords.length * 0.3) {
          score = Math.min(10, score + 1);
          strengths.push('Câu trả lời liên quan đến câu hỏi');
        } else {
          improvements.push('Câu trả lời cần tập trung hơn vào câu hỏi');
        }
      }

      return {
        score: Math.min(10, Math.max(0, score)),
        comment: len === 0 ? 'Không có câu trả lời.' :
          score >= 7 ? 'Câu trả lời khá tốt, đạt yêu cầu cơ bản.' :
            score >= 5 ? 'Câu trả lời cần cải thiện thêm.' :
              'Câu trả lời chưa đạt yêu cầu.',
        strengths,
        improvements
      };
    });

    const avgScore = Math.round(perQuestion.reduce((s, p) => s + p.score, 0) / perQuestion.length * 10);

    return {
      score: Math.min(100, Math.max(0, avgScore)),
      feedback: '[Hệ thống AI tạm thời bận] Điểm được đánh giá tự động dựa trên độ dài và độ phù hợp của câu trả lời. Giảng viên sẽ xem xét và điều chỉnh điểm sau.',
      perQuestion,
      qualityMetrics: {
        understanding: avgScore,
        depth: Math.max(0, avgScore - 10),
        creativity: Math.max(0, avgScore - 15)
      },
      plagiarismScore: 100,
      plagiarismWarning: null
    };
  }
}

export async function submitQuiz({ submissionId = null, quizId, userId, studentEmail = '', answers = [], startedAt = null, answersMap = null, courseDocId = null }) {
  if (!quizId || !userId) throw new Error('quizId and userId required');

  const quiz = await getQuiz(quizId);
  if (!quiz) throw new Error('quiz not found');

  let score = computeScore(quiz, answers);
  let aiFeedback = null;
  let aiPerQuestion = null;
  let graded = true;

  // For essay/short_answer, use AI grading
  let aiResult = null;
  if (quiz.format !== 'multiple_choice' && answersMap) {
    try {
      aiResult = await aiGradeQuiz(quiz, answersMap);
      if (aiResult) {
        score = aiResult.score;
        aiFeedback = aiResult.feedback;
        aiPerQuestion = aiResult.perQuestion;
      }
    } catch (err) {
      console.error('AI grading error:', err);
      graded = false;
    }
  }

  const payload = {
    quizId,
    userId,
    studentEmail: studentEmail || '',
    answers,
    startedAt: startedAt || null,
    submittedAt: serverTimestamp(),
    timeTakenSeconds: null,
    score,
    totalQuestions: quiz.questions?.length || 0,
    graded,
    ...(courseDocId ? { courseDocId } : {}),
    ...(aiFeedback ? { aiFeedback } : {}),
    ...(aiPerQuestion ? { aiPerQuestion } : {}),
    ...(aiResult?.qualityMetrics ? { qualityMetrics: aiResult.qualityMetrics } : {}),
    ...(aiResult?.plagiarismScore !== undefined ? { plagiarismScore: aiResult.plagiarismScore } : {}),
    ...(aiResult?.plagiarismWarning ? { plagiarismWarning: aiResult.plagiarismWarning } : {}),
  };

  const attemptPayload = {
    quizId,
    studentId: userId,
    studentEmail: studentEmail || '',
    score,
    totalQuestions: quiz.questions?.length || 0,
    submittedAt: serverTimestamp(),
    answers,
    courseDocId,
    aiGrading: aiResult ? {
      score: aiResult.score,
      feedback: aiResult.feedback,
      perQuestion: aiResult.perQuestion,
      qualityMetrics: aiResult.qualityMetrics || null,
      plagiarismScore: aiResult.plagiarismScore ?? 100,
      plagiarismWarning: aiResult.plagiarismWarning || null
    } : null
  };
  await addDoc(collection(db, 'elearning_quiz_attempts'), attemptPayload);

  if (submissionId) {
    const ref = doc(db, 'quiz_submissions', submissionId);
    await updateDoc(ref, payload);
    return {
      id: submissionId,
      score,
      aiFeedback,
      aiPerQuestion,
      qualityMetrics: aiResult?.qualityMetrics || null,
      plagiarismScore: aiResult?.plagiarismScore ?? 100,
      plagiarismWarning: aiResult?.plagiarismWarning || null
    };
  }

  const ref = await addDoc(collection(db, 'quiz_submissions'), payload);
  return {
    id: ref.id,
    score,
    aiFeedback,
    aiPerQuestion,
    qualityMetrics: aiResult?.qualityMetrics || null,
    plagiarismScore: aiResult?.plagiarismScore ?? 100,
    plagiarismWarning: aiResult?.plagiarismWarning || null
  };
}

/**
 * Sync quiz grades to registrations & EduTrack student_grades
 * Uses latest quiz submission for grade calculation
 */
export async function syncQuizGradesToGradebook(studentEmail, courseDocId, manualScoresOrScore = null) {
  try {
    let manualScores = null;
    if (manualScoresOrScore && typeof manualScoresOrScore === 'object') {
      manualScores = manualScoresOrScore;
    }

    // Find registration matching studentEmail & courseDocId
    const qReg = query(collection(db, 'registrations'), where('courseDocId', '==', courseDocId), where('studentEmail', '==', studentEmail));
    const regSnap = await getDocs(qReg);
    if (regSnap.empty) return;
    const regDoc = regSnap.docs[0];
    const regData = regDoc.data();
    const studentId = regData.studentId;

    // Fetch all assignments for this course
    const qAssigns = query(collection(db, 'elearning_assignments'), where('courseDocId', '==', courseDocId));
    const assignsSnap = await getDocs(qAssigns);
    const assignmentsList = assignsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Fetch all assignment submissions by this student
    const qAssignSubs = query(collection(db, 'elearning_submissions'), where('courseDocId', '==', courseDocId), where('userEmail', '==', studentEmail));
    const assignSubsSnap = await getDocs(qAssignSubs);
    const assignSubsList = assignSubsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Fetch all quiz submissions by this student
    const qQuizSubs = query(collection(db, 'quiz_submissions'), where('courseDocId', '==', courseDocId), where('studentEmail', '==', studentEmail));
    const quizSubsSnap = await getDocs(qQuizSubs);
    const quizSubsList = quizSubsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Group assignment submissions by assignmentId and get latest
    const latestAssignSubs = {};
    assignSubsList.forEach(s => {
      const assignId = s.assignmentId;
      if (!latestAssignSubs[assignId]) latestAssignSubs[assignId] = [];
      latestAssignSubs[assignId].push(s);
    });

    let totalPtsScored = 0;
    let count = 0;

    assignmentsList.forEach(a => {
      const subs = latestAssignSubs[a.id] || [];
      if (subs.length > 0) {
        subs.sort((x, y) => {
          const timeX = x.submittedAt?.toDate ? x.submittedAt.toDate() : (x.submittedAt ? new Date(x.submittedAt) : new Date(0));
          const timeY = y.submittedAt?.toDate ? y.submittedAt.toDate() : (y.submittedAt ? new Date(y.submittedAt) : new Date(0));
          return timeY - timeX;
        });
        const latest = subs[0];
        if (latest && latest.status === 'graded' && latest.score !== undefined && latest.score !== null) {
          totalPtsScored += (latest.score / (a.points || 10)) * 10;
          count++;
        }
      }
    });

    // Group quiz submissions by quizId and get latest
    const latestQuizSubs = {};
    quizSubsList.forEach(s => {
      const quizId = s.quizId;
      if (!latestQuizSubs[quizId]) latestQuizSubs[quizId] = [];
      latestQuizSubs[quizId].push(s);
    });

    Object.keys(latestQuizSubs).forEach(quizId => {
      const subs = latestQuizSubs[quizId];
      subs.sort((x, y) => {
        const timeX = x.submittedAt?.toDate ? x.submittedAt.toDate() : (x.submittedAt ? new Date(x.submittedAt) : new Date(0));
        const timeY = y.submittedAt?.toDate ? y.submittedAt.toDate() : (y.submittedAt ? new Date(y.submittedAt) : new Date(0));
        return timeY - timeX;
      });
      const latest = subs[0];
      if (latest && latest.score !== undefined && latest.score !== null) {
        totalPtsScored += (latest.score / 100) * 10;
        count++;
      }
    });

    const avgScore = count > 0 ? parseFloat((totalPtsScored / count).toFixed(1)) : null;

    // Determine att, mid, fin
    let att = avgScore;
    if (manualScores && manualScores.attendanceScore !== undefined && manualScores.attendanceScore !== null) {
      att = manualScores.attendanceScore;
    } else if (att === null) {
      att = regData.attendanceScore !== undefined ? Number(regData.attendanceScore) : 10.0;
    }

    let mid = regData.midtermScore !== undefined ? Number(regData.midtermScore) : 8.0;
    if (manualScores && manualScores.midtermScore !== undefined && manualScores.midtermScore !== null) {
      mid = manualScores.midtermScore;
    }

    let fin = regData.finalScore !== undefined ? Number(regData.finalScore) : 8.0;
    if (manualScores && manualScores.finalScore !== undefined && manualScores.finalScore !== null) {
      fin = manualScores.finalScore;
    }

    const newTotal10 = parseFloat(((att * 0.1) + (mid * 0.2) + (fin * 0.7)).toFixed(1));

    const getLetterGrade = (total) => {
      if (total >= 8.5) return 'A';
      if (total >= 7.0) return 'B';
      if (total >= 5.5) return 'C';
      if (total >= 4.0) return 'D';
      return 'F';
    };

    const getGPA4 = (letter) => {
      if (letter === 'A') return 4.0;
      if (letter === 'B') return 3.0;
      if (letter === 'C') return 2.0;
      if (letter === 'D') return 1.0;
      return 0.0;
    };

    const letterGrade = getLetterGrade(newTotal10);
    const gpa4 = getGPA4(letterGrade);

    const gradeStatus = (manualScores && manualScores.gradeStatus) || regData.gradeStatus || 'admin_published';

    // Update registrations
    await updateDoc(doc(db, 'registrations', regDoc.id), {
      attendanceScore: att,
      midtermScore: mid,
      finalScore: fin,
      total10: newTotal10,
      letterGrade,
      gpa4,
      gradeStatus
    });

    // Sync to EduTrack student_grades
    if (studentId) {
      const studentGradesRef = doc(db, 'student_grades', studentId);
      const studentGradesSnap = await getDoc(studentGradesRef);
      if (studentGradesSnap.exists()) {
        const sgData = studentGradesSnap.data();
        let semesters = sgData.semesters || [];
        let docUpdated = false;

        semesters = semesters.map(sem => {
          let courses = sem.courses || [];
          let courseUpdated = false;

          courses = courses.map(c => {
            if (c.courseDocId === courseDocId || c.courseId === regData.courseId) {
              courseUpdated = true;
              docUpdated = true;
              return {
                ...c,
                grade10: newTotal10,
                gradeChar: letterGrade,
                grade4: gpa4
              };
            }
            return c;
          });

          if (courseUpdated) {
            // Recalculate summary
            let totalCredits = 0;
            let sum10 = 0;
            let sum4 = 0;
            courses.forEach(c => {
              const creds = Number(c.credits || 0);
              totalCredits += creds;
              sum10 += Number(c.grade10 || 0) * creds;
              sum4 += Number(c.grade4 || 0) * creds;
            });
            const avg10 = totalCredits > 0 ? parseFloat((sum10 / totalCredits).toFixed(2)) : 0;
            const avg4 = totalCredits > 0 ? parseFloat((sum4 / totalCredits).toFixed(2)) : 0;

            return {
              ...sem,
              courses,
              summary: { totalCredits, avg10, avg4 }
            };
          }
          return sem;
        });

        if (docUpdated) {
          await updateDoc(studentGradesRef, { semesters });
        }
      }
    }
  } catch (err) {
    console.error('Sync grades failed:', err);
  }
}

/**
 * Analyze student activity patterns during quiz
 */
export async function analyzeStudentActivity(quizId, userId) {
  try {
    // Fetch cheating logs for this student
    const logsQuery = query(
      collection(db, 'elearning_cheating_logs'),
      where('quizId', '==', quizId),
      where('studentId', '==', userId)
    );

    // This would need to be called with onSnapshot or getDocs in the component
    // For now, return a helper function
    return {
      getViolationCount: (logs) => logs.filter(l => l.studentId === userId).length,
      getViolationTypes: (logs) => {
        const userLogs = logs.filter(l => l.studentId === userId);
        return [...new Set(userLogs.map(l => l.type))];
      },
      getRiskLevel: (violationCount) => {
        if (violationCount === 0) return 'low';
        if (violationCount <= 2) return 'medium';
        return 'high';
      }
    };
  } catch (err) {
    console.error('Error analyzing activity:', err);
    return null;
  }
}

export default {
  createQuiz,
  getQuiz,
  saveDraft,
  startSubmission,
  submitQuiz,
  aiGradeQuiz,
  analyzeStudentActivity,
  syncQuizGradesToGradebook,
};
