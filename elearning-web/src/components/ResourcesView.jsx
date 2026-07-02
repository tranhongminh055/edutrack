import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import { FolderOpen, FileText, Upload, Trash2, Link2, Plus, Loader2, ExternalLink, File } from 'lucide-react';

export default function ResourcesView({ courses, role, email }) {
  const [resources, setResources] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [resTitle, setResTitle] = useState('');
  const [resUrl, setResUrl] = useState('');
  const [resType, setResType] = useState('link');
  const [resCourse, setResCourse] = useState(courses[0]?.docId || '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (courses.length === 0) { setLoading(false); return; }
    const courseIds = courses.map(c => c.docId);

    // Listen to resources for all user's courses
    const q = query(collection(db, 'elearning_resources'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      const data = snap.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .filter(r => courseIds.includes(r.courseDocId));
      setResources(data);
      setLoading(false);
    }, () => setLoading(false));
    return () => unsub();
  }, [courses]);

  const handleAdd = async () => {
    if (!resTitle.trim() || !resCourse) return;
    setSaving(true);
    try {
      const selectedCourse = courses.find(c => c.docId === resCourse);
      const courseName = selectedCourse?.courseName || '';
      
      await addDoc(collection(db, 'elearning_resources'), {
        title: resTitle.trim(),
        url: resUrl.trim(),
        type: resType,
        courseDocId: resCourse,
        courseName: courseName,
        createdAt: serverTimestamp(),
      });

      // Auto-generate announcement
      const authorName = selectedCourse?.lecturerName || email.split('@')[0].toUpperCase();
      await addDoc(collection(db, 'elearning_announcements'), {
        title: resTitle.trim().toUpperCase(),
        content: `Tài liệu mới đã được đăng: ${resTitle.trim()}`,
        authorName: authorName,
        authorEmail: email,
        authorRole: role,
        courseDocId: resCourse,
        courseName: courseName,
        classGroup: selectedCourse?.classGroup || '',
        createdAt: serverTimestamp(),
      });
      setResTitle('');
      setResUrl('');
      setShowForm(false);
    } catch (err) {
      console.error(err);
      alert('Lỗi khi thêm tài liệu!');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Xóa tài liệu này?')) return;
    await deleteDoc(doc(db, 'elearning_resources', id));
  };

  const getTypeIcon = (type) => {
    switch (type) {
      case 'pdf': return <FileText size={18} style={{color: '#ef4444'}} />;
      case 'link': return <Link2 size={18} style={{color: '#3b82f6'}} />;
      case 'doc': return <File size={18} style={{color: '#2563eb'}} />;
      default: return <FolderOpen size={18} style={{color: '#6b7280'}} />;
    }
  };

  // Group by course
  const resourcesByCourse = {};
  resources.forEach(r => {
    const name = r.courseName || 'Khác';
    if (!resourcesByCourse[name]) resourcesByCourse[name] = [];
    resourcesByCourse[name].push(r);
  });

  return (
    <div className="sakai-home">
      <div className="sakai-page-header">
        <h2>📁 Resources</h2>
        <p>Tài liệu học tập và liên kết</p>
      </div>

      {/* Add resource (lecturer) */}
      {role === 'lecturer' && (
        <div style={{marginBottom: 20}}>
          {!showForm ? (
            <button className="sakai-btn-primary" onClick={() => setShowForm(true)}>
              <Plus size={16} /> Thêm tài liệu
            </button>
          ) : (
            <div className="sakai-card">
              <div className="sakai-card-title-bar">Thêm tài liệu mới</div>
              <div className="sakai-card-body">
                <div className="form-group">
                  <label>Môn học *</label>
                  <select value={resCourse} onChange={e => setResCourse(e.target.value)} className="sakai-input">
                    {courses.map(c => (
                      <option key={c.docId} value={c.docId}>{c.courseName} ({c.classGroup})</option>
                    ))}
                  </select>
                </div>
                <div className="form-row">
                  <div className="form-group" style={{flex: 1}}>
                    <label>Tên tài liệu *</label>
                    <input type="text" value={resTitle} onChange={e => setResTitle(e.target.value)} placeholder="VD: Slide bài giảng Chương 1" className="sakai-input" />
                  </div>
                  <div className="form-group" style={{width: 120}}>
                    <label>Loại</label>
                    <select value={resType} onChange={e => setResType(e.target.value)} className="sakai-input">
                      <option value="link">Link</option>
                      <option value="pdf">PDF</option>
                      <option value="doc">Document</option>
                      <option value="other">Khác</option>
                    </select>
                  </div>
                </div>
                <div className="form-group">
                  <label>URL / Đường dẫn</label>
                  <input type="text" value={resUrl} onChange={e => setResUrl(e.target.value)} placeholder="https://..." className="sakai-input" />
                </div>
                <div className="form-actions">
                  <button className="sakai-btn-primary" onClick={handleAdd} disabled={saving || !resTitle.trim()}>
                    {saving ? <Loader2 size={14} className="spin" /> : <Upload size={14} />}
                    {saving ? 'Đang lưu...' : 'Thêm tài liệu'}
                  </button>
                  <button className="sakai-btn-outline" onClick={() => setShowForm(false)}>Hủy</button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Resource list */}
      {loading ? (
        <div className="loading-spinner"><Loader2 style={{width: 32, height: 32, color: '#3b82f6'}} /><span>Đang tải...</span></div>
      ) : resources.length === 0 ? (
        <div className="sakai-card">
          <div className="sakai-card-body">
            <div className="empty-state">
              <FolderOpen />
              <p>{role === 'lecturer' ? 'Chưa có tài liệu nào. Bấm "Thêm tài liệu" để bắt đầu.' : 'Giảng viên chưa upload tài liệu.'}</p>
            </div>
          </div>
        </div>
      ) : (
        Object.entries(resourcesByCourse).map(([courseName, items]) => (
          <div key={courseName} className="sakai-card" style={{marginBottom: 16}}>
            <div className="sakai-card-title-bar">📂 {courseName}</div>
            <div className="sakai-card-body" style={{padding: 0}}>
              {items.map(r => (
                <div key={r.id} className="resource-row">
                  <div className="resource-row-icon">{getTypeIcon(r.type)}</div>
                  <div className="resource-row-info">
                    <h4>{r.title}</h4>
                    <p>{r.createdAt?.toDate?.()?.toLocaleDateString('vi-VN') || 'N/A'}</p>
                  </div>
                  <div className="resource-row-actions">
                    {r.url && (
                      <a href={r.url} target="_blank" rel="noopener noreferrer" className="sakai-btn-outline" style={{fontSize: 11}}>
                        <ExternalLink size={12} /> Mở
                      </a>
                    )}
                    {role === 'lecturer' && (
                      <button className="sakai-btn-danger-sm" onClick={() => handleDelete(r.id)}>
                        <Trash2 size={12} />
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  );
}
