import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, updateDoc, doc, writeBatch } from 'firebase/firestore';
import { db } from '../firebase';
import { ChevronRight, Save, Loader2, CheckCircle, Award, User, Percent, AlertCircle, FileText, Brain, HelpCircle } from 'lucide-react';

export default function GradebookView({ course, role, email, userId }) {
  const [registrations, setRegistrations] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [submissions, setSubmissions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [gradesMap, setGradesMap] = useState({}); // regId -> { attendance, midterm, final }
  const [toast, setToast] = useState(null);
  
  const isLecturer = role === 'lecturer';

  useEffect(() => {
    if (!course?.docId) return;
    
    // Fetch registrations (students roster)
    const qReg = query(
      collection(db, 'registrations'), 
      where('courseDocId', '==', course.docId)
    );
    const unsubReg = onSnapshot(qReg, snap => {
      const list = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setRegistrations(list);
      
      // Initialize grades map from registrations
      const initialMap = {};
      list.forEach(r => {
        initialMap[r.id] = {
          attendance: r.attendanceScore !== undefined ? r.attendanceScore : '',
          midterm: r.midtermScore !== undefined ? r.midtermScore : '',
          final: r.finalScore !== undefined ? r.finalScore : ''
        };
      });
      setGradesMap(initialMap);
    });

    // Fetch all assignments for this course
    const qAssigns = query(
      collection(db, 'elearning_assignments'),
      where('courseDocId', '==', course.docId)
    );
    const unsubAssigns = onSnapshot(qAssigns, snap => {
      setAssignments(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    // Fetch all submissions for this course
    const qSubs = query(
      collection(db, 'elearning_submissions'),
      where('courseDocId', '==', course.docId)
    );
    const unsubSubs = onSnapshot(qSubs, snap => {
      setSubmissions(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    }, () => setLoading(false));

    return () => {
      unsubReg();
      unsubAssigns();
      unsubSubs();
    };
  }, [course.docId]);

  // Helper to calculate student's assignment average score (normalized to scale of 10)
  const getStudentAssignmentAvg = (studentEmail) => {
    const studentSubs = submissions.filter(s => s.userEmail === studentEmail && s.status === 'graded');
    if (studentSubs.length === 0) return null;

    let totalPtsScored = 0;
    let count = 0;

    const assignsMap = {};
    assignments.forEach(a => { assignsMap[a.id] = a.points || 10; });

    studentSubs.forEach(s => {
      const maxPts = assignsMap[s.assignmentId] || 10;
      if (s.score !== undefined && s.score !== null) {
        totalPtsScored += (s.score / maxPts) * 10;
        count++;
      }
    });

    return count > 0 ? parseFloat((totalPtsScored / count).toFixed(1)) : null;
  };

  const handleGradeChange = (regId, field, val) => {
    const numericVal = val === '' ? '' : parseFloat(val);
    if (numericVal !== '' && (isNaN(numericVal) || numericVal < 0 || numericVal > 10)) return;
    
    setGradesMap(prev => ({
      ...prev,
      [regId]: {
        ...prev[regId],
        [field]: val === '' ? '' : numericVal
      }
    }));
  };

  // 10% Attendance (linked to Assignment Avg if exists, else custom)
  // 20% Midterm Score
  // 70% Final Exam Score
  const calculateTotal = (attendance, midterm, final, studentEmail) => {
    // If student has graded assignments, automatically override attendance with assignments average
    const aiAtt = getStudentAssignmentAvg(studentEmail);
    const att = aiAtt !== null ? aiAtt : (attendance === '' ? 0 : Number(attendance));
    const mid = midterm === '' ? 0 : Number(midterm);
    const fin = final === '' ? 0 : Number(final);
    const total = (att * 0.1) + (mid * 0.2) + (fin * 0.7);
    return parseFloat(total.toFixed(1));
  };

  const getLetterGrade = (total) => {
    if (total >= 8.5) return 'A';
    if (total >= 7.0) return 'B';
    if (total >= 5.5) return 'C';
    if (total >= 4.0) return 'D';
    return 'F';
  };

  const getGPA4 = (letter) => {
    switch(letter) {
      case 'A': return 4.0;
      case 'B': return 3.0;
      case 'C': return 2.0;
      case 'D': return 1.0;
      default: return 0.0;
    }
  };

  const handleSaveGrades = async () => {
    setSaving(true);
    try {
      const batch = writeBatch(db);
      Object.keys(gradesMap).forEach(regId => {
        const reg = registrations.find(r => r.id === regId);
        if (!reg) return;

        const { attendance, midterm, final } = gradesMap[regId];
        
        // Calculate fields
        const aiAtt = getStudentAssignmentAvg(reg.studentEmail);
        const attScore = aiAtt !== null ? aiAtt : (attendance === '' ? null : Number(attendance));
        const midScore = midterm === '' ? null : Number(midterm);
        const finScore = final === '' ? null : Number(final);
        
        const updateData = {};
        if (attScore !== null) updateData.attendanceScore = attScore;
        if (midScore !== null) updateData.midtermScore = midScore;
        if (finScore !== null) updateData.finalScore = finScore;
        
        if (attScore !== null && midScore !== null && finScore !== null) {
          const total = calculateTotal(attScore, midScore, finScore, reg.studentEmail);
          const letter = getLetterGrade(total);
          updateData.total10 = total;
          updateData.letterGrade = letter;
          updateData.gpa4 = getGPA4(letter);
        }
        
        updateData.gradeStatus = 'lecturer_saved';
        const ref = doc(db, 'registrations', regId);
        batch.update(ref, updateData);
      });

      await batch.commit();
      setToast('Đã lưu điểm số thành công!');
      setTimeout(() => setToast(null), 2500);
    } catch(e) {
      console.error(e);
      setToast('Lỗi khi lưu điểm số!');
      setTimeout(() => setToast(null), 2500);
    }
    setSaving(false);
  };

  const handlePublishGrades = async () => {
    if (!window.confirm('Bạn có chắc chắn muốn công bố điểm? Điểm số sẽ được hiển thị trực tiếp cho Sinh viên.')) return;
    setSaving(true);
    try {
      const batch = writeBatch(db);
      Object.keys(gradesMap).forEach(regId => {
        const reg = registrations.find(r => r.id === regId);
        if (!reg) return;

        const { attendance, midterm, final } = gradesMap[regId];
        const aiAtt = getStudentAssignmentAvg(reg.studentEmail);
        const attScore = aiAtt !== null ? aiAtt : (attendance === '' ? 0 : Number(attendance));
        const midScore = midterm === '' ? 0 : Number(midterm);
        const finScore = final === '' ? 0 : Number(final);
        
        const total = calculateTotal(attScore, midScore, finScore, reg.studentEmail);
        const letter = getLetterGrade(total);
        
        const ref = doc(db, 'registrations', regId);
        batch.update(ref, {
          attendanceScore: attScore,
          midtermScore: midScore,
          finalScore: finScore,
          total10: total,
          letterGrade: letter,
          gpa4: getGPA4(letter),
          gradeStatus: 'admin_published'
        });
      });

      await batch.commit();
      setToast('Đã công bố điểm cho lớp học!');
      setTimeout(() => setToast(null), 2500);
    } catch(e) {
      console.error(e);
      setToast('Lỗi khi công bố điểm!');
    }
    setSaving(false);
  };

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0', fontFamily: 'Inter, sans-serif' },
    banner: { backgroundColor: '#cc0000', padding: '14px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 1200, margin: '0 auto' },
    card: { border: '1px solid #2a2d38', borderRadius: 8, overflow: 'hidden', backgroundColor: '#1e2129', marginBottom: 22, boxShadow: '0 4px 12px rgba(0,0,0,0.15)' },
    cardHeader: { backgroundColor: '#20232d', padding: '14px 20px', fontSize: 14.5, fontWeight: 700, borderBottom: '1px solid #2a2d38', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#e0e0e0' },
    btn: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 16px', background: '#2563eb', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' },
    btnOutline: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 16px', background: 'transparent', color: '#9ca3af', border: '1px solid #3f4350', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' },
    table: { width: '100%', borderCollapse: 'collapse', fontSize: 13, color: '#c8ccd0' },
    th: { textAlign: 'left', padding: '12px 16px', background: '#20232d', borderBottom: '1.5px solid #2a2d38', fontWeight: 600, color: '#e0e0e0' },
    td: { padding: '12px 16px', borderBottom: '1px solid #2a2d38', verticalAlign: 'middle' },
    input: { width: 68, padding: '6px 8px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 4, color: '#e0e0e0', fontSize: 13, outline: 'none', textAlign: 'center' },
    gradeBadge: { display: 'inline-flex', alignItems: 'center', gap: 4, padding: '3px 8px', borderRadius: 4, fontSize: 11, fontWeight: 700 },
    alert: { display: 'flex', alignItems: 'center', gap: 8, padding: '12px 16px', background: 'rgba(251,191,36,0.03)', border: '1px solid rgba(251,191,36,0.15)', borderRadius: 6, color: '#fbbf24', fontSize: 12.5, marginBottom: 20 }
  };

  // Student view
  if (!isLecturer) {
    const myReg = registrations.find(r => r.userId === userId);
    const hasPublished = myReg?.gradeStatus === 'admin_published';
    const myAssignments = assignments.map(a => {
      const sub = submissions.find(s => s.assignmentId === a.id && s.userId === userId);
      return { ...a, sub };
    });
    const myAvg = getStudentAssignmentAvg(email);
    
    return (
      <div style={s.page}>
        <div style={s.banner}>
          <span>{course.courseId} {course.courseName} <ChevronRight size={16} style={{ margin: '0 8px', verticalAlign: 'middle' }} /> Bảng điểm cá nhân</span>
        </div>
        <div style={s.container}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: 24, alignItems: 'start' }}>
            {/* Standard Gradecard */}
            <div style={s.card}>
              <div style={s.cardHeader}>
                <span>Phiếu điểm học tập</span>
              </div>
              <div style={{ padding: 20 }}>
                {loading ? (
                  <div style={{ textAlign: 'center', padding: 20 }}><Loader2 size={24} style={{ color: '#3b82f6', animation: 'spin 1s linear infinite' }} /></div>
                ) : !myReg ? (
                  <div style={{ textAlign: 'center', color: '#6b7280' }}>Không tìm thấy thông tin đăng ký lớp.</div>
                ) : !hasPublished ? (
                  <div style={{ textAlign: 'center', color: '#9ca3af', padding: '20px 0' }}>
                    <AlertCircle size={36} style={{ color: '#fbbf24', marginBottom: 12, opacity: 0.8 }} />
                    <p style={{ fontWeight: 600 }}>Điểm số chưa được công bố chính thức</p>
                    <p style={{ fontSize: 12, color: '#6b7280', marginTop: 4 }}>Vui lòng đợi Giảng viên chấm điểm và đồng bộ điểm tổng kết.</p>
                  </div>
                ) : (
                  <div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: 12, borderBottom: '1px solid #2a2d38' }}>
                        <span style={{ color: '#9ca3af' }}>Họ và tên</span>
                        <span style={{ fontWeight: 600 }}>{myReg.studentName}</span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: 12, borderBottom: '1px solid #2a2d38' }}>
                        <span style={{ color: '#9ca3af' }}>Mã sinh viên</span>
                        <span style={{ fontWeight: 600 }}>{myReg.studentId}</span>
                      </div>
                      
                      {/* Component grades */}
                      <div style={{ display: 'flex', justifyContent: 'space-between', paddingTop: 8 }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>Chuyên cần / Bài tập (10%) {myAvg !== null && <span style={{ fontSize: 10.5, color: '#10b981', background: 'rgba(16,185,129,0.1)', padding: '2px 6px', borderRadius: 4 }}>Tự động từ AI</span>}</span>
                        <span style={{ fontWeight: 600 }}>{myReg.attendanceScore}</span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span>Điểm giữa kỳ (20%)</span>
                        <span style={{ fontWeight: 600 }}>{myReg.midtermScore}</span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span>Điểm cuối kỳ (70%)</span>
                        <span style={{ fontWeight: 600 }}>{myReg.finalScore}</span>
                      </div>
                      
                      {/* Final summary */}
                      <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid #3f4350', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <div style={{ fontSize: 15, fontWeight: 700, color: '#fff' }}>Tổng kết (Hệ 10)</div>
                          <div style={{ fontSize: 11.5, color: '#9ca3af', marginTop: 2 }}>Quy đổi hệ 4: {myReg.gpa4?.toFixed(1)}</div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <span style={{ fontSize: 24, fontWeight: 800, color: '#60a5fa' }}>{myReg.total10}</span>
                          <span style={{ ...s.gradeBadge, fontSize: 13, padding: '4px 10px', background: myReg.letterGrade === 'F' ? 'rgba(239,68,68,0.15)' : 'rgba(16,185,129,0.15)', border: `1px solid ${myReg.letterGrade === 'F' ? 'rgba(239,68,68,0.3)' : 'rgba(16,185,129,0.3)'}`, color: myReg.letterGrade === 'F' ? '#ef4444' : '#10b981' }}>
                            {myReg.letterGrade}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Assignments Breakdown for Student */}
            <div style={s.card}>
              <div style={s.cardHeader}>
                <span>Chi tiết điểm bài tập (AI đánh giá)</span>
                {myAvg !== null && <span style={{ color: '#10b981', fontWeight: 600, fontSize: 12.5 }}>Trung bình: {myAvg}/10</span>}
              </div>
              <div style={{ padding: 20 }}>
                {myAssignments.length === 0 ? (
                  <div style={{ textAlign: 'center', color: '#6b7280', padding: 20 }}>Không có bài tập trong khóa học này.</div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                    {myAssignments.map(a => {
                      const hasGraded = a.sub?.status === 'graded';
                      return (
                        <div key={a.id} style={{ background: '#12141a', border: '1px solid #2a2d38', borderRadius: 8, padding: 14 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                            <div style={{ fontWeight: 600, color: '#fff' }}>{a.title}</div>
                            <span style={{ fontWeight: 700, color: hasGraded ? '#10b981' : '#f59e0b', fontSize: 13 }}>
                              {hasGraded ? `${a.sub.score}/${a.points}đ` : (a.sub ? 'Chờ chấm điểm' : 'Chưa nộp')}
                            </span>
                          </div>
                          {a.sub?.feedback ? (
                            <div style={{ marginTop: 8, padding: '8px 12px', background: 'rgba(99,102,241,0.03)', border: '1px dashed rgba(99,102,241,0.2)', borderRadius: 6, fontSize: 11.5, color: '#c7d2fe', lineHeight: 1.4 }}>
                              <Brain size={12} style={{ display: 'inline', marginRight: 6, verticalAlign: 'middle', color: '#8b5cf6' }} />
                              {a.sub.feedback}
                            </div>
                          ) : (
                            <div style={{ fontSize: 11, color: '#6b7280', marginTop: 4 }}>Chưa có phản hồi từ trợ lý giảng dạy AI.</div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Lecturer view
  return (
    <div style={s.page}>
      <div style={s.banner}>
        <span>{course.courseId} {course.courseName} <ChevronRight size={16} style={{ margin: '0 8px', verticalAlign: 'middle' }} /> Bảng điểm lớp học</span>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={s.btnOutline} onClick={handleSaveGrades} disabled={saving}>
            <Save size={14}/> Lưu nháp
          </button>
          <button style={s.btn} onClick={handlePublishGrades} disabled={saving}>
            <Award size={14}/> Công bố & Đồng bộ
          </button>
        </div>
      </div>
      <div style={s.container}>
        <div style={s.alert}>
          <Percent size={14}/>
          <span>
            Tính điểm: 10% Chuyên cần (Hệ thống tự động đồng bộ trung bình cộng điểm các bài tập đã chấm) + 20% Giữa kỳ + 70% Cuối kỳ.
          </span>
        </div>
        
        <div style={s.card}>
          <div style={s.cardHeader}>
            <span>Bảng tổng hợp điểm số lớp ({registrations.length} sinh viên)</span>
            {saving && <span style={{ fontSize: 12, fontWeight: 'normal', color: '#9ca3af', display: 'flex', alignItems: 'center', gap: 4 }}><Loader2 size={12} style={{ animation: 'spin 1s linear infinite' }} /> Đang xử lý...</span>}
          </div>
          {loading ? (
            <div style={{ textAlign: 'center', padding: 60 }}><Loader2 size={32} style={{ color: '#cc0000', animation: 'spin 1s linear infinite' }} /></div>
          ) : registrations.length === 0 ? (
            <div style={{ textAlign: 'center', padding: 40, color: '#6b7280' }}>Chưa có sinh viên đăng ký lớp học này.</div>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={s.table}>
                <thead>
                  <tr>
                    <th style={s.th}>Họ và tên / Mã SV</th>
                    {assignments.map(a => (
                      <th key={a.id} style={{ ...s.th, textAlign: 'center', fontSize: 11.5, maxWidth: 100, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={a.title}>
                        {a.title} ({a.points}đ)
                      </th>
                    ))}
                    <th style={{ ...s.th, textAlign: 'center' }}>TB Bài tập (10%)</th>
                    <th style={{ ...s.th, textAlign: 'center' }}>Giữa kỳ (20%)</th>
                    <th style={{ ...s.th, textAlign: 'center' }}>Cuối kỳ (70%)</th>
                    <th style={{ ...s.th, textAlign: 'center' }}>Tổng kết</th>
                    <th style={{ ...s.th, textAlign: 'center' }}>Điểm chữ</th>
                    <th style={s.th}>Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  {registrations.map(r => {
                    const grade = gradesMap[r.id] || { attendance: '', midterm: '', final: '' };
                    const assignmentAvg = getStudentAssignmentAvg(r.studentEmail);
                    
                    // attendance score uses assignmentAvg if available, otherwise fallback to standard input
                    const displayAttendance = assignmentAvg !== null ? assignmentAvg : grade.attendance;
                    const total = calculateTotal(grade.attendance, grade.midterm, grade.final, r.studentEmail);
                    const letter = getLetterGrade(total);
                    const isPublished = r.gradeStatus === 'admin_published';
                    
                    return (
                      <tr key={r.id}>
                        <td style={s.td}>
                          <div style={{ fontWeight: 600, color: '#fff' }}>{r.studentName}</div>
                          <div style={{ fontSize: 11, color: '#6b7280', marginTop: 2 }}>{r.studentId} | {r.studentEmail}</div>
                        </td>

                        {/* Individual Assignment Scores */}
                        {assignments.map(a => {
                          const sub = submissions.find(s => s.assignmentId === a.id && s.userEmail === r.studentEmail);
                          const isSubGraded = sub?.status === 'graded';
                          return (
                            <td key={a.id} style={{ ...s.td, textAlign: 'center', fontSize: 12 }}>
                              {sub ? (
                                <span style={{ color: isSubGraded ? '#10b981' : '#f59e0b', fontWeight: isSubGraded ? 'bold' : 'normal' }}>
                                  {isSubGraded ? `${sub.score}/${a.points}` : 'Chờ chấm'}
                                </span>
                              ) : (
                                <span style={{ color: '#4b5563' }}>-</span>
                              )}
                            </td>
                          );
                        })}

                        {/* TB Bài tập (10%) */}
                        <td style={{ ...s.td, textAlign: 'center', fontWeight: 'bold', color: assignmentAvg !== null ? '#10b981' : '#e0e0e0' }}>
                          {assignmentAvg !== null ? assignmentAvg : (
                            <input 
                              style={s.input} 
                              type="number" 
                              min={0} max={10} step={0.1}
                              value={grade.attendance} 
                              onChange={e => handleGradeChange(r.id, 'attendance', e.target.value)}
                              placeholder="Nhập tay"
                            />
                          )}
                        </td>

                        {/* Giữa kỳ (20%) */}
                        <td style={{ ...s.td, textAlign: 'center' }}>
                          <input 
                            style={s.input} 
                            type="number" 
                            min={0} max={10} step={0.1}
                            value={grade.midterm} 
                            onChange={e => handleGradeChange(r.id, 'midterm', e.target.value)}
                          />
                        </td>

                        {/* Cuối kỳ (70%) */}
                        <td style={{ ...s.td, textAlign: 'center' }}>
                          <input 
                            style={s.input} 
                            type="number" 
                            min={0} max={10} step={0.1}
                            value={grade.final} 
                            onChange={e => handleGradeChange(r.id, 'final', e.target.value)}
                          />
                        </td>

                        {/* Tổng kết */}
                        <td style={{ ...s.td, textAlign: 'center', fontWeight: 800, color: '#60a5fa', fontSize: 14 }}>{total}</td>
                        
                        {/* Điểm chữ */}
                        <td style={{ ...s.td, textAlign: 'center' }}>
                          <span style={{ ...s.gradeBadge, background: letter === 'F' ? 'rgba(239,68,68,0.15)' : 'rgba(16,185,129,0.15)', border: `1px solid ${letter === 'F' ? 'rgba(239,68,68,0.3)' : 'rgba(16,185,129,0.3)'}`, color: letter === 'F' ? '#ef4444' : '#10b981' }}>
                            {letter}
                          </span>
                        </td>

                        {/* Trạng thái */}
                        <td style={s.td}>
                          <span style={{ fontSize: 11.5, color: isPublished ? '#10b981' : '#fbbf24', fontWeight: 600 }}>
                            {isPublished ? 'Đã công bố' : 'Lưu nháp'}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
      {toast && <div className="toast-notification success"><CheckCircle size={16} />{toast}</div>}
    </div>
  );
}
