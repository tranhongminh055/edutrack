import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, orderBy, limit } from 'firebase/firestore';
import { db } from '../firebase';
import { User, MessageSquare, ChevronRight, HelpCircle, Users, FileSignature, BookOpen, Bell, Calendar, ClipboardList, Award, TrendingUp, Clock, Loader2 } from 'lucide-react';

export default function CourseHomeView({ course, role, email }) {
  const courseTitle = course ? `${course.courseId || ''} ${course.courseName} (${course.classGroup})` : 'Course Home';
  const isLecturer = role === 'lecturer';

  const [stats, setStats] = useState({ students: 0, announcements: 0, assignments: 0, lessons: 0, resources: 0 });
  const [recentAnnouncements, setRecentAnnouncements] = useState([]);
  const [recentAssignments, setRecentAssignments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!course?.docId) return;
    const unsubs = [];

    // Student count
    const qStudents = query(collection(db, 'registrations'), where('courseDocId', '==', course.docId));
    unsubs.push(onSnapshot(qStudents, snap => {
      setStats(prev => ({ ...prev, students: snap.size }));
    }));

    // Announcements
    const qAnn = query(collection(db, 'elearning_course_announcements'), where('courseDocId', '==', course.docId), orderBy('createdAt', 'desc'), limit(5));
    unsubs.push(onSnapshot(qAnn, snap => {
      setRecentAnnouncements(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setStats(prev => ({ ...prev, announcements: snap.size }));
    }));

    // Assignments
    const qAsg = query(collection(db, 'elearning_assignments'), where('courseDocId', '==', course.docId));
    unsubs.push(onSnapshot(qAsg, snap => {
      setRecentAssignments(snap.docs.map(d => ({ id: d.id, ...d.data() })).sort((a, b) => new Date(b.dueDate) - new Date(a.dueDate)).slice(0, 3));
      setStats(prev => ({ ...prev, assignments: snap.size }));
    }));

    // Lessons
    const qLes = query(collection(db, 'elearning_lessons'), where('courseDocId', '==', course.docId));
    unsubs.push(onSnapshot(qLes, snap => {
      setStats(prev => ({ ...prev, lessons: snap.size }));
    }));

    // Resources
    const qRes = query(collection(db, 'elearning_resources'), where('courseDocId', '==', course.docId));
    unsubs.push(onSnapshot(qRes, snap => {
      setStats(prev => ({ ...prev, resources: snap.size }));
      setLoading(false);
    }));

    return () => unsubs.forEach(u => u());
  }, [course?.docId]);

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff' },
    container: { padding: '20px 30px', maxWidth: 1200, margin: '0 auto' },
    card: { border: '1px solid #2a2d38', borderRadius: 6, overflow: 'hidden', backgroundColor: '#1e2129' },
    cardHeader: { backgroundColor: '#2a2d38', padding: '12px 16px', fontSize: 14, fontWeight: 'bold', borderBottom: '1px solid #33363f', display: 'flex', alignItems: 'center', gap: 8 },
    cardBody: { padding: '16px' },
    statCard: { flex: 1, padding: '16px 20px', borderRadius: 8, border: '1px solid #2a2d38', backgroundColor: '#1e2129', display: 'flex', alignItems: 'center', gap: 14, transition: 'transform 0.15s', cursor: 'default' },
    statIcon: { width: 44, height: 44, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 },
    statNum: { fontSize: 22, fontWeight: 800, color: '#fff', lineHeight: 1 },
    statLabel: { fontSize: 12, color: '#9ca3af', marginTop: 2 },
  };

  return (
    <div style={s.page}>
      <div style={s.banner}>
        <div style={{ display: 'flex', alignItems: 'center', fontSize: 14, fontWeight: 'bold' }}>
          {courseTitle} <ChevronRight size={16} style={{ margin: '0 8px' }} /> Home
        </div>
        <HelpCircle size={18} />
      </div>

      <div style={s.container}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20, color: '#d1d5db', fontSize: 14 }}>
          <User size={16} /> Your role is {isLecturer ? 'Instructor' : 'Student'}
        </div>

        {/* Stats Row */}
        <div style={{ display: 'flex', gap: 14, marginBottom: 24, flexWrap: 'wrap' }}>
          <div style={s.statCard}>
            <div style={{ ...s.statIcon, background: 'rgba(59,130,246,0.15)', color: '#60a5fa' }}><Users size={22} /></div>
            <div><div style={s.statNum}>{stats.students}</div><div style={s.statLabel}>Sinh viên</div></div>
          </div>
          <div style={s.statCard}>
            <div style={{ ...s.statIcon, background: 'rgba(245,158,11,0.15)', color: '#f59e0b' }}><Bell size={22} /></div>
            <div><div style={s.statNum}>{stats.announcements}</div><div style={s.statLabel}>Thông báo</div></div>
          </div>
          <div style={s.statCard}>
            <div style={{ ...s.statIcon, background: 'rgba(139,92,246,0.15)', color: '#8b5cf6' }}><FileSignature size={22} /></div>
            <div><div style={s.statNum}>{stats.assignments}</div><div style={s.statLabel}>Bài tập</div></div>
          </div>
          <div style={s.statCard}>
            <div style={{ ...s.statIcon, background: 'rgba(16,185,129,0.15)', color: '#10b981' }}><BookOpen size={22} /></div>
            <div><div style={s.statNum}>{stats.lessons}</div><div style={s.statLabel}>Bài giảng</div></div>
          </div>
          <div style={s.statCard}>
            <div style={{ ...s.statIcon, background: 'rgba(236,72,153,0.15)', color: '#ec4899' }}><ClipboardList size={22} /></div>
            <div><div style={s.statNum}>{stats.resources}</div><div style={s.statLabel}>Tài nguyên</div></div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 24, alignItems: 'flex-start' }}>
          {/* Left Column */}
          <div style={{ flex: 2, display: 'flex', flexDirection: 'column', gap: 24 }}>
            {/* Course Information */}
            <div style={s.card}>
              <div style={s.cardHeader}><BookOpen size={16} /> Course Information</div>
              <div style={s.cardBody}>
                <table style={{ width: '100%', fontSize: 13, color: '#c8ccd0' }}>
                  <tbody>
                    <tr><td style={{ padding: '8px 0', color: '#9ca3af', width: 140 }}>Mã môn học</td><td style={{ fontWeight: 600 }}>{course.courseId}</td></tr>
                    <tr><td style={{ padding: '8px 0', color: '#9ca3af' }}>Tên môn học</td><td style={{ fontWeight: 600 }}>{course.courseName}</td></tr>
                    <tr><td style={{ padding: '8px 0', color: '#9ca3af' }}>Lớp</td><td>{course.classGroup}</td></tr>
                    <tr><td style={{ padding: '8px 0', color: '#9ca3af' }}>Ngành</td><td>{course.major || 'N/A'}</td></tr>
                    <tr><td style={{ padding: '8px 0', color: '#9ca3af' }}>Giảng viên</td><td>{course.lecturerName || course.lecturerEmail}</td></tr>
                    <tr><td style={{ padding: '8px 0', color: '#9ca3af' }}>Học kỳ</td><td>{course.semester} - {course.academicYear}</td></tr>
                    {course.room && <tr><td style={{ padding: '8px 0', color: '#9ca3af' }}>Phòng học</td><td>{course.room}</td></tr>}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Recent Assignments */}
            {recentAssignments.length > 0 && (
              <div style={s.card}>
                <div style={s.cardHeader}><FileSignature size={16} /> Bài tập gần đây</div>
                <div style={{ ...s.cardBody, padding: 0 }}>
                  {recentAssignments.map(a => {
                    const isLate = new Date(a.dueDate) < new Date();
                    return (
                      <div key={a.id} style={{ padding: '12px 16px', borderBottom: '1px solid #2a2d38', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <div style={{ fontSize: 14, fontWeight: 600, color: '#e0e0e0' }}>{a.title}</div>
                          <div style={{ fontSize: 12, color: '#9ca3af', marginTop: 2 }}>{a.points} điểm • {a.type === 'project' ? 'Đồ án' : 'Bài tập'}</div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: isLate ? '#ef4444' : '#10b981' }}>
                          <Clock size={12} /> {new Date(a.dueDate).toLocaleDateString('vi-VN')}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>

          {/* Right Column */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 24 }}>
            {/* Latest Announcements */}
            <div style={s.card}>
              <div style={s.cardHeader}><Bell size={16} /> Thông báo mới nhất</div>
              <div style={s.cardBody}>
                {recentAnnouncements.length > 0 ? (
                  recentAnnouncements.slice(0, 3).map(a => {
                    const date = a.createdAt?.toDate?.();
                    return (
                      <div key={a.id} style={{ marginBottom: 14, paddingBottom: 14, borderBottom: '1px solid #2a2d38' }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: '#60a5fa' }}>{a.title}</div>
                        <div style={{ fontSize: 11, color: '#6b7280', marginTop: 4 }}>
                          {a.authorName || a.createdBy} {date ? `• ${date.toLocaleDateString('vi-VN')}` : ''}
                        </div>
                        {a.content && <p style={{ fontSize: 12, color: '#9ca3af', marginTop: 6, lineHeight: 1.5, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{a.content}</p>}
                      </div>
                    );
                  })
                ) : (
                  <p style={{ fontSize: 13, color: '#6b7280' }}>Chưa có thông báo.</p>
                )}
              </div>
            </div>

            {/* Quick Actions for Lecturer */}
            {isLecturer && (
              <div style={s.card}>
                <div style={s.cardHeader}><TrendingUp size={16} /> Công cụ Giảng viên</div>
                <div style={s.cardBody}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    <div style={{ padding: '10px 14px', background: 'rgba(59,130,246,0.08)', borderRadius: 6, border: '1px solid rgba(59,130,246,0.15)', fontSize: 13, color: '#93c5fd', display: 'flex', alignItems: 'center', gap: 8 }}>
                      <Award size={14} /> Nhập điểm tại mục <strong>Gradebook</strong>
                    </div>
                    <div style={{ padding: '10px 14px', background: 'rgba(139,92,246,0.08)', borderRadius: 6, border: '1px solid rgba(139,92,246,0.15)', fontSize: 13, color: '#c4b5fd', display: 'flex', alignItems: 'center', gap: 8 }}>
                      <FileSignature size={14} /> Giao bài tập tại mục <strong>Assignments</strong>
                    </div>
                    <div style={{ padding: '10px 14px', background: 'rgba(245,158,11,0.08)', borderRadius: 6, border: '1px solid rgba(245,158,11,0.15)', fontSize: 13, color: '#fcd34d', display: 'flex', alignItems: 'center', gap: 8 }}>
                      <Bell size={14} /> Đăng thông báo tại mục <strong>Announcements</strong>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Messages Center */}
            <div style={s.card}>
              <div style={s.cardHeader}><MessageSquare size={16} /> Messages Center</div>
              <div style={s.cardBody}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                  <span style={{ color: '#60a5fa' }}>New Messages</span>
                  <span style={{ color: '#9ca3af' }}>none</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
