import React, { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, where } from 'firebase/firestore';
import { db } from '../firebase';
import { Bell, Plus, Send, Loader2, Clock, User, MessageSquare } from 'lucide-react';

export default function AnnouncementsView({ courses, role, email }) {
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [targetCourse, setTargetCourse] = useState('all');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const q = query(collection(db, 'elearning_announcements'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      // Filter: students see all, lecturers see their own
      const filtered = role === 'lecturer'
        ? data.filter(a => a.authorEmail === email)
        : data;
      setAnnouncements(filtered);
      setLoading(false);
    }, () => setLoading(false));
    return () => unsub();
  }, [role, email]);

  const handlePost = async () => {
    if (!title.trim() || !content.trim()) return;
    setSaving(true);
    try {
      await addDoc(collection(db, 'elearning_announcements'), {
        title: title.trim(),
        content: content.trim(),
        authorEmail: email,
        authorRole: role,
        courseDocId: targetCourse === 'all' ? null : targetCourse,
        courseName: targetCourse === 'all' ? 'Tất cả' : courses.find(c => c.docId === targetCourse)?.courseName || '',
        createdAt: serverTimestamp(),
      });
      setTitle('');
      setContent('');
      setShowForm(false);
    } catch (err) {
      console.error('Error posting:', err);
      alert('Lỗi khi đăng thông báo!');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="sakai-home">
      <div className="sakai-page-header">
        <h2>📢 Announcements</h2>
        <p>Thông báo từ hệ thống E-Learning</p>
      </div>

      {/* Lecturer: Create announcement */}
      {role === 'lecturer' && (
        <div style={{marginBottom: 20}}>
          {!showForm ? (
            <button className="sakai-btn-primary" onClick={() => setShowForm(true)}>
              <Plus size={16} /> Đăng thông báo mới
            </button>
          ) : (
            <div className="sakai-card">
              <div className="sakai-card-title-bar">Tạo thông báo mới</div>
              <div className="sakai-card-body">
                <div className="form-group">
                  <label>Tiêu đề *</label>
                  <input
                    type="text"
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    placeholder="Nhập tiêu đề thông báo..."
                    className="sakai-input"
                  />
                </div>
                <div className="form-group">
                  <label>Môn học</label>
                  <select value={targetCourse} onChange={e => setTargetCourse(e.target.value)} className="sakai-input">
                    <option value="all">Tất cả các lớp</option>
                    {courses.map(c => (
                      <option key={c.docId} value={c.docId}>{c.courseName} ({c.classGroup})</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Nội dung *</label>
                  <textarea
                    value={content}
                    onChange={e => setContent(e.target.value)}
                    placeholder="Nhập nội dung thông báo..."
                    rows={4}
                    className="sakai-input"
                  />
                </div>
                <div className="form-actions">
                  <button className="sakai-btn-primary" onClick={handlePost} disabled={saving || !title.trim() || !content.trim()}>
                    {saving ? <Loader2 size={14} className="spin" /> : <Send size={14} />}
                    {saving ? 'Đang gửi...' : 'Đăng thông báo'}
                  </button>
                  <button className="sakai-btn-outline" onClick={() => setShowForm(false)}>Hủy</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Announcements list */}
      {loading ? (
        <div className="loading-spinner"><Loader2 style={{width: 32, height: 32, color: '#3b82f6'}} /><span>Đang tải...</span></div>
      ) : announcements.length === 0 ? (
        <div className="sakai-card">
          <div className="sakai-card-body">
            <div className="empty-state">
              <Bell />
              <p>Chưa có thông báo nào.</p>
            </div>
          </div>
        </div>
      ) : (
        <div className="sakai-card slide-up-anim" style={{ animationDelay: '50ms' }}>
          <div className="sakai-card-title-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>Thông báo (xem các thông báo gần đây)</span>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', fontSize: 13, fontWeight: 'normal', color: '#9ca3af' }}>
              <span>Xem</span>
              <select className="sakai-input" style={{ width: 100, padding: '4px 8px' }}>
                <option>Tất cả</option>
              </select>
            </div>
          </div>
          <div className="sakai-card-body" style={{ padding: 0 }}>
            {/* Toolbar */}
            <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: '1px solid #3f4350' }}>
              <span style={{ fontSize: 13, color: '#9ca3af' }}>Đang hiển thị 1 - {announcements.length} trong tổng số {announcements.length} mục</span>
              <div style={{ display: 'flex' }}>
                <button className="sakai-btn-outline" style={{ padding: '4px 8px', borderRadius: '4px 0 0 4px' }}>|&lt;</button>
                <button className="sakai-btn-outline" style={{ padding: '4px 8px', borderRadius: 0, borderLeft: 0 }}>&lt;</button>
                <select className="sakai-input" style={{ padding: '4px 8px', borderRadius: 0, borderLeft: 0, width: 130 }}>
                  <option>Hiển thị 10 mục...</option>
                </select>
                <button className="sakai-btn-outline" style={{ padding: '4px 8px', borderRadius: 0, borderLeft: 0 }}>&gt;</button>
                <button className="sakai-btn-outline" style={{ padding: '4px 8px', borderRadius: '0 4px 4px 0', borderLeft: 0 }}>&gt;|</button>
              </div>
            </div>
            {/* Table */}
            <table className="sakai-table">
              <thead>
                <tr>
                  <th>Chủ đề</th>
                  <th>Được lưu bởi</th>
                  <th>Ngày sửa đổi</th>
                  <th>Địa điểm</th>
                  <th>Ngày bắt đầu</th>
                  <th>Ngày kết thúc</th>
                </tr>
              </thead>
              <tbody>
                {announcements.map(a => (
                  <tr key={a.id}>
                    <td>
                      <div style={{ fontWeight: 600, color: '#60a5fa', display: 'flex', alignItems: 'center', gap: 6 }}>
                        <MessageSquare size={14} /> {a.title}
                      </div>
                    </td>
                    <td style={{ fontSize: 13, color: '#d1d5db' }}>{a.authorName || a.authorEmail?.split('@')[0].toUpperCase()}</td>
                    <td style={{ fontSize: 13, color: '#d1d5db' }}>
                      {a.createdAt?.toDate?.()?.toLocaleString('vi-VN', { dateStyle: 'long', timeStyle: 'short' }) || 'N/A'}
                    </td>
                    <td style={{ fontSize: 13, color: '#d1d5db' }}>
                      {a.courseName ? `${a.courseName} (${a.classGroup})` : 'Hệ thống'}
                    </td>
                    <td></td>
                    <td></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
