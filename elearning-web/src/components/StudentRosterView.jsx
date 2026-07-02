import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';
import { ChevronRight, Users, Loader2, Search, Mail, User, Hash, GraduationCap } from 'lucide-react';

export default function StudentRosterView({ course, role, email }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const isLecturer = role === 'lecturer';

  useEffect(() => {
    if (!course?.docId) return;
    const q = query(collection(db, 'registrations'), where('courseDocId', '==', course.docId));
    const unsub = onSnapshot(q, snap => {
      setStudents(snap.docs.map(d => ({ id: d.id, ...d.data() })).sort((a, b) => (a.studentName || '').localeCompare(b.studentName || '')));
      setLoading(false);
    }, () => setLoading(false));
    return unsub;
  }, [course.docId]);

  const filtered = students.filter(s =>
    (s.studentName || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (s.studentId || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (s.studentEmail || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 1000, margin: '0 auto' },
    card: { border: '1px solid #2a2d38', borderRadius: 6, overflow: 'hidden', backgroundColor: '#1e2129' },
    cardHeader: { backgroundColor: '#2a2d38', padding: '12px 16px', fontSize: 14, fontWeight: 700, borderBottom: '1px solid #33363f', display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
    searchBox: { display: 'flex', alignItems: 'center', gap: 8, background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, padding: '6px 12px', marginBottom: 16 },
    searchInput: { background: 'none', border: 'none', color: '#e0e0e0', fontSize: 13, outline: 'none', flex: 1 },
    table: { width: '100%', borderCollapse: 'collapse', fontSize: 13, color: '#c8ccd0' },
    th: { textAlign: 'left', padding: '12px 16px', background: '#2a2d38', borderBottom: '1px solid #3f4350', fontWeight: 600, color: '#e0e0e0' },
    td: { padding: '12px 16px', borderBottom: '1px solid #2a2d38' },
  };

  return (
    <div style={s.page}>
      <div style={s.banner}>
        <span>{course.courseId} {course.courseName} ({course.classGroup}) <ChevronRight size={16} style={{ margin: '0 8px', verticalAlign: 'middle' }} /> Danh sách lớp</span>
        <span style={{ fontWeight: 400, fontSize: 13 }}>{students.length} sinh viên</span>
      </div>
      <div style={s.container}>
        {/* Summary */}
        <div style={{ display: 'flex', gap: 16, marginBottom: 20 }}>
          <div style={{ flex: 1, padding: '16px 20px', borderRadius: 8, border: '1px solid #2a2d38', backgroundColor: '#1e2129', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(59,130,246,0.15)', color: '#60a5fa', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Users size={20} /></div>
            <div><div style={{ fontSize: 20, fontWeight: 800, color: '#fff' }}>{students.length}</div><div style={{ fontSize: 12, color: '#9ca3af' }}>Tổng sinh viên</div></div>
          </div>
          <div style={{ flex: 1, padding: '16px 20px', borderRadius: 8, border: '1px solid #2a2d38', backgroundColor: '#1e2129', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(16,185,129,0.15)', color: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GraduationCap size={20} /></div>
            <div><div style={{ fontSize: 20, fontWeight: 800, color: '#fff' }}>{course.classGroup}</div><div style={{ fontSize: 12, color: '#9ca3af' }}>Lớp học phần</div></div>
          </div>
          <div style={{ flex: 1, padding: '16px 20px', borderRadius: 8, border: '1px solid #2a2d38', backgroundColor: '#1e2129', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(245,158,11,0.15)', color: '#f59e0b', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Hash size={20} /></div>
            <div><div style={{ fontSize: 20, fontWeight: 800, color: '#fff' }}>{course.courseId}</div><div style={{ fontSize: 12, color: '#9ca3af' }}>Mã môn học</div></div>
          </div>
        </div>

        {/* Search */}
        <div style={s.searchBox}>
          <Search size={16} style={{ color: '#6b7280' }} />
          <input style={s.searchInput} placeholder="Tìm kiếm theo tên, mã SV, email..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} />
        </div>

        {/* Table */}
        <div style={s.card}>
          <div style={s.cardHeader}>
            <span>Danh sách sinh viên ({filtered.length})</span>
          </div>
          {loading ? (
            <div style={{ textAlign: 'center', padding: 60 }}><Loader2 size={32} style={{ color: '#3b82f6', animation: 'spin 1s linear infinite' }} /></div>
          ) : filtered.length === 0 ? (
            <div style={{ textAlign: 'center', padding: 40, color: '#6b7280' }}>
              {searchTerm ? 'Không tìm thấy kết quả phù hợp.' : 'Chưa có sinh viên nào đăng ký lớp học này.'}
            </div>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={s.table}>
                <thead>
                  <tr>
                    <th style={s.th}>STT</th>
                    <th style={s.th}>Họ và tên</th>
                    <th style={s.th}>Mã SV</th>
                    <th style={s.th}>Email</th>
                    <th style={s.th}>Trạng thái</th>
                    {isLecturer && <th style={s.th}>Điểm</th>}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((stu, idx) => (
                    <tr key={stu.id}>
                      <td style={s.td}>{idx + 1}</td>
                      <td style={s.td}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{ width: 32, height: 32, borderRadius: '50%', background: 'rgba(99,102,241,0.15)', color: '#818cf8', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700, flexShrink: 0 }}>
                            {(stu.studentName || '?')[0].toUpperCase()}
                          </div>
                          <span style={{ fontWeight: 600, color: '#fff' }}>{stu.studentName}</span>
                        </div>
                      </td>
                      <td style={s.td}><code style={{ color: '#60a5fa', fontSize: 12 }}>{stu.studentId}</code></td>
                      <td style={s.td}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, color: '#9ca3af' }}>
                          <Mail size={12} /> {stu.studentEmail}
                        </div>
                      </td>
                      <td style={s.td}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, padding: '3px 8px', borderRadius: 4, fontSize: 11, fontWeight: 600, background: 'rgba(16,185,129,0.1)', color: '#34d399', border: '1px solid rgba(16,185,129,0.2)' }}>
                          Đã đăng ký
                        </span>
                      </td>
                      {isLecturer && (
                        <td style={s.td}>
                          {stu.gradeStatus === 'admin_published' ? (
                            <span style={{ fontWeight: 700, color: stu.letterGrade === 'F' ? '#ef4444' : '#10b981' }}>
                              {stu.total10} ({stu.letterGrade})
                            </span>
                          ) : (
                            <span style={{ fontSize: 11, color: '#6b7280' }}>Chưa có</span>
                          )}
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
