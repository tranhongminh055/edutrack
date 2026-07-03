import React, { useState, useEffect, useRef } from 'react';
import { collection, query, where, onSnapshot, serverTimestamp, deleteDoc, doc, setDoc, addDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { ArrowLeft, Clock, CheckCircle2, Send, AlertTriangle, FileText, Award, Trash2, Eye, Loader2, Camera, ShieldAlert, Monitor, Brain, Star } from 'lucide-react';
import quizService from '../services/quizService';

export default function TakeQuizView({ quiz, role, userId, email, onBack }) {
  const [answers, setAnswers] = useState({}); // khoi tao ket qua bai thi
  const [submitted, setSubmitted] = useState(false); // trang thai da nop bai
  const [submitting, setSubmitting] = useState(false); // trang thai dang nop bai
  const [timeLeft, setTimeLeft] = useState(quiz.timeLimitMinutes > 0 ? quiz.timeLimitMinutes * 60 : null); // thoi gian da lam bai thi 
  const [attempts, setAttempts] = useState([]);
  const [loadingAttempts, setLoadingAttempts] = useState(true);
  const [viewMode, setViewMode] = useState('info'); // 'info' | 'take' | 'result'
  const [lastResult, setLastResult] = useState(null);
  const [cameraAllowed, setCameraAllowed] = useState(false);
  const [violationCount, setViolationCount] = useState(0);
  const [cheatingAlert, setCheatingAlert] = useState(null);
  const [isBanned, setIsBanned] = useState(false);
  const [aiResult, setAiResult] = useState(null);
  const [screenShareRequired, setScreenShareRequired] = useState(false);
  const [requestingPermissions, setRequestingPermissions] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [currentTime, setCurrentTime] = useState(new Date());
  const timerRef = useRef(null);
  const activeStreamRef = useRef(null);
  const activeSessionIntervalRef = useRef(null);
  const screenStreamRef = useRef(null);
  const screenIntervalRef = useRef(null);

  // Reusable canvas refs to avoid GC pressure from creating new canvases every frame
  const cameraCanvasRef = useRef(null);
  const screenCanvasRef = useRef(null);
  
  // Proctoring Refs
  const violationCountRef = useRef(0);
  const handleSubmitRef = useRef(null);
  useEffect(() => {
    handleSubmitRef.current = handleSubmit;
  });

  // Update current time every minute to check quiz availability
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(new Date());
    }, 60000); // Update every minute

    return () => clearInterval(interval);
  }, []);

  // Detect mobile device
  useEffect(() => {
    const userAgent = navigator.userAgent || navigator.vendor || window.opera;
    const mobile = /android|ipad|iphone|ipod/i.test(userAgent) || window.innerWidth <= 768;
    setIsMobile(mobile);
  }, []);

  // Fetch existing attempts (read from quiz_submissions)
  useEffect(() => {
    if (!userId) { setLoadingAttempts(false); return; }

    let q;
    if (role === 'student') {
      q = query(
        collection(db, 'quiz_submissions'),
        where('quizId', '==', quiz.id),
        where('userId', '==', userId)
      );
    } else {
      // Lecturer sees all attempts
      q = query(
        collection(db, 'quiz_submissions'),
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

  // Camera & tab surveillance logic (Student only)
  useEffect(() => {
    // Only start surveillance if viewMode is 'take' AND stream is already obtained from handleStartQuiz
    if (viewMode !== 'take' || role !== 'student' || !activeStreamRef.current) return;

    let localStream = null;
    let localInterval = null;
    let isCapturing = false; // Prevent overlapping captures

    const startCamera = async () => {
      // Use existing stream from handleStartQuiz only
      const stream = activeStreamRef.current;
      if (!stream) return;

      try {
        let video = document.getElementById('hidden-surveillance-video');
        if (!video) {
          video = document.createElement('video');
          video.id = 'hidden-surveillance-video';
          video.autoplay = true;
          video.playsInline = true;
          video.muted = true;
          video.style.cssText = 'position:fixed;width:1px;height:1px;opacity:0.01;pointer-events:none;top:-10px;left:-10px;';
          document.body.appendChild(video);
        }
        video.srcObject = stream;
        await video.play().catch(() => {}); // Ensure playback starts
        setCameraAllowed(true);

        // Also connect to visible preview
        setTimeout(() => {
          const previewVideo = document.getElementById('student-camera-preview');
          if (previewVideo) {
            previewVideo.srcObject = stream;
            previewVideo.play().catch(() => {});
          }
        }, 500);

        // Initialize reusable canvas for camera
        const camW = isMobile ? 160 : 320;
        const camH = isMobile ? 120 : 240;
        if (!cameraCanvasRef.current) {
          const canvas = document.createElement('canvas');
          canvas.width = camW;
          canvas.height = camH;
          cameraCanvasRef.current = canvas;
        } else {
          cameraCanvasRef.current.width = camW;
          cameraCanvasRef.current.height = camH;
        }

        const sessionRef = doc(db, 'elearning_active_sessions', `${userId}_${quiz.id}`);
        await setDoc(sessionRef, {
          studentId: userId,
          studentEmail: email,
          quizId: quiz.id,
          quizTitle: quiz.title,
          courseDocId: quiz.courseDocId,
          lastActive: serverTimestamp(),
          liveFrame: '',
          status: 'safe',
          deviceType: isMobile ? 'mobile' : 'desktop'
        });

        localInterval = setInterval(async () => {
          if (!video.videoWidth || isCapturing) return;
          isCapturing = true;
          try {
            const canvas = cameraCanvasRef.current;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

            // Subtle "AI Face Detection Box" overlay
            ctx.strokeStyle = '#22c55e';
            ctx.lineWidth = 2;
            const bx = Math.round(canvas.width * 0.25);
            const by = Math.round(canvas.height * 0.25);
            ctx.strokeRect(bx, by, canvas.width * 0.5, canvas.height * 0.5);

            const frameData = canvas.toDataURL('image/jpeg', 0.25);
            await setDoc(sessionRef, {
              liveFrame: frameData,
              lastActive: serverTimestamp()
            }, { merge: true });
          } catch (err) {
            console.error('Camera capture error:', err);
          } finally {
            isCapturing = false;
          }
        }, 3000);
        activeSessionIntervalRef.current = localInterval;
      } catch (err) {
        console.warn('Camera surveillance failed:', err);
        await addDoc(collection(db, 'elearning_cheating_logs'), {
          quizId: quiz.id, quizTitle: quiz.title, courseDocId: quiz.courseDocId,
          studentId: userId, studentEmail: email,
          type: 'camera_blocked',
          message: 'Sinh viên từ chối cấp quyền camera hoặc camera bị chặn.',
          timestamp: serverTimestamp()
        });
      }
    };

    startCamera();

    return () => {
      if (localInterval) clearInterval(localInterval);
      if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
      }
      const video = document.getElementById('hidden-surveillance-video');
      if (video) video.remove();
    };
  }, [viewMode, role, userId, email, quiz.id, quiz.title, quiz.courseDocId, isMobile]);

  // Screen capture via getDisplayMedia (Both mobile and desktop if available)
  useEffect(() => {
    // Start screen capture if stream is available (works on both mobile and desktop)
    if (viewMode !== 'take' || role !== 'student' || !screenStreamRef.current) return;

    let localScreenStream = null;
    let localScreenInterval = null;
    let isScreenCapturing = false; // Prevent overlapping writes

    const startScreenCapture = async () => {
      // Use existing stream from handleStartQuiz only
      const screenStream = screenStreamRef.current;
      if (!screenStream) return;

      try {
        let screenVideo = document.getElementById('hidden-screen-video');
        if (!screenVideo) {
          screenVideo = document.createElement('video');
          screenVideo.id = 'hidden-screen-video';
          screenVideo.autoplay = true;
          screenVideo.playsInline = true;
          screenVideo.muted = true;
          screenVideo.style.cssText = 'position:fixed;width:1px;height:1px;opacity:0.01;pointer-events:none;top:-10px;left:-10px;';
          document.body.appendChild(screenVideo);
        }
        screenVideo.srcObject = screenStream;
        await screenVideo.play().catch(() => {}); // Ensure playback starts

        // Also connect to visible preview
        setTimeout(() => {
          const previewScreenVideo = document.getElementById('student-screen-preview');
          if (previewScreenVideo) {
            previewScreenVideo.srcObject = screenStream;
            previewScreenVideo.play().catch(() => {});
          }
        }, 500);

        // When student stops sharing screen, log it
        const videoTrack = screenStream.getVideoTracks()[0];
        if (videoTrack) {
          videoTrack.addEventListener('ended', () => {
            addDoc(collection(db, 'elearning_cheating_logs'), {
              quizId: quiz.id, quizTitle: quiz.title, courseDocId: quiz.courseDocId,
              studentId: userId, studentEmail: email,
              type: 'screen_share_stopped',
              message: 'Sinh viên đã dừng chia sẻ màn hình.',
              timestamp: serverTimestamp()
            });
          });
        }

        // Initialize reusable canvas for screen capture
        const scrW = isMobile ? 160 : 320;
        const scrH = isMobile ? 90 : 180;
        if (!screenCanvasRef.current) {
          const canvas = document.createElement('canvas');
          canvas.width = scrW;
          canvas.height = scrH;
          screenCanvasRef.current = canvas;
        } else {
          screenCanvasRef.current.width = scrW;
          screenCanvasRef.current.height = scrH;
        }

        const screenSessionRef = doc(db, 'elearning_screen_sessions', `${userId}_${quiz.id}`);
        await setDoc(screenSessionRef, {
          studentId: userId, studentEmail: email,
          quizId: quiz.id, quizTitle: quiz.title,
          courseDocId: quiz.courseDocId,
          screenFrame: '', status: 'active',
          timestamp: serverTimestamp()
        });

        // Stagger screen interval 1.5s offset from camera to avoid write contention
        await new Promise(r => setTimeout(r, 1500));

        localScreenInterval = setInterval(async () => {
          if (!screenVideo.videoWidth || isScreenCapturing) return;
          isScreenCapturing = true;
          try {
            const canvas = screenCanvasRef.current;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(screenVideo, 0, 0, canvas.width, canvas.height);

            // Overlay label
            ctx.fillStyle = 'rgba(0,0,0,0.5)';
            ctx.fillRect(0, 0, 100, 14);
            ctx.fillStyle = '#22c55e';
            ctx.font = 'bold 7px Arial';
            ctx.fillText('SCREEN', 4, 11);

            const frameData = canvas.toDataURL('image/jpeg', 0.2);
            await setDoc(screenSessionRef, {
              screenFrame: frameData,
              timestamp: serverTimestamp()
            }, { merge: true });
          } catch (err) {
            console.error('Screen capture error:', err);
          } finally {
            isScreenCapturing = false;
          }
        }, 3000);
        screenIntervalRef.current = localScreenInterval;
      } catch (err) {
        console.warn('Screen capture not available or denied:', err);
        await addDoc(collection(db, 'elearning_cheating_logs'), {
          quizId: quiz.id, quizTitle: quiz.title, courseDocId: quiz.courseDocId,
          studentId: userId, studentEmail: email,
          type: 'screen_share_denied',
          message: 'Sinh viên từ chối chia sẻ màn hình.',
          timestamp: serverTimestamp()
        });
      }
    };

    startScreenCapture();

    return () => {
      if (localScreenInterval) clearInterval(localScreenInterval);
      if (localScreenStream) {
        localScreenStream.getTracks().forEach(track => track.stop());
      }
      const screenVideo = document.getElementById('hidden-screen-video');
      if (screenVideo) screenVideo.remove();

      const screenSessionRef = doc(db, 'elearning_screen_sessions', `${userId}_${quiz.id}`);
      deleteDoc(screenSessionRef).catch(() => {});
    };
  }, [viewMode, role, quiz.id, userId, email, isMobile, screenStreamRef]);

  // Tab Switching & Blur surveillance detection (Student only)
  useEffect(() => {
    if (viewMode !== 'take' || role !== 'student') return;

    const triggerCheatingLog = async (messageText) => {
      violationCountRef.current += 1;
      const currentViolation = violationCountRef.current;
      setViolationCount(currentViolation);

      // Show alert toast on the top-right of the screen
      setCheatingAlert({ message: messageText, count: currentViolation });

      // Play Beep Alarm Sound
      try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const playTone = (freq, start, duration) => {
          const osc = audioCtx.createOscillator();
          const gain = audioCtx.createGain();
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.frequency.setValueAtTime(freq, start);
          gain.gain.setValueAtTime(0.5, start);
          gain.gain.exponentialRampToValueAtTime(0.01, start + duration);
          osc.start(start);
          osc.stop(start + duration);
        };
        playTone(987.77, audioCtx.currentTime, 0.3); // B5
        playTone(987.77, audioCtx.currentTime + 0.35, 0.3);
      } catch (err) {
        console.error('Error playing alarm beep:', err);
      }

      // Voice Warning in Vietnamese (Speech Synthesis)
      try {
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(
          currentViolation >= 3
            ? "Bạn đã bị đình chỉ thi do vi phạm quy chế quá ba lần. Bài thi sẽ tự động nộp."
            : "Vui lòng nghiêm túc."
        );
        utterance.lang = 'vi-VN';
        utterance.rate = 0.95;
        window.speechSynthesis.speak(utterance);
      } catch (err) {
        console.error('Error speaking:', err);
      }

      // Capture snapshot evidence
      let evidenceUrl = '';
      const video = document.getElementById('hidden-surveillance-video');
      if (video && video.videoWidth) {
        try {
          const canvas = document.createElement('canvas');
          canvas.width = 320;
          canvas.height = 240;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(video, 0, 0, 320, 240);

          // Red overlay warning banner
          ctx.fillStyle = 'rgba(239, 68, 68, 0.25)';
          ctx.fillRect(0, 0, 320, 240);
          ctx.strokeStyle = '#ef4444';
          ctx.lineWidth = 3;
          ctx.strokeRect(10, 10, 300, 220);
          ctx.fillStyle = '#ef4444';
          ctx.font = 'bold 11px Arial';
          ctx.fillText('WARNING: SCREEN LEFT / TAB SWITCHED', 20, 30);

          evidenceUrl = canvas.toDataURL('image/jpeg', 0.5);
        } catch (err) {
          console.error('Error drawing evidence canvas:', err);
        }
      }

      // Send to Firestore cheating logs
      try {
        await addDoc(collection(db, 'elearning_cheating_logs'), {
          quizId: quiz.id,
          quizTitle: quiz.title,
          courseDocId: quiz.courseDocId,
          studentId: userId,
          studentEmail: email,
          type: 'tab_switch',
          message: `${messageText} (Lần ${currentViolation})`,
          evidenceUrl: evidenceUrl,
          timestamp: serverTimestamp()
        });

        // Set session state to 'cheating' or 'banned'
        const sessionRef = doc(db, 'elearning_active_sessions', `${userId}_${quiz.id}`);
        await setDoc(sessionRef, { status: currentViolation >= 3 ? 'banned' : 'cheating' }, { merge: true });
      } catch (err) {
        console.error('Error logging cheating event:', err);
      }

      // If violation count exceeds 3, trigger auto-submit and lock the student
      if (currentViolation >= 3) {
        setIsBanned(true);
        if (handleSubmitRef.current) {
          await handleSubmitRef.current();
        }
      }
    };

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'hidden') {
        triggerCheatingLog('Sinh viên chuyển tab hoặc rời khỏi trang thi');
      }
    };

    const handleWindowBlur = () => {
      triggerCheatingLog('Sinh viên mất tập trung khỏi màn hình thi');
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('blur', handleWindowBlur);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('blur', handleWindowBlur);
    };
  }, [viewMode, role, quiz.id, userId, email]);

  // Auto-dismiss cheating alert toast after 5 seconds
  useEffect(() => {
    if (cheatingAlert) {
      const timer = setTimeout(() => setCheatingAlert(null), 5000);
      return () => clearTimeout(timer);
    }
  }, [cheatingAlert]);

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

      // Map answers into normalized array { questionId, answer }
      const normalizedAnswers = quiz.questions.map((q, i) => ({
        questionId: q.id || String(i),
        answer: answers[i] !== undefined ? answers[i] : null,
      }));

      // Persist via quizService (creates quiz_submissions)
      // Pass answersMap for AI grading of essay/short_answer
      const result = await quizService.submitQuiz({
        quizId: quiz.id,
        userId,
        studentEmail: email,
        answers: normalizedAnswers,
        answersMap: quiz.format !== 'multiple_choice' ? answers : null,
        courseDocId: quiz.courseDocId
      });

      // Sync grades to gradebook
      await quizService.syncQuizGradesToGradebook(email, quiz.courseDocId, result.score);

      // Delete active sessions
      try {
        await deleteDoc(doc(db, 'elearning_active_sessions', `${userId}_${quiz.id}`));
        await deleteDoc(doc(db, 'elearning_screen_sessions', `${userId}_${quiz.id}`));
      } catch (e) {
        console.error('Error deleting session on submit:', e);
      }

      // Stop screen & camera streams
      if (screenStreamRef.current) {
        screenStreamRef.current.getTracks().forEach(t => t.stop());
      }
      if (activeStreamRef.current) {
        activeStreamRef.current.getTracks().forEach(t => t.stop());
      }

      if (result.aiFeedback) {
        setAiResult({
          score: result.score,
          feedback: result.aiFeedback,
          perQuestion: result.aiPerQuestion,
          qualityMetrics: result.qualityMetrics,
          plagiarismScore: result.plagiarismScore,
          plagiarismWarning: result.plagiarismWarning
        });
      }

      setLastResult({ score: quiz.format === 'multiple_choice' ? score : result.score, totalQuestions });
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

  const handleStartQuiz = async () => {
    violationCountRef.current = 0;
    setViolationCount(0);
    setIsBanned(false);
    setCheatingAlert(null);

    if (role !== 'student') {
      setViewMode('take');
      setAnswers({});
      setSubmitted(false);
      setTimeLeft(quiz.timeLimitMinutes > 0 ? quiz.timeLimitMinutes * 60 : null);
      return;
    }

    // Require camera for all devices, screen share only for desktop
    setRequestingPermissions(true);
    try {
      // 1. Request camera first (required for all devices)
      alert('Bước 1: Vui lòng bấm "Cho phép" (Allow) để cấp quyền camera cho hệ thống giám sát.');
      const cameraStream = await navigator.mediaDevices.getUserMedia({
        video: {
          width: isMobile ? { ideal: 320 } : { ideal: 640 },
          height: isMobile ? { ideal: 240 } : { ideal: 480 },
          facingMode: 'user'
        },
        audio: false
      });
      activeStreamRef.current = cameraStream;

      // 2. Request screen share (try on both mobile and desktop)
      try {
        if (isMobile) {
          alert('Bước 2: Vui lòng chọn màn hình thiết bị để giám sát.');
        } else {
          alert('Bước 2: Vui lòng chọn "Toàn màn hình" (Entire Screen) và bấm "Chia sẻ" (Share) để giám sát màn hình.');
        }
        const screenStream = await navigator.mediaDevices.getDisplayMedia({
          video: {
            cursor: isMobile ? "never" : "always",
            width: isMobile ? { ideal: 320 } : { ideal: 640 },
            height: isMobile ? { ideal: 180 } : { ideal: 360 }
          },
          audio: false
        });
        screenStreamRef.current = screenStream;

        // When student stops sharing, prevent quiz taking
        screenStream.getVideoTracks()[0].addEventListener('ended', () => {
          alert('Bạn đã dừng chia sẻ màn hình. Bài kiểm tra sẽ bị hủy.');
          setViewMode('info');
          if (screenStreamRef.current) {
            screenStreamRef.current.getTracks().forEach(track => track.stop());
          }
          if (activeStreamRef.current) {
            activeStreamRef.current.getTracks().forEach(track => track.stop());
          }
        });
      } catch (screenErr) {
        console.warn('Screen share not available:', screenErr);
        if (isMobile) {
          alert('Thiết bị của bạn không hỗ trợ chia sẻ màn hình. Hệ thống sẽ chỉ giám sát qua camera.');
        } else {
          throw screenErr; // Re-throw for desktop - screen share is required
        }
      }

      // Now start the quiz
      setViewMode('take');
      setAnswers({});
      setSubmitted(false);
      setTimeLeft(quiz.timeLimitMinutes > 0 ? quiz.timeLimitMinutes * 60 : null);
    } catch (err) {
      console.error('Camera or screen share denied:', err);
      alert(isMobile
        ? 'Bạn phải cấp quyền camera để bắt đầu làm bài kiểm tra. Hãy thử lại và bấm "Cho phép".'
        : 'Bạn phải cấp quyền camera và chia sẻ toàn màn hình để bắt đầu làm bài kiểm tra. Hãy thử lại và bấm "Cho phép" / "Chia sẻ".');
      // Clean up if partial success
      if (activeStreamRef.current) {
        activeStreamRef.current.getTracks().forEach(track => track.stop());
        activeStreamRef.current = null;
      }
      if (screenStreamRef.current) {
        screenStreamRef.current.getTracks().forEach(track => track.stop());
        screenStreamRef.current = null;
      }
    } finally {
      setRequestingPermissions(false);
    }
  };

  const openTimeDate = quiz.openTime?.toDate ? quiz.openTime.toDate() : (quiz.openTime ? new Date(quiz.openTime) : null);
  const closeTimeDate = quiz.closeTime?.toDate ? quiz.closeTime.toDate() : (quiz.closeTime ? new Date(quiz.closeTime) : null);

  // If no time limits set, quiz is always available
  const hasTimeLimits = openTimeDate || closeTimeDate;

  const isNotOpenYet = hasTimeLimits && openTimeDate && currentTime < openTimeDate;
  const isClosedAlready = hasTimeLimits && closeTimeDate && currentTime > closeTimeDate;
  const isTimeValid = !isNotOpenYet && !isClosedAlready;

  const hasAttempted = attempts.length > 0;

  // ============ BANNED VIEW ============
  if (isBanned) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-8 bg-gray-950 text-white min-h-[500px]">
        <div className="bg-red-500/10 border border-red-500/30 rounded-3xl p-8 max-w-md text-center shadow-2xl space-y-6">
          <div className="w-20 h-20 bg-red-500/25 text-red-500 rounded-full flex items-center justify-center mx-auto border border-red-500/40 animate-pulse">
            <AlertTriangle className="w-10 h-10" />
          </div>
          <h2 className="text-2xl font-bold text-red-400">ĐÌNH CHỈ THI</h2>
          <p className="text-gray-300 text-sm leading-relaxed">
            Bạn đã vi phạm quy chế thi (chuyển tab hoặc rời khỏi trang thi) quá 3 lần. Hệ thống đã đình chỉ quyền làm bài và tự động nộp bài làm hiện tại của bạn.
          </p>
          <div className="p-4 bg-gray-900/50 rounded-xl text-xs text-gray-400 border border-gray-800">
            Hành vi vi phạm đã được ghi nhận và báo cáo chi tiết đến giảng viên lớp học.
          </div>
          <button 
            onClick={() => { setIsBanned(false); setViewMode('info'); }} 
            className="w-full py-3 bg-red-600 hover:bg-red-500 text-white font-semibold rounded-xl transition-colors shadow-lg shadow-red-900/40"
          >
            Quay lại trang thông tin
          </button>
        </div>
      </div>
    );
  }

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
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <InfoItem label="Loại" value={formatMap[quiz.format] || 'N/A'} />
              <InfoItem label="Số câu hỏi" value={`${quiz.questions?.length || 0} câu`} />
              <InfoItem label="Thời gian làm bài" value={quiz.timeLimitMinutes > 0 ? `${quiz.timeLimitMinutes} phút` : 'Không giới hạn'} />
              <InfoItem label="Ngày tạo" value={quiz.createdAt?.toDate?.()?.toLocaleDateString('vi-VN') || 'N/A'} />
              <InfoItem label="Thời gian mở đề" value={openTimeDate ? openTimeDate.toLocaleString('vi-VN') : 'Không giới hạn'} />
              <InfoItem label="Thời gian đóng đề" value={closeTimeDate ? closeTimeDate.toLocaleString('vi-VN') : 'Không giới hạn'} />
            </div>
            {quiz.description && (
              <div className="mt-4 pt-4 border-t border-gray-700">
                <p className="text-sm text-gray-400">{quiz.description}</p>
              </div>
            )}
          </div>

          {/* Action Button (Student) */}
          {role === 'student' && (
            <div className="flex flex-col items-center justify-center space-y-4">
              {isNotOpenYet && (
                <div className="flex items-center space-x-2 text-amber-400 bg-amber-500/10 border border-amber-500/20 px-4 py-3 rounded-xl text-sm">
                  <Clock className="w-4 h-4" />
                  <span>Bài thi chưa mở. Vui lòng quay lại vào lúc {openTimeDate.toLocaleString('vi-VN')}.</span>
                </div>
              )}
              {isClosedAlready && (
                <div className="flex items-center space-x-2 text-red-400 bg-red-500/10 border border-red-500/20 px-4 py-3 rounded-xl text-sm">
                  <AlertTriangle className="w-4 h-4" />
                  <span>Bài thi đã đóng vào lúc {closeTimeDate.toLocaleString('vi-VN')}. Bạn không thể làm bài nữa.</span>
                </div>
              )}

              <button
                disabled={!isTimeValid || requestingPermissions}
                onClick={handleStartQuiz}
                className={`px-8 py-3 rounded-xl font-semibold text-lg flex items-center space-x-3 transition-all ${isTimeValid && !requestingPermissions
                  ? 'bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-500 hover:to-blue-400 text-white shadow-lg shadow-blue-900/40 cursor-pointer'
                  : 'bg-gray-700 text-gray-500 cursor-not-allowed opacity-50'
                  }`}
              >
                {requestingPermissions ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>Đang yêu cầu quyền...</span>
                  </>
                ) : (
                  <>
                    <FileText className="w-5 h-5" />
                    <span>{hasAttempted ? 'Làm lại bài thi' : 'Bắt đầu làm bài'}</span>
                  </>
                )}
              </button>

              {isTimeValid && (
                <div className="space-y-2">
                  <div className="flex items-center space-x-2 text-blue-400 bg-blue-500/5 px-4 py-2 rounded-xl text-xs border border-blue-500/10">
                    <ShieldAlert className="w-3.5 h-3.5" />
                    <span>Hệ thống giám sát camera và tab ẩn sẽ kích hoạt khi bạn bắt đầu thi.</span>
                  </div>
                  <div className="flex items-center space-x-2 text-purple-400 bg-purple-500/5 px-4 py-2 rounded-xl text-xs border border-purple-500/10">
                    <Monitor className="w-3.5 h-3.5" />
                    <span>Yêu cầu chia sẻ màn hình để giảng viên giám sát. Bài sẽ được AI chấm điểm tự động.</span>
                  </div>
                </div>
              )}
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
                            <span className={`font-bold ${(att.score || 0) >= 50 ? 'text-green-400' : 'text-red-400'}`}>
                              {Math.round(((att.score || 0) / 100) * (att.totalQuestions || 1))}/{att.totalQuestions || 1}
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
      <div className="flex-1 flex flex-col h-full overflow-hidden relative">
        {/* Cheating Alert Toast */}
        {cheatingAlert && (
          <div className="fixed top-6 right-6 z-50 animate-bounce flex items-center space-x-3 bg-red-600 text-white px-5 py-4 rounded-2xl shadow-2xl border border-red-500 max-w-sm">
            <div className="p-2 bg-red-700 rounded-lg">
              <AlertTriangle className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="font-bold text-sm">CẢNH BÁO VI PHẠM!</div>
              <div className="text-xs opacity-90 mt-0.5">{cheatingAlert.message}</div>
              <div className="text-xs font-semibold mt-1 bg-red-800 px-2 py-0.5 rounded-md inline-block">Lần vi phạm: {cheatingAlert.count}/3</div>
            </div>
          </div>
        )}

        {/* Sticky Header with Timer */}
        <div className="p-5 border-b border-gray-700/50 bg-gray-800/50 backdrop-blur-md shrink-0">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <button onClick={() => { if (window.confirm('Bạn có muốn thoát? Bài làm sẽ không được lưu.')) { setViewMode('info'); clearInterval(timerRef.current); } }} className="p-2 hover:bg-gray-700 rounded-lg transition-colors">
                <ArrowLeft className="w-5 h-5 text-gray-400" />
              </button>
              <h2 className="text-lg font-bold text-white">{quiz.title}</h2>
            </div>
            <div className="flex items-center space-x-3">
              {role === 'student' && (
                <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 animate-pulse text-xs font-bold">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  <span>ĐANG GIÁM SÁT MÀN HÌNH</span>
                </div>
              )}
              {timeLeft !== null && (
                <div className={`flex items-center space-x-2 px-4 py-2 rounded-xl font-mono text-lg font-bold ${timeLeft < 60 ? 'bg-red-500/20 text-red-400 border border-red-500/30 animate-pulse' : 'bg-gray-700/50 text-white border border-gray-600/50'}`}>
                  <Clock className="w-5 h-5" />
                  <span>{formatTime(timeLeft)}</span>
                </div>
              )}
            </div>
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

        {/* Camera & Screen Preview for Students - Hidden from students, only visible to lecturers */}
        {role !== 'student' && (
          <div className="px-6 py-3 bg-gray-900/30 border-b border-gray-700/30 flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2 text-xs text-gray-400">
                <Camera className="w-4 h-4 text-green-400" />
                <span>Camera: <span className="text-green-400">Đang hoạt động</span></span>
              </div>
              {screenStreamRef.current && (
                <div className="flex items-center space-x-2 text-xs text-gray-400">
                  <Monitor className="w-4 h-4 text-green-400" />
                  <span>Màn hình: <span className="text-green-400">Đang chia sẻ</span></span>
                </div>
              )}
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-16 h-12 bg-black rounded border border-gray-600 overflow-hidden">
                <video id="student-camera-preview" autoPlay muted playsInline className="w-full h-full object-cover" style={{ transform: 'scaleX(-1)' }} />
              </div>
              {screenStreamRef.current && (
                <div className="w-24 h-12 bg-black rounded border border-gray-600 overflow-hidden">
                  <video id="student-screen-preview" autoPlay muted playsInline className="w-full h-full object-cover" />
                </div>
              )}
            </div>
          </div>
        )}

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
                        className={`w-full text-left px-4 py-3 rounded-xl border-2 transition-all duration-200 flex items-center space-x-3 ${isSelected
                          ? 'border-blue-500 bg-blue-500/10 shadow-lg shadow-blue-900/10'
                          : 'border-gray-700 bg-gray-900/30 hover:border-gray-500 hover:bg-gray-800/50'
                          }`}
                      >
                        <span className={`flex items-center justify-center w-7 h-7 rounded-full border-2 text-xs font-bold shrink-0 ${isSelected ? 'border-blue-500 bg-blue-500 text-white' : 'border-gray-600 text-gray-400'
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
              <span className="text-xs">
                {quiz.format !== 'multiple_choice'
                  ? 'Bài sẽ được AI Gemini chấm điểm tự động sau khi nộp.'
                  : 'Kiểm tra kỹ trước khi nộp bài. Bài nộp không thể chỉnh sửa.'
                }
              </span>
            </div>
            <button
              onClick={handleSubmit}
              disabled={submitting}
              className="flex items-center space-x-2 px-8 py-3 bg-gradient-to-r from-green-600 to-emerald-500 hover:from-green-500 hover:to-emerald-400 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl font-semibold shadow-lg shadow-green-900/30 transition-all"
            >
              {submitting ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
              <span>{submitting ? (quiz.format !== 'multiple_choice' ? 'AI đang chấm điểm...' : 'Đang nộp...') : 'Nộp bài'}</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ============ RESULT VIEW ============
  if (viewMode === 'result' && lastResult) {
    const rawScore = lastResult.score > lastResult.totalQuestions
      ? Math.round((lastResult.score / 100) * lastResult.totalQuestions)
      : lastResult.score;
    const percent = quiz.format === 'multiple_choice'
      ? Math.round((rawScore / lastResult.totalQuestions) * 100)
      : (aiResult ? aiResult.score : null);
    const isPass = percent !== null && percent >= 50;
    return (
      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl mx-auto space-y-6">
          {/* Score Card */}
          <div className="bg-gray-800/50 border border-gray-700/50 rounded-3xl p-10 text-center shadow-2xl">
            <div className={`w-24 h-24 mx-auto rounded-full flex items-center justify-center mb-6 ${percent !== null
              ? isPass ? 'bg-green-500/20 border-2 border-green-500/50' : 'bg-red-500/20 border-2 border-red-500/50'
              : 'bg-blue-500/20 border-2 border-blue-500/50'
              }`}>
              {percent !== null ? (
                isPass
                  ? <CheckCircle2 className="w-12 h-12 text-green-400" />
                  : <AlertTriangle className="w-12 h-12 text-red-400" />
              ) : (
                <CheckCircle2 className="w-12 h-12 text-blue-400" />
              )}
            </div>

            <h2 className="text-2xl font-bold text-white mb-2">
              {percent !== null
                ? (isPass ? 'Chúc mừng! 🎉' : 'Hãy cố gắng hơn!')
                : 'Đã nộp bài thành công! ✅'
              }
            </h2>

            {quiz.format === 'multiple_choice' && (
              <div className="my-6">
                <div className="text-5xl font-black text-white">{rawScore}/{lastResult.totalQuestions}</div>
                <div className="text-lg text-gray-400 mt-1">{percent}% đúng</div>
              </div>
            )}

            {quiz.format !== 'multiple_choice' && aiResult && (
              <div className="my-6">
                <div className="text-5xl font-black bg-gradient-to-r from-purple-400 to-blue-400 bg-clip-text text-transparent">{aiResult.score}/100</div>
                <div className="flex items-center justify-center space-x-2 text-purple-400 text-sm mt-2">
                  <Brain className="w-4 h-4" />
                  <span>Chấm điểm bởi AI Gemini</span>
                </div>
                {aiResult.plagiarismScore !== undefined && (
                  <div className="mt-3 flex items-center justify-center space-x-2">
                    <div className={`px-3 py-1 rounded-full text-xs font-medium ${aiResult.plagiarismScore >= 80
                      ? 'bg-green-500/10 text-green-400 border border-green-500/30'
                      : aiResult.plagiarismScore >= 50
                        ? 'bg-amber-500/10 text-amber-400 border border-amber-500/30'
                        : 'bg-red-500/10 text-red-400 border border-red-500/30'
                      }`}>
                      <ShieldAlert className="w-3 h-3 inline mr-1" />
                      Độc đáo: {aiResult.plagiarismScore}%
                    </div>
                  </div>
                )}
              </div>
            )}

            {quiz.format !== 'multiple_choice' && !aiResult && (
              <p className="text-gray-400 my-4">Bài làm của bạn đã được gửi đến giảng viên để chấm điểm.</p>
            )}

            <button
              onClick={() => { setViewMode('info'); setLastResult(null); setAiResult(null); }}
              className="mt-4 px-8 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-medium transition-colors"
            >
              Quay lại
            </button>
          </div>

          {/* AI Feedback Detail Card */}
          {aiResult && (
            <div className="bg-gradient-to-br from-purple-900/20 to-blue-900/20 border border-purple-500/30 rounded-2xl p-6 shadow-xl">
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-10 h-10 rounded-xl bg-purple-500/20 border border-purple-500/40 flex items-center justify-center">
                  <Brain className="w-5 h-5 text-purple-400" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-base">Nhận xét từ AI Gemini</h3>
                  <p className="text-xs text-purple-300/70">Gemini 1.5 Flash — Tự động chấm điểm</p>
                </div>
              </div>

              {/* Overall Feedback */}
              <div className="bg-gray-900/50 rounded-xl p-4 mb-4 border border-gray-700/50">
                <p className="text-sm text-gray-300 leading-relaxed">{aiResult.feedback}</p>
              </div>

              {/* Quality Metrics */}
              {aiResult.qualityMetrics && (
                <div className="bg-gray-900/50 rounded-xl p-4 mb-4 border border-gray-700/50">
                  <h4 className="text-sm font-semibold text-gray-300 mb-3">Chỉ số chất lượng bài làm</h4>
                  <div className="grid grid-cols-3 gap-3">
                    <div className="text-center">
                      <div className="text-lg font-bold text-blue-400">{aiResult.qualityMetrics.understanding || 0}</div>
                      <div className="text-[10px] text-gray-500">Mức độ hiểu bài</div>
                    </div>
                    <div className="text-center">
                      <div className="text-lg font-bold text-purple-400">{aiResult.qualityMetrics.depth || 0}</div>
                      <div className="text-[10px] text-gray-500">Độ sâu phân tích</div>
                    </div>
                    <div className="text-center">
                      <div className="text-lg font-bold text-cyan-400">{aiResult.qualityMetrics.creativity || 0}</div>
                      <div className="text-[10px] text-gray-500">Tính sáng tạo</div>
                    </div>
                  </div>
                </div>
              )}

              {/* Plagiarism Warning */}
              {aiResult.plagiarismWarning && (
                <div className="bg-red-950/30 border border-red-500/40 rounded-xl p-4 mb-4">
                  <div className="flex items-start space-x-2">
                    <AlertTriangle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-sm font-bold text-red-400">Cảnh báo đạo văn</h4>
                      <p className="text-xs text-red-300 mt-1">{aiResult.plagiarismWarning}</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Per-Question Feedback */}
              {aiResult.perQuestion && (
                <div className="space-y-3">
                  <h4 className="text-sm font-semibold text-gray-400 uppercase tracking-wider">Chi tiết từng câu</h4>
                  {aiResult.perQuestion.map((pq, i) => (
                    <div key={i} className="bg-gray-900/40 rounded-xl p-4 border border-gray-700/30">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-bold text-white">Câu {i + 1}</span>
                        <div className="flex items-center space-x-1">
                          {[...Array(10)].map((_, si) => (
                            <Star key={si} className={`w-3 h-3 ${si < pq.score ? 'text-amber-400 fill-amber-400' : 'text-gray-700'}`} />
                          ))}
                          <span className="text-xs font-bold text-amber-400 ml-2">{pq.score}/10</span>
                        </div>
                      </div>
                      <p className="text-xs text-gray-400 mb-2">{pq.comment}</p>
                      {pq.strengths && pq.strengths.length > 0 && (
                        <div className="mt-2">
                          <p className="text-[10px] font-semibold text-green-400 mb-1">✓ Điểm mạnh:</p>
                          <ul className="list-disc list-inside text-[10px] text-gray-400 space-y-0.5">
                            {pq.strengths.map((strength, idx) => (
                              <li key={idx}>{strength}</li>
                            ))}
                          </ul>
                        </div>
                      )}
                      {pq.improvements && pq.improvements.length > 0 && (
                        <div className="mt-2">
                          <p className="text-[10px] font-semibold text-amber-400 mb-1">↑ Cần cải thiện:</p>
                          <ul className="list-disc list-inside text-[10px] text-gray-400 space-y-0.5">
                            {pq.improvements.map((improvement, idx) => (
                              <li key={idx}>{improvement}</li>
                            ))}
                          </ul>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
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
