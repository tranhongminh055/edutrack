import React, { useState, useEffect, useRef } from 'react';
import { collection, addDoc, query, where, onSnapshot, serverTimestamp, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../firebase';
import { ArrowLeft, Clock, CheckCircle2, Send, AlertTriangle, FileText, Award, Trash2, Eye, Loader2 } from 'lucide-react';

export default function TakeQuizView({ quiz, role, userId, email, onBack }) {
  const [answers, setAnswers] = useState({});
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [timeLeft, setTimeLeft] = useState(quiz.timeLimitMinutes > 0 ? quiz.timeLimitMinutes * 60 : null);
  const [attempts, setAttempts] = useState([]);
  const [loadingAttempts, setLoadingAttempts] = useState(true);
  const [viewMode, setViewMode] = useState('info'); // 'info' | 'take' | 'result'
  const [lastResult, setLastResult] = useState(null);
  const timerRef = useRef(null);

  // Fetch existing attempts
  useEffect(() => {
    if (!userId) { setLoadingAttempts(false); return; }

    let q;
    if (role === 'student') {
      q = query(
        collection(db, 'elearning_quiz_attempts'),
        where('quizId', '==', quiz.id),
        where('studentId', '==', userId)
      );
    } else {
      // Lecturer sees all attempts
      q = query(
        collection(db, 'elearning_quiz_attempts'),
        where('quizId', '==', quiz.id)
      );
    }

    const unsub = onSnapshot(q, (snap) => {
      setAttempts(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoadingAttempts(false);
    });

    return () => unsub();
  }, [quiz.id, userId, role]);

  // Timer countdown
  useEffect(() => {
    if (viewMode !== 'take' || timeLeft === null || timeLeft <= 0) return;

    timerRef.current = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(timerRef.current);
          handleSubmit();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timerRef.current);
  }, [viewMode, timeLeft]);

  const formatTime = (seconds) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  const handleSubmit = async () => {
    if (submitting) return;
    setSubmitting(true);

    try {
      let score = 0;
      const totalQuestions = quiz.questions.length;

      if (quiz.format === 'multiple_choice') {
        quiz.questions.forEach((q, i) => {
          if (answers[i] === q.correctIndex) score++;
        });
      }

      const attemptData = {
        quizId: quiz.id,
        studentId: userId,
        studentEmail: email,
        answers,
        score,
        totalQuestions,
        format: quiz.format,
        submittedAt: serverTimestamp(),
      };

      await addDoc(collection(db, 'elearning_quiz_attempts'), attemptData);
      setLastResult({ score, totalQuestions });
      setSubmitted(true);
      setViewMode('result');
    } catch (err) {
      console.error('Error submitting:', err);
      alert('Lỗi khi nộp bài!');
    } finally {
      setSubmitting(false);
      if (timerRef.current) clearInterval(timerRef.current);
    }
  };

  const handleDeleteQuiz = async () => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa bài kiểm tra này?')) return;
    try {
      await deleteDoc(doc(db, 'elearning_quizzes', quiz.id));
      onBack();
    } catch (err) {
      console.error('Error deleting quiz:', err);
    }
  };

  const formatMap = {
    'multiple_choice': 'Trắc nghiệm',
    'short_answer': 'Câu hỏi ngắn',
    'essay': 'Tự luận',
  };

  const hasAttempted = attempts.length > 0;

  // ============ INFO VIEW ============
  if (viewMode === 'info') {
    return (
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        <div className="p-6 border-b border-gray-700/50 bg-gray-800/30 shrink-0">
          <button onClick={onBack} className="flex items-center space-x-2 text-gray-400 hover:text-white transition-colors mb-4">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm">Quay lại danh sách</span>
          </button>
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-bold text-white">{quiz.title}</h2>
            {role === 'lecturer' && (
              <button onClick={handleDeleteQuiz} className="flex items-center space-x-2 px-4 py-2 bg-red-600/20 hover:bg-red-600/30 border border-red-500/30 text-red-400 rounded-xl transition-all text-sm font-medium">
                <Trash2 className="w-4 h-4" />
                <span>Xóa bài thi</span>
              </button>
            )}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Quiz Info Card */}
          <div className="bg-gray-800/50 border border-gray-700/50 rounded-2xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4">Thông tin bài kiểm tra</h3>
            <div className="grid grid-cols-2 gap-4">
              <InfoItem label="Loại" value={formatMap[quiz.format] || 'N/A'} />
              <InfoItem label="Số câu hỏi" value={`${quiz.questions?.length || 0} câu`} />
              <InfoItem label="Thời gian" value={quiz.timeLimitMinutes > 0 ? `${quiz.timeLimitMinutes} phút` : 'Không giới hạn'} />
              <InfoItem label="Ngày tạo" value={quiz.createdAt?.toDate?.()?.toLocaleDateString('vi-VN') || 'N/A'} />
            </div>
            {quiz.description && (
              <div className="mt-4 pt-4 border-t border-gray-700">
                <p className="text-sm text-gray-400">{quiz.description}</p>
              </div>
            )}
          </div>

          {/* Action Button (Student) */}
          {role === 'student' && (
            <div className="flex items-center justify-center">
              <button
                onClick={() => {
                  setViewMode('take');
                  setAnswers({});
                  setSubmitted(false);
                  setTimeLeft(quiz.timeLimitMinutes > 0 ? quiz.timeLimitMinutes * 60 : null);
                }}
                className="px-8 py-3 bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-500 hover:to-blue-400 text-white rounded-xl transition-all font-semibold text-lg shadow-lg shadow-blue-900/40 flex items-center space-x-3"
              >
                <FileText className="w-5 h-5" />
                <span>{hasAttempted ? 'Làm lại bài thi' : 'Bắt đầu làm bài'}</span>
              </button>
            </div>
          )}

          {/* Lecturer: Preview questions */}
          {role === 'lecturer' && (
            <div className="bg-gray-800/50 border border-gray-700/50 rounded-2xl p-6">
              <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
                <Eye className="w-5 h-5 text-blue-400" />
                <span>Xem trước nội dung đề thi</span>
              </h3>
              <div className="space-y-4">
                {quiz.questions?.map((q, i) => (
                  <div key={i} className="bg-gray-900/50 border border-gray-700 rounded-xl p-4">
                    <p className="text-white font-medium mb-2">
                      <span className="text-blue-400 mr-2">Câu {i + 1}.</span>
                      {q.text}
                    </p>
                    {quiz.format === 'multiple_choice' && q.options && (
                      <div className="space-y-1 ml-6">
                        {q.options.map((opt, oi) => (
                          <div key={oi} className={`flex items-center space-x-2 text-sm ${oi === q.correctIndex ? 'text-green-400 font-semibold' : 'text-gray-400'}`}>
                            <span>{String.fromCharCode(65 + oi)}.</span>
                            <span>{opt}</span>
                            {oi === q.correctIndex && <CheckCircle2 className="w-3.5 h-3.5" />}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Attempts History */}
          <div className="bg-gray-800/50 border border-gray-700/50 rounded-2xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
              <Award className="w-5 h-5 text-amber-400" />
              <span>{role === 'lecturer' ? 'Danh sách bài nộp của Sinh viên' : 'Lịch sử làm bài'}</span>
            </h3>
            {loadingAttempts ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="w-6 h-6 animate-spin text-blue-500" />
              </div>
            ) : attempts.length === 0 ? (
              <p className="text-gray-500 text-sm text-center py-6">Chưa có bài nộp nào.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-700">
                      <th className="text-left py-3 text-gray-400 font-medium">Lần</th>
                      {role === 'lecturer' && <th className="text-left py-3 text-gray-400 font-medium">Email SV</th>}
                      {quiz.format === 'multiple_choice' && <th className="text-left py-3 text-gray-400 font-medium">Điểm</th>}
                      <th className="text-left py-3 text-gray-400 font-medium">Thời gian nộp</th>
                      {role === 'lecturer' && quiz.format !== 'multiple_choice' && <th className="text-left py-3 text-gray-400 font-medium">Xem bài</th>}
                    </tr>
                  </thead>
                  <tbody>
                    {attempts.map((att, i) => (
                      <tr key={att.id} className="border-b border-gray-700/50 hover:bg-gray-700/20">
                        <td className="py-3 text-gray-300">#{i + 1}</td>
                        {role === 'lecturer' && <td className="py-3 text-gray-300">{att.studentEmail || 'N/A'}</td>}
                        {quiz.format === 'multiple_choice' && (
                          <td className="py-3">
                            <span className={`font-bold ${att.score / att.totalQuestions >= 0.5 ? 'text-green-400' : 'text-red-400'}`}>
                              {att.score}/{att.totalQuestions}
                            </span>
                          </td>
                        )}
                        <td className="py-3 text-gray-400">{att.submittedAt?.toDate?.()?.toLocaleString('vi-VN') || 'N/A'}</td>
                        {role === 'lecturer' && quiz.format !== 'multiple_choice' && (
                          <td className="py-3">
                            <button
                              onClick={() => setLastResult(att)}
                              className="text-blue-400 hover:text-blue-300 text-xs font-medium"
                            >
                              Xem chi tiết
                            </button>
                          </td>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Lecturer viewing a student's essay/short answer */}
          {role === 'lecturer' && lastResult && lastResult.answers && quiz.format !== 'multiple_choice' && (
            <div className="bg-gray-800/50 border border-blue-500/30 rounded-2xl p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Chi tiết bài làm — {lastResult.studentEmail}</h3>
                <button onClick={() => setLastResult(null)} className="text-gray-400 hover:text-white text-sm">Đóng</button>
              </div>
              {quiz.questions?.map((q, i) => (
                <div key={i} className="mb-4 bg-gray-900/50 border border-gray-700 rounded-xl p-4">
                  <p className="text-white font-medium mb-2"><span className="text-blue-400 mr-1">Câu {i + 1}.</span> {q.text}</p>
                  <div className="bg-gray-800 border border-gray-600 rounded-lg p-3">
                    <p className="text-gray-300 text-sm whitespace-pre-wrap">{lastResult.answers[i] || <span className="text-gray-600 italic">Không trả lời</span>}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  }

  // ============ TAKE VIEW (Student Only) ============
  if (viewMode === 'take') {
    return (
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        {/* Sticky Header with Timer */}
        <div className="p-5 border-b border-gray-700/50 bg-gray-800/50 backdrop-blur-md shrink-0">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <button onClick={() => { if (window.confirm('Bạn có muốn thoát? Bài làm sẽ không được lưu.')) { setViewMode('info'); clearInterval(timerRef.current); }}} className="p-2 hover:bg-gray-700 rounded-lg transition-colors">
                <ArrowLeft className="w-5 h-5 text-gray-400" />
              </button>
              <h2 className="text-lg font-bold text-white">{quiz.title}</h2>
            </div>
            {timeLeft !== null && (
              <div className={`flex items-center space-x-2 px-4 py-2 rounded-xl font-mono text-lg font-bold ${timeLeft < 60 ? 'bg-red-500/20 text-red-400 border border-red-500/30 animate-pulse' : 'bg-gray-700/50 text-white border border-gray-600/50'}`}>
                <Clock className="w-5 h-5" />
                <span>{formatTime(timeLeft)}</span>
              </div>
            )}
          </div>
          {/* Progress bar */}
          <div className="mt-3 h-1.5 bg-gray-700 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-blue-500 to-cyan-400 rounded-full transition-all duration-300"
              style={{ width: `${(Object.keys(answers).length / (quiz.questions?.length || 1)) * 100}%` }}
            />
          </div>
          <p className="text-xs text-gray-500 mt-1.5">
            Đã trả lời {Object.keys(answers).filter(k => answers[k] !== undefined && answers[k] !== '').length}/{quiz.questions?.length || 0} câu
          </p>
        </div>

        {/* Questions */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {quiz.questions?.map((q, qIndex) => (
            <div key={qIndex} className="bg-gray-800/50 border border-gray-700/50 rounded-2xl p-6">
              <p className="text-white font-semibold text-base mb-4">
                <span className="inline-flex items-center justify-center w-7 h-7 bg-blue-500/20 text-blue-400 rounded-lg text-xs font-bold mr-3">{qIndex + 1}</span>
                {q.text}
              </p>

              {quiz.format === 'multiple_choice' && (
                <div className="space-y-2 ml-10">
                  {q.options.map((opt, oIndex) => {
                    const isSelected = answers[qIndex] === oIndex;
                    return (
                      <button
                        key={oIndex}
                        onClick={() => setAnswers(prev => ({ ...prev, [qIndex]: oIndex }))}
                        className={`w-full text-left px-4 py-3 rounded-xl border-2 transition-all duration-200 flex items-center space-x-3 ${
                          isSelected
                            ? 'border-blue-500 bg-blue-500/10 shadow-lg shadow-blue-900/10'
                            : 'border-gray-700 bg-gray-900/30 hover:border-gray-500 hover:bg-gray-800/50'
                        }`}
                      >
                        <span className={`flex items-center justify-center w-7 h-7 rounded-full border-2 text-xs font-bold shrink-0 ${
                          isSelected ? 'border-blue-500 bg-blue-500 text-white' : 'border-gray-600 text-gray-400'
                        }`}>
                          {String.fromCharCode(65 + oIndex)}
                        </span>
                        <span className={`text-sm ${isSelected ? 'text-blue-300' : 'text-gray-300'}`}>{opt}</span>
                      </button>
                    );
                  })}
                </div>
              )}

              {quiz.format === 'short_answer' && (
                <div className="ml-10">
                  <input
                    type="text"
                    value={answers[qIndex] || ''}
                    onChange={(e) => setAnswers(prev => ({ ...prev, [qIndex]: e.target.value }))}
                    placeholder="Nhập câu trả lời ngắn gọn..."
                    className="w-full px-4 py-3 bg-gray-900/50 border border-gray-600 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-sm"
                  />
                </div>
              )}

              {quiz.format === 'essay' && (
                <div className="ml-10">
                  <textarea
                    value={answers[qIndex] || ''}
                    onChange={(e) => setAnswers(prev => ({ ...prev, [qIndex]: e.target.value }))}
                    placeholder="Nhập bài làm tự luận của bạn tại đây..."
                    rows={6}
                    className="w-full px-4 py-3 bg-gray-900/50 border border-gray-600 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-sm resize-y"
                  />
                  <p className="text-xs text-gray-500 mt-1">{(answers[qIndex] || '').length} ký tự</p>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Submit Footer */}
        <div className="p-5 border-t border-gray-700/50 bg-gray-800/50 backdrop-blur-md shrink-0">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2 text-amber-400">
              <AlertTriangle className="w-4 h-4" />
              <span className="text-xs">Kiểm tra kỹ trước khi nộp bài. Bài nộp không thể chỉnh sửa.</span>
            </div>
            <button
              onClick={handleSubmit}
              disabled={submitting}
              className="flex items-center space-x-2 px-8 py-3 bg-gradient-to-r from-green-600 to-emerald-500 hover:from-green-500 hover:to-emerald-400 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl font-semibold shadow-lg shadow-green-900/30 transition-all"
            >
              {submitting ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
              <span>{submitting ? 'Đang nộp...' : 'Nộp bài'}</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ============ RESULT VIEW ============
  if (viewMode === 'result' && lastResult) {
    const percent = quiz.format === 'multiple_choice' ? Math.round((lastResult.score / lastResult.totalQuestions) * 100) : null;
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-10">
        <div className="bg-gray-800/50 border border-gray-700/50 rounded-3xl p-10 text-center max-w-md w-full shadow-2xl">
          <div className={`w-24 h-24 mx-auto rounded-full flex items-center justify-center mb-6 ${
            percent !== null
              ? percent >= 50 ? 'bg-green-500/20 border-2 border-green-500/50' : 'bg-red-500/20 border-2 border-red-500/50'
              : 'bg-blue-500/20 border-2 border-blue-500/50'
          }`}>
            {percent !== null ? (
              percent >= 50 
                ? <CheckCircle2 className="w-12 h-12 text-green-400" /> 
                : <AlertTriangle className="w-12 h-12 text-red-400" />
            ) : (
              <CheckCircle2 className="w-12 h-12 text-blue-400" />
            )}
          </div>
          
          <h2 className="text-2xl font-bold text-white mb-2">
            {quiz.format === 'multiple_choice' 
              ? (percent >= 50 ? 'Chúc mừng! 🎉' : 'Hãy cố gắng hơn!')
              : 'Đã nộp bài thành công! ✅'
            }
          </h2>
          
          {quiz.format === 'multiple_choice' && (
            <div className="my-6">
              <div className="text-5xl font-black text-white">{lastResult.score}/{lastResult.totalQuestions}</div>
              <div className="text-lg text-gray-400 mt-1">{percent}% đúng</div>
            </div>
          )}

          {quiz.format !== 'multiple_choice' && (
            <p className="text-gray-400 my-4">Bài làm của bạn đã được gửi đến giảng viên để chấm điểm.</p>
          )}

          <button
            onClick={() => { setViewMode('info'); setLastResult(null); }}
            className="mt-4 px-8 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-medium transition-colors"
          >
            Quay lại
          </button>
        </div>
      </div>
    );
  }

  return null;
}

function InfoItem({ label, value }) {
  return (
    <div className="bg-gray-900/50 rounded-xl p-4 border border-gray-700/50">
      <p className="text-xs text-gray-500 mb-1">{label}</p>
      <p className="text-white font-semibold">{value}</p>
    </div>
  );
}
