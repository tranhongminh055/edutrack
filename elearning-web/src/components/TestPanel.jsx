import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import { Plus, FileText, Clock, Tag, Loader2, ClipboardList, AlertCircle } from 'lucide-react';
import CreateQuizModal from './CreateQuizModal';
import TakeQuizView from './TakeQuizView';

export default function TestPanel({ course, role, userId, email }) {
  const [quizzes, setQuizzes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedQuiz, setSelectedQuiz] = useState(null);

  useEffect(() => {
    setSelectedQuiz(null);
    setLoading(true);

    const q = query(
      collection(db, 'elearning_quizzes'),
      where('courseDocId', '==', course.docId),
      orderBy('createdAt', 'desc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setQuizzes(data);
      setLoading(false);
    }, (error) => {
      console.error('Error fetching quizzes:', error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [course.docId]);

  // If a quiz is selected, show the TakeQuizView
  if (selectedQuiz) {
    return (
      <TakeQuizView
        quiz={selectedQuiz}
        role={role}
        userId={userId}
        email={email}
        onBack={() => setSelectedQuiz(null)}
      />
    );
  }

  const formatMap = {
    'multiple_choice': { 
      label: 'Trắc nghiệm', icon: '◉',
      iconBg: 'bg-blue-500/15 border-blue-500/30',
      badgeBg: 'bg-blue-500/15 text-blue-400 border-blue-500/25',
    },
    'short_answer': { 
      label: 'Câu hỏi ngắn', icon: '✎',
      iconBg: 'bg-emerald-500/15 border-emerald-500/30',
      badgeBg: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/25',
    },
    'essay': { 
      label: 'Tự luận', icon: '✍',
      iconBg: 'bg-purple-500/15 border-purple-500/30',
      badgeBg: 'bg-purple-500/15 text-purple-400 border-purple-500/25',
    },
  };

  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-gray-700/50 bg-gray-800/30 backdrop-blur-sm shrink-0">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-white">{course.courseName}</h2>
            <p className="text-sm text-gray-400 mt-1">
              {course.courseId} — {course.classGroup} 
              {course.lecturerName && <span> — GV: {course.lecturerName}</span>}
            </p>
          </div>
          {role === 'lecturer' && (
            <button
              onClick={() => setShowCreateModal(true)}
              className="flex items-center space-x-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-500 hover:to-blue-400 text-white rounded-xl transition-all duration-200 shadow-lg shadow-blue-900/30 hover:shadow-blue-800/40 font-medium text-sm"
            >
              <Plus className="w-4 h-4" />
              <span>Thêm bài kiểm tra</span>
            </button>
          )}
        </div>
      </div>

      {/* Quiz List */}
      <div className="flex-1 overflow-y-auto p-6">
        {loading ? (
          <div className="flex flex-col items-center justify-center h-60 text-gray-500">
            <Loader2 className="w-10 h-10 animate-spin mb-3 text-blue-500" />
            <span>Đang tải bài kiểm tra...</span>
          </div>
        ) : quizzes.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-60 text-gray-500">
            <ClipboardList className="w-16 h-16 mb-4 opacity-20" />
            <p className="text-lg font-medium text-gray-400">Chưa có bài kiểm tra nào</p>
            <p className="text-sm text-gray-600 mt-1">
              {role === 'lecturer' 
                ? 'Hãy bấm "Thêm bài kiểm tra" để tạo mới.' 
                : 'Giảng viên chưa upload bài kiểm tra cho môn này.'}
            </p>
          </div>
        ) : (
          <div className="grid gap-4">
            {quizzes.map((quiz) => {
              const fmt = formatMap[quiz.format] || formatMap['multiple_choice'];
              const questionCount = quiz.questions?.length || 0;
              const createdDate = quiz.createdAt?.toDate?.();

              return (
                <button
                  key={quiz.id}
                  onClick={() => setSelectedQuiz(quiz)}
                  className="w-full text-left p-5 bg-gray-800/50 hover:bg-gray-700/60 border border-gray-700/50 hover:border-gray-600/70 rounded-2xl transition-all duration-200 group shadow-sm hover:shadow-md hover:shadow-gray-900/50"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <div className={`w-9 h-9 rounded-lg flex items-center justify-center text-lg ${fmt.iconBg} border`}>
                          {fmt.icon}
                        </div>
                        <h3 className="text-lg font-semibold text-gray-100 group-hover:text-white transition-colors">
                          {quiz.title}
                        </h3>
                      </div>

                      {quiz.description && (
                        <p className="text-sm text-gray-400 mb-3 ml-12 line-clamp-2">{quiz.description}</p>
                      )}

                      <div className="flex items-center flex-wrap gap-3 ml-12">
                        <span className={`inline-flex items-center space-x-1 px-2.5 py-1 rounded-full text-xs font-medium ${fmt.badgeBg} border`}>
                          <Tag className="w-3 h-3" />
                          <span>{fmt.label}</span>
                        </span>

                        <span className="inline-flex items-center space-x-1 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-700/50 text-gray-300 border border-gray-600/50">
                          <FileText className="w-3 h-3" />
                          <span>{questionCount} câu hỏi</span>
                        </span>

                        {quiz.timeLimitMinutes > 0 && (
                          <span className="inline-flex items-center space-x-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-500/15 text-amber-400 border border-amber-500/25">
                            <Clock className="w-3 h-3" />
                            <span>{quiz.timeLimitMinutes} phút</span>
                          </span>
                        )}

                        {createdDate && (
                          <span className="text-xs text-gray-500">
                            {createdDate.toLocaleDateString('vi-VN')}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="ml-4 text-gray-600 group-hover:text-blue-400 transition-colors">
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Create Quiz Modal */}
      {showCreateModal && (
        <CreateQuizModal
          courseDocId={course.docId}
          onClose={() => setShowCreateModal(false)}
        />
      )}
    </div>
  );
}
