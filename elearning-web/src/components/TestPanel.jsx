import React, { useState, useEffect, useRef } from 'react';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';
import { Plus, FileText, Clock, Tag, Loader2, ClipboardList, AlertCircle, Camera, ShieldAlert, Monitor, Bell, AlertTriangle, Activity, Eye } from 'lucide-react';
import CreateQuizModal from './CreateQuizModal';
import TakeQuizView from './TakeQuizView'; // import trang chu tu trang cau hoi

export default function TestPanel({ course, role, userId, email }) {
  const [quizzes, setQuizzes] = useState([]); // khoi tao ham upload bai kiem tra va setup baif kiem tra cua giang vien 
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedQuiz, setSelectedQuiz] = useState(null);

  // Proctoring surveillance states
  const [activeTab, setActiveTab] = useState('quizzes'); // 'quizzes' | 'surveillance'
  const [activeSessions, setActiveSessions] = useState([]);
  const [cheatingLogs, setCheatingLogs] = useState([]);
  const [selectedSession, setSelectedSession] = useState(null);
  const [evidencePhoto, setEvidencePhoto] = useState(null);
  const [toastAlert, setToastAlert] = useState(null);
  const [selectedScreenSession, setSelectedScreenSession] = useState(null);
  const loadedTimeRef = useRef(new Date());

  useEffect(() => {
    setSelectedQuiz(null);
    setLoading(true);
    console.log('[TestPanel] Fetching quizzes for courseDocId:', course.docId);

    const q = query(
      collection(db, 'elearning_quizzes'),
      where('courseDocId', '==', course.docId)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() }))
        .sort((a, b) => {
          const ta = a.createdAt?.toMillis?.() || 0;
          const tb = b.createdAt?.toMillis?.() || 0;
          return tb - ta;
        });
      console.log('[TestPanel] Quizzes found:', data.length);
      setQuizzes(data);
      setLoading(false);
    }, (error) => {
      console.error('Error fetching quizzes:', error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [course.docId]);

  // 1. Fetch Active Sessions in real-time (Lecturer only) - Camera sessions
  useEffect(() => {
    if (role !== 'lecturer') return;

    const q = query(
      collection(db, 'elearning_active_sessions'),
      where('courseDocId', '==', course.docId)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const now = Date.now();
      const cameraData = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data(), type: 'camera' }))
        .filter(session => {
          // Only show sessions that are active (updated within last 10 minutes)
          const lastActive = session.lastActive?.toDate?.() || session.timestamp?.toDate?.();
          if (!lastActive) return false;
          const timeDiff = (now - lastActive.getTime()) / 1000;
          return timeDiff < 600;
        });
      setActiveSessions(prev => {
        const screenSessions = prev.filter(s => s.type === 'screen');
        return [...cameraData, ...screenSessions];
      });
    }, (error) => {
      console.error('Error fetching active sessions:', error);
    });

    return () => unsubscribe();
  }, [course.docId, role]);

  // 1b. Fetch Screen Sessions in real-time (Lecturer only)
  useEffect(() => {
    if (role !== 'lecturer') return;

    const q = query(
      collection(db, 'elearning_screen_sessions'),
      where('courseDocId', '==', course.docId)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const now = Date.now();
      const screenData = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data(), type: 'screen' }))
        .filter(session => {
          const lastActive = session.timestamp?.toDate?.();
          if (!lastActive) return false;
          const timeDiff = (now - lastActive.getTime()) / 1000;
          return timeDiff < 600;
        });
      setActiveSessions(prev => {
        const cameraSessions = prev.filter(s => s.type !== 'screen');
        return [...cameraSessions, ...screenData];
      });
    }, (error) => {
      console.error('Error fetching screen sessions:', error);
    });

    return () => unsubscribe();
  }, [course.docId, role]);

  // 2. Fetch Cheating Logs in real-time & Trigger warnings (Lecturer only)
  useEffect(() => {
    if (role !== 'lecturer') return;

    const q = query(
      collection(db, 'elearning_cheating_logs'),
      where('courseDocId', '==', course.docId)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() }))
        .sort((a, b) => {
          const ta = a.timestamp?.toMillis?.() || 0;
          const tb = b.timestamp?.toMillis?.() || 0;
          return tb - ta;
        });
      setCheatingLogs(data);

      // Alert lecturer on new cheating events
      snapshot.docChanges().forEach(change => {
        if (change.type === 'added') {
          const log = change.doc.data();
          const logTime = log.timestamp?.toDate ? log.timestamp.toDate() : null;
          // Trigger only for events occurring after the lecturer loads the page
          if (logTime && logTime > loadedTimeRef.current) {
            setToastAlert({
              id: change.doc.id,
              studentEmail: log.studentEmail,
              message: log.message,
              type: log.type,
              time: logTime.toLocaleTimeString('vi-VN')
            });

            // Play warning sound (Dual-tone alarm sweep)
            try {
              const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

              const playTone = (freq, delay, dur) => {
                const osc = audioCtx.createOscillator();
                const gain = audioCtx.createGain();
                osc.type = 'sawtooth';
                osc.connect(gain);
                gain.connect(audioCtx.destination);
                osc.frequency.setValueAtTime(freq, audioCtx.currentTime + delay);
                gain.gain.setValueAtTime(0.2, audioCtx.currentTime + delay);
                gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + delay + dur - 0.05);
                osc.start(audioCtx.currentTime + delay);
                osc.stop(audioCtx.currentTime + delay + dur);
              };

              // Ascending police alarm double beep
              playTone(520, 0, 0.25);
              playTone(780, 0.25, 0.35);
            } catch (err) {
              console.error('Error playing alarm:', err);
            }
          }
        }
      });
    }, (error) => {
      console.error('Error fetching cheating logs:', error);
    });

    return () => unsubscribe();
  }, [course.docId, role]);

  // 3. Auto-dismiss Toast notifications
  useEffect(() => {
    if (toastAlert) {
      const timer = setTimeout(() => setToastAlert(null), 5000);
      return () => clearTimeout(timer);
    }
  }, [toastAlert]);

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
    <div className="flex-1 flex flex-col h-full overflow-hidden text-gray-200">
      {/* Real-time Toast Alert for Lecturers */}
      {toastAlert && (
        <div className="fixed top-20 right-6 z-50 w-96 bg-red-950/90 border border-red-500/70 rounded-2xl p-4 shadow-2xl backdrop-blur-md animate-bounce flex items-start space-x-3 border-l-4 border-l-red-500">
          <div className="w-10 h-10 rounded-full bg-red-500/20 border border-red-500/40 flex items-center justify-center text-red-400 shrink-0">
            <AlertTriangle className="w-5 h-5 animate-pulse" />
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="font-black text-red-400 text-xs tracking-wider">CẢNH BÁO GIAN LẬN TRỰC TUYẾN</h4>
            <p className="text-xs font-bold text-white truncate mt-0.5">{toastAlert.studentEmail}</p>
            <p className="text-xs text-gray-300 mt-1 font-medium">{toastAlert.message}</p>
            <span className="text-[9px] text-gray-500 mt-1.5 block font-mono">{toastAlert.time}</span>
          </div>
          <button onClick={() => setToastAlert(null)} className="text-gray-400 hover:text-white text-xs font-bold font-mono">✕</button>
        </div>
      )}

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

          <div className="flex items-center space-x-3">
            {role === 'lecturer' && (
              <>
                <button
                  onClick={() => setActiveTab('quizzes')}
                  className={`flex items-center space-x-1.5 px-4 py-2 rounded-xl text-sm font-medium transition-all ${activeTab === 'quizzes'
                    ? 'bg-gray-700 text-white border border-gray-600 shadow-sm shadow-gray-900/50'
                    : 'text-gray-400 hover:text-gray-200 hover:bg-gray-700/30'
                    }`}
                >
                  <FileText className="w-4 h-4" />
                  <span>Bài thi</span>
                </button>
                <button
                  onClick={() => setActiveTab('surveillance')}
                  className={`flex items-center space-x-1.5 px-4 py-2 rounded-xl text-sm font-medium transition-all relative ${activeTab === 'surveillance'
                    ? 'bg-red-950/45 text-red-400 border border-red-500/30 shadow-md shadow-red-950/30'
                    : 'text-gray-400 hover:text-gray-200 hover:bg-gray-700/30'
                    }`}
                >
                  <ShieldAlert className="w-4 h-4" />
                  <span>Giám sát</span>
                  {activeSessions.length > 0 && (
                    <span className="absolute -top-1.5 -right-1.5 w-4 h-4 bg-red-500 text-white rounded-full flex items-center justify-center text-[9px] font-bold animate-pulse">
                      {activeSessions.length}
                    </span>
                  )}
                </button>
                <div className="h-6 w-px bg-gray-700" />
              </>
            )}

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
      </div>

      {/* Main Content Area */}
      {activeTab === 'quizzes' || role === 'student' ? (
        /* Quiz List View */
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
      ) : (
        /* Surveillance Dashboard View */
        <div className="flex-1 overflow-y-auto p-6 space-y-6 bg-gray-900/20 custom-scrollbar">
          {/* Status Dashboard Summary */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-gray-800/40 border border-gray-700/50 rounded-2xl p-5 flex items-center space-x-4">
              <div className="w-12 h-12 rounded-xl bg-blue-500/10 border border-blue-500/25 flex items-center justify-center text-blue-400 shrink-0">
                <Camera className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Camera sinh viên</p>
                <h3 className="text-2xl font-bold text-white mt-1">{activeSessions.filter(s => s.type !== 'screen').length} SV</h3>
              </div>
            </div>

            <div className="bg-gray-800/40 border border-gray-700/50 rounded-2xl p-5 flex items-center space-x-4">
              <div className="w-12 h-12 rounded-xl bg-purple-500/10 border border-purple-500/25 flex items-center justify-center text-purple-400 shrink-0">
                <Monitor className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Màn hình đang giám sát</p>
                <h3 className="text-2xl font-bold text-purple-300 mt-1">{activeSessions.filter(s => s.type === 'screen').length} màn hình</h3>
              </div>
            </div>

            <div className="bg-gray-800/40 border border-gray-700/50 rounded-2xl p-5 flex items-center space-x-4">
              <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${cheatingLogs.length > 0
                ? 'bg-red-500/10 border border-red-500/25 text-red-400 animate-pulse'
                : 'bg-green-500/10 border border-green-500/25 text-green-400'
                }`}>
                <ShieldAlert className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Tổng vi phạm</p>
                <h3 className={`text-2xl font-bold mt-1 ${cheatingLogs.length > 0 ? 'text-red-400' : 'text-green-400'}`}>
                  {cheatingLogs.length} lần
                </h3>
              </div>
            </div>

            <div className="bg-gray-800/40 border border-gray-700/50 rounded-2xl p-5 flex items-center space-x-4">
              <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/25 flex items-center justify-center text-emerald-400 shrink-0">
                <Camera className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Hệ thống</p>
                <h3 className="text-sm font-semibold text-emerald-400 mt-2 flex items-center space-x-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
                  <span>Đang giám sát</span>
                </h3>
              </div>
            </div>

            <div className="bg-gray-800/40 border border-gray-700/50 rounded-2xl p-5 flex items-center space-x-4">
              <div className="w-12 h-12 rounded-xl bg-cyan-500/10 border border-cyan-500/25 flex items-center justify-center text-cyan-400 shrink-0">
                <Activity className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Tần suất cập nhật</p>
                <h3 className="text-sm font-semibold text-cyan-400 mt-2">
                  Mỗi 3 giây
                </h3>
              </div>
            </div>
          </div>

          {/* Live streams and Logs Split Panel */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* LEFT: Live Video Streaming (7 cols) */}
            <div className="lg:col-span-7 space-y-6">
              {/* Webcam Grid */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center space-x-2">
                    <Camera className="w-4 h-4 text-blue-400" />
                    <span>Camera Sinh viên</span>
                  </h3>
                  {activeSessions.filter(s => s.type !== 'screen').length > 0 && (
                    <span className="text-xs text-gray-500">Nhấp để phóng to</span>
                  )}
                </div>

                {activeSessions.filter(s => s.type !== 'screen').length === 0 ? (
                  <div className="bg-gray-800/20 border border-gray-700/40 rounded-2xl p-8 text-center flex flex-col items-center justify-center">
                    <Camera className="w-10 h-10 text-gray-600 mb-2 opacity-30" />
                    <p className="text-sm text-gray-400">Chưa có camera nào đang hoạt động</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {activeSessions.filter(s => s.type !== 'screen').map((session) => {
                      const isCheating = session.status === 'cheating';
                      return (
                        <div
                          key={session.id}
                          onClick={() => setSelectedSession(session)}
                          className={`relative bg-gray-850 border rounded-2xl overflow-hidden cursor-pointer group hover:scale-[1.02] transition-all duration-205 ${isCheating
                            ? 'border-red-500/60 shadow-lg shadow-red-950/20'
                            : 'border-gray-700/50 hover:border-gray-600'
                            }`}
                        >
                          {/* Video Stream Container */}
                          <div className="w-full h-44 bg-black relative flex items-center justify-center">
                            {session.liveFrame ? (
                              <img
                                src={session.liveFrame}
                                alt={`Camera of ${session.studentEmail}`}
                                className="w-full h-full object-cover"
                                loading="eager"
                                style={{ imageRendering: 'auto' }}
                              />
                            ) : (
                              <div className="flex flex-col items-center space-y-2 text-gray-600">
                                <Loader2 className="w-6 h-6 animate-spin text-blue-500" />
                                <span className="text-xs">Đang kết nối camera...</span>
                              </div>
                            )}

                            {/* Scan Line effect for video */}
                            <div className="absolute inset-0 pointer-events-none bg-gradient-to-b from-transparent via-blue-500/5 to-transparent bg-[length:100%_4px] animate-pulse" />

                            {/* Top Overlays */}
                            <div className="absolute top-3 left-3 bg-black/60 backdrop-blur-md px-2.5 py-1 rounded-lg flex items-center space-x-1.5 border border-white/10">
                              <span className={`w-2.5 h-2.5 rounded-full ${isCheating ? 'bg-red-500 animate-ping' : 'bg-emerald-500 animate-pulse'}`} />
                              <span className="text-[10px] font-bold font-mono text-white">LIVE</span>
                            </div>

                            <div className={`absolute top-3 right-3 px-2 py-0.5 rounded-md text-[9px] font-bold border ${isCheating
                              ? 'bg-red-950/85 text-red-400 border-red-500/35'
                              : 'bg-emerald-950/80 text-emerald-400 border-emerald-500/30'
                              }`}>
                              {isCheating ? 'CẢNH BÁO VI PHẠM' : 'AN TOÀN'}
                            </div>

                            {/* Bottom Student Info Overlay */}
                            <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent p-3 pt-6">
                              <p className="text-xs font-semibold text-white truncate">{session.studentEmail}</p>
                              <p className="text-[10px] text-gray-300 mt-0.5 truncate">{session.quizTitle}</p>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* Screen Monitoring Section */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center space-x-2">
                    <Monitor className="w-4 h-4 text-purple-400" />
                    <span>Giám sát màn hình sinh viên</span>
                  </h3>
                  {activeSessions.filter(s => !s.type || s.type !== 'screen').length > 0 && (
                    <span className="text-xs text-gray-500">Nhấp để xem chi tiết</span>
                  )}
                </div>

                {activeSessions.filter(s => s.type === 'screen').length === 0 ? (
                  <div className="bg-gray-800/20 border border-gray-700/40 rounded-2xl p-8 text-center flex flex-col items-center justify-center">
                    <Monitor className="w-10 h-10 text-gray-600 mb-2 opacity-30" />
                    <p className="text-sm text-gray-400">Chưa có sinh viên nào chia sẻ màn hình</p>
                    <p className="text-xs text-gray-600 mt-1">Hệ thống sẽ tự động hiển thị khi sinh viên bắt đầu làm bài</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {activeSessions.filter(s => s.type === 'screen').map((session) => {
                      const isCheating = session.status === 'cheating';
                      const lastActive = session.timestamp?.toDate ? session.timestamp.toDate() : new Date();
                      const timeSinceUpdate = Math.floor((new Date() - lastActive) / 1000);

                      return (
                        <div
                          key={session.id}
                          onClick={() => setSelectedScreenSession(session)}
                          className={`relative bg-gray-850 border rounded-2xl overflow-hidden cursor-pointer group hover:scale-[1.02] transition-all duration-200 ${isCheating
                            ? 'border-red-500/60 shadow-lg shadow-red-950/20'
                            : 'border-purple-700/50 hover:border-purple-600'
                            }`}
                        >
                          {/* Screen Capture Container */}
                          <div className="w-full h-48 bg-black relative flex items-center justify-center">
                            {session.screenFrame ? (
                              <img
                                src={session.screenFrame}
                                alt={`Screen of ${session.studentEmail}`}
                                className="w-full h-full object-cover"
                                loading="eager"
                                style={{ imageRendering: 'auto' }}
                              />
                            ) : (
                              <div className="flex flex-col items-center space-y-2 text-gray-600">
                                <Loader2 className="w-6 h-6 animate-spin text-purple-500" />
                                <span className="text-xs">Đang chờ chia sẻ màn hình...</span>
                              </div>
                            )}

                            {/* Screen Monitor Overlay */}
                            <div className="absolute inset-0 pointer-events-none bg-gradient-to-br from-purple-500/5 to-transparent" />

                            {/* Top Overlays */}
                            <div className="absolute top-3 left-3 bg-black/60 backdrop-blur-md px-2.5 py-1 rounded-lg flex items-center space-x-1.5 border border-white/10">
                              <span className={`w-2.5 h-2.5 rounded-full ${isCheating ? 'bg-red-500 animate-ping' : 'bg-purple-500 animate-pulse'}`} />
                              <span className="text-[10px] font-bold font-mono text-white">SCREEN</span>
                            </div>

                            <div className={`absolute top-3 right-3 px-2 py-0.5 rounded-md text-[9px] font-bold border ${isCheating
                              ? 'bg-red-950/85 text-red-400 border-red-500/35'
                              : 'bg-purple-950/80 text-purple-400 border-purple-500/30'
                              }`}>
                              {isCheating ? 'CẢNH BÁO' : 'ĐANG GIÁM SÁT'}
                            </div>

                            {/* Update indicator */}
                            <div className="absolute bottom-3 right-3 bg-black/60 backdrop-blur-md px-2 py-0.5 rounded-md">
                              <span className="text-[9px] font-mono text-gray-400">
                                Cập nhật: {timeSinceUpdate}s trước
                              </span>
                            </div>

                            {/* Bottom Student Info Overlay */}
                            <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent p-3 pt-6">
                              <p className="text-xs font-semibold text-white truncate">{session.studentEmail}</p>
                              <p className="text-[10px] text-gray-300 mt-0.5 truncate">{session.quizTitle}</p>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* RIGHT: Real-time Cheating Logs (5 cols) */}
              <div className="lg:col-span-5 space-y-4">
                <h3 className="text-base font-bold text-white flex items-center space-x-2">
                  <Bell className="w-4 h-4 text-red-400" />
                  <span>Nhật ký Vi phạm (Logs)</span>
                </h3>

                {cheatingLogs.length === 0 ? (
                  <div className="bg-gray-800/20 border border-gray-700/40 rounded-2xl p-10 text-center flex flex-col items-center justify-center h-80">
                    <ShieldAlert className="w-12 h-12 text-gray-600 mb-3 opacity-30" />
                    <p className="text-sm font-medium text-gray-400">Chưa ghi nhận vi phạm nào</p>
                    <p className="text-xs text-gray-600 mt-1">Lịch sử chuyển tab, rời màn hình của sinh viên sẽ tự động lưu trữ.</p>
                  </div>
                ) : (
                  <div className="space-y-3 max-h-[500px] overflow-y-auto pr-1 custom-scrollbar">
                    {cheatingLogs.map((log) => {
                      const date = log.timestamp?.toDate ? log.timestamp.toDate() : (log.timestamp ? new Date(log.timestamp) : null);
                      return (
                        <div
                          key={log.id}
                          className="bg-gray-800/40 border border-red-500/20 hover:border-red-500/45 rounded-xl p-4 transition-all duration-150 flex items-start space-x-3 shrink-0"
                        >
                          {/* Violation Icon or Photo */}
                          {log.evidenceUrl ? (
                            <div
                              onClick={() => setEvidencePhoto(log.evidenceUrl)}
                              className="w-14 h-14 rounded-lg bg-gray-900 border border-gray-700 overflow-hidden cursor-zoom-in shrink-0 relative group"
                              title="Bấm để xem ảnh chứng cứ"
                            >
                              <img src={log.evidenceUrl} className="w-full h-full object-cover group-hover:scale-110 transition-transform" />
                              <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                <Plus className="w-4 h-4 text-white" />
                              </div>
                            </div>
                          ) : (
                            <div className="w-10 h-10 rounded-lg bg-red-500/10 border border-red-500/25 text-red-400 flex items-center justify-center shrink-0">
                              <AlertTriangle className="w-5 h-5" />
                            </div>
                          )}

                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between">
                              <p className="text-xs font-bold text-white truncate">{log.studentEmail}</p>
                              <span className="text-[10px] text-gray-500 shrink-0 font-mono">
                                {date ? date.toLocaleTimeString('vi-VN') : 'N/A'}
                              </span>
                            </div>
                            <p className="text-xs text-red-400 font-semibold mt-1">{log.message}</p>
                            <p className="text-[10px] text-gray-500 mt-1 italic truncate text-ellipsis">{log.quizTitle}</p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>

            {/* Lightbox / Evidence Photo Preview Modal */}
            {evidencePhoto && (
              <div
                className="fixed inset-0 bg-black/85 backdrop-blur-sm z-[100] flex items-center justify-center p-4 cursor-zoom-out"
                onClick={() => setEvidencePhoto(null)}
              >
                <div className="bg-gray-900 border border-gray-700 p-3 rounded-2xl max-w-xl w-full shadow-2xl relative" onClick={e => e.stopPropagation()}>
                  <img src={evidencePhoto} className="w-full h-auto rounded-xl object-contain border border-gray-700" alt="Evidence Large" />
                  <p className="text-xs text-red-400 font-bold mt-3 text-center">BẰNG CHỨNG GHI NHẬN HÀNH VI GIAN LẬN</p>
                  <button
                    onClick={() => setEvidencePhoto(null)}
                    className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-gray-800 border border-gray-600 text-white flex items-center justify-center hover:bg-gray-700 shadow-md font-bold"
                  >
                    ✕
                  </button>
                </div>
              </div>
            )}

            {/* Screen Monitor Fullscreen Preview Modal */}
            {selectedScreenSession && (
              <div
                className="fixed inset-0 bg-black/85 backdrop-blur-sm z-[100] flex items-center justify-center p-4 cursor-zoom-out"
                onClick={() => setSelectedScreenSession(null)}
              >
                <div className="bg-gray-950 border border-purple-700/50 rounded-2xl max-w-5xl w-full shadow-2xl overflow-hidden relative" onClick={e => e.stopPropagation()}>
                  <div className="p-4 border-b border-gray-800 flex items-center justify-between">
                    <div>
                      <h4 className="font-bold text-white text-sm flex items-center space-x-2">
                        <Monitor className="w-4 h-4 text-purple-400" />
                        <span>Giám sát màn hình: {selectedScreenSession.studentEmail}</span>
                      </h4>
                      <p className="text-xs text-gray-400 mt-0.5">{selectedScreenSession.quizTitle}</p>
                    </div>
                    <button
                      onClick={() => setSelectedScreenSession(null)}
                      className="px-3 py-1 bg-gray-800 hover:bg-gray-700 text-white text-xs font-semibold rounded-lg"
                    >
                      Đóng
                    </button>
                  </div>
                  <div className="w-full bg-black flex items-center justify-center" style={{ height: '500px' }}>
                    {selectedScreenSession.screenFrame ? (
                      <img src={selectedScreenSession.screenFrame} className="w-full h-full object-contain" alt="Fullscreen Screen Monitor" />
                    ) : (
                      <div className="flex flex-col items-center space-y-3">
                        <Loader2 className="w-10 h-10 animate-spin text-purple-500" />
                        <span className="text-sm text-gray-400">Đang chờ cập nhật màn hình...</span>
                      </div>
                    )}
                  </div>
                  <div className="p-4 bg-gray-900/60 flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <span className="text-xs text-gray-500">Trạng thái:
                        <span className={`ml-1 font-bold ${selectedScreenSession.status === 'banned' ? 'text-orange-400' : selectedScreenSession.status === 'cheating' ? 'text-red-400' : 'text-purple-400'}`}>
                          {selectedScreenSession.status === 'banned' ? 'ĐÌNH CHỈ THI' : selectedScreenSession.status === 'cheating' ? 'CẢNH BÁO VI PHẠM' : 'ĐANG GIÁM SÁT'}
                        </span>
                      </span>
                      <span className="text-[10px] text-gray-600 font-mono">
                        Loại: Chia sẻ màn hình
                      </span>
                    </div>
                    <span className="text-[10px] text-gray-600 font-mono">
                      Cập nhật cuối: {selectedScreenSession.lastActive?.toDate ? selectedScreenSession.lastActive.toDate().toLocaleTimeString('vi-VN') : 'Vừa xong'}
                    </span>
                  </div>
                </div>
              </div>
            )}

            {/* Live Stream Fullscreen Preview Modal */}
            {selectedSession && (
              <div
                className="fixed inset-0 bg-black/85 backdrop-blur-sm z-[100] flex items-center justify-center p-4 cursor-zoom-out"
                onClick={() => setSelectedSession(null)}
              >
                <div className="bg-gray-950 border border-gray-700 rounded-2xl max-w-2xl w-full shadow-2xl overflow-hidden relative" onClick={e => e.stopPropagation()}>
                  <div className="p-4 border-b border-gray-850 flex items-center justify-between">
                    <div>
                      <h4 className="font-bold text-white text-sm">{selectedSession.studentEmail}</h4>
                      <p className="text-xs text-gray-400 mt-0.5">{selectedSession.quizTitle}</p>
                    </div>
                    <button
                      onClick={() => setSelectedSession(null)}
                      className="px-3 py-1 bg-gray-800 hover:bg-gray-700 text-white text-xs font-semibold rounded-lg"
                    >
                      Đóng
                    </button>
                  </div>
                  <div className="w-full bg-black flex items-center justify-center" style={{ height: '400px' }}>
                    {selectedSession.liveFrame ? (
                      <img src={selectedSession.liveFrame} className="w-full h-full object-contain" alt="Fullscreen Monitor" />
                    ) : (
                      <Loader2 className="w-10 h-10 animate-spin text-blue-500" />
                    )}
                  </div>
                  <div className="p-4 bg-gray-900/60 flex items-center justify-between">
                    <span className="text-xs text-gray-500">Trạng thái:
                      <span className={`ml-1 font-bold ${selectedSession.status === 'cheating' ? 'text-red-400' : 'text-emerald-400'}`}>
                        {selectedSession.status === 'cheating' ? 'CẢNH BÁO VI PHẠM' : 'AN TOÀN'}
                      </span>
                    </span>
                    <span className="text-[10px] text-gray-600 font-mono">
                      Cập nhật cuối: {selectedSession.lastActive?.toDate ? selectedSession.lastActive.toDate().toLocaleTimeString('vi-VN') : 'Vừa xong'}
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Create Quiz Modal */}
      {showCreateModal && (
        <CreateQuizModal
          courseDocId={course.docId}
          userId={userId}
          onClose={() => setShowCreateModal(false)}
        />
      )}
    </div>
  );
};

