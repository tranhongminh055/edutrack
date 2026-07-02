import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import { ChevronRight, Plus, Trash2, Bell, Loader2, X, Save, CheckCircle, User, Calendar } from 'lucide-react';

export default function CourseAnnouncementsView({ course, role, email }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({ title: '', content: '' });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [expandedId, setExpandedId] = useState(null);
  const isLecturer = role === 'lecturer';

  useEffect(() => {
    const q = query(collection(db, 'elearning_course_announcements'), where('courseDocId', '==', course.docId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, snap => {
      setItems(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    }, () => setLoading(false));
    return unsub;
  }, [course.docId]);

  const handleAdd = async () => {
    if (!form.title) return;
    setSaving(true);
    try {
      await addDoc(collection(db, 'elearning_course_announcements'), { ...form, courseDocId: course.docId, createdBy: email, authorName: course.lecturerName || email, createdAt: serverTimestamp() });
      setShowAdd(false); setForm({ title: '', content: '' });
      setToast('Đã đăng thông báo!'); setTimeout(() => setToast(null), 2500);
    } catch(e) { console.error(e); }
    setSaving(false);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Xóa thông báo này?')) return;
    await deleteDoc(doc(db, 'elearning_course_announcements', id));
  };

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 900, margin: '0 auto' },
    card: { border: '1px solid #2a2d38', borderRadius: 6, overflow: 'hidden', backgroundColor: '#1e2129', marginBottom: 12 },
    btn: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '7px 16px', background: '#2563eb', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' },
    input: { width: '100%', padding: '8px 12px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, outline: 'none', fontFamily: 'inherit' },
    overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    modal: { background: '#1e2129', border: '1px solid #2a2d38', borderRadius: 10, padding: 24, width: 500, maxHeight: '80vh', overflowY: 'auto' },
  };

  return (
    <div style={s.page}>
      <div style={s.banner}>
        <span>{course.courseId} {course.courseName} ({course.classGroup}) <ChevronRight size={16} style={{ margin: '0 8px', verticalAlign: 'middle' }} /> Announcements</span>
        {isLecturer && <button style={{ ...s.btn, background: 'rgba(255,255,255,0.15)' }} onClick={() => setShowAdd(true)}><Plus size={14} /> Đăng thông báo</button>}
      </div>
      <div style={s.container}>
        {loading ? (
          <div style={{ textAlign: 'center', padding: 60 }}><Loader2 size={32} style={{ color: '#3b82f6', animation: 'spin 1s linear infinite' }} /></div>
        ) : items.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 60, color: '#6b7280' }}>
            <Bell size={48} style={{ opacity: 0.2, marginBottom: 12 }} />
            <p style={{ fontSize: 15, fontWeight: 600, color: '#9ca3af' }}>Chưa có thông báo</p>
          </div>
        ) : items.map(item => {
          const date = item.createdAt?.toDate?.();
          const expanded = expandedId === item.id;
          return (
            <div key={item.id} style={s.card}>
              <div style={{ padding: '14px 16px', cursor: 'pointer', display: 'flex', alignItems: 'flex-start', gap: 12 }} onClick={() => setExpandedId(expanded ? null : item.id)}>
                <div style={{ width: 36, height: 36, borderRadius: 8, background: 'rgba(245,158,11,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#f59e0b', flexShrink: 0 }}>
                  <Bell size={16} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: '#e0e0e0' }}>{item.title}</div>
                  <div style={{ display: 'flex', gap: 12, marginTop: 4, flexWrap: 'wrap' }}>
                    <span style={{ fontSize: 11, color: '#6b7280', display: 'inline-flex', alignItems: 'center', gap: 3 }}><User size={10} />{item.authorName || item.createdBy}</span>
                    {date && <span style={{ fontSize: 11, color: '#6b7280', display: 'inline-flex', alignItems: 'center', gap: 3 }}><Calendar size={10} />{date.toLocaleDateString('vi-VN')} {date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</span>}
                  </div>
                  {!expanded && item.content && <p style={{ fontSize: 12, color: '#9ca3af', marginTop: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.content}</p>}
                  {expanded && item.content && <p style={{ fontSize: 13, color: '#c8ccd0', marginTop: 10, lineHeight: 1.7, whiteSpace: 'pre-wrap' }}>{item.content}</p>}
                </div>
                {isLecturer && <button onClick={e => { e.stopPropagation(); handleDelete(item.id); }} style={{ background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer', padding: 4 }}><Trash2 size={14} /></button>}
              </div>
            </div>
          );
        })}
      </div>

      {showAdd && (
        <div style={s.overlay} onClick={() => setShowAdd(false)}>
          <div style={s.modal} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
              <h3 style={{ fontSize: 16, fontWeight: 700 }}>Đăng thông báo mới</h3>
              <button onClick={() => setShowAdd(false)} style={{ background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer' }}><X size={18} /></button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Tiêu đề *</label><input style={s.input} value={form.title} onChange={e => setForm(f => ({...f, title: e.target.value}))} /></div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Nội dung</label><textarea style={{...s.input, minHeight: 120, resize: 'vertical'}} value={form.content} onChange={e => setForm(f => ({...f, content: e.target.value}))} /></div>
              <button style={{...s.btn, justifyContent:'center', padding:10, opacity: saving?0.6:1}} onClick={handleAdd} disabled={saving}>
                {saving ? <Loader2 size={14} style={{animation:'spin 1s linear infinite'}} /> : <Save size={14} />} Đăng
              </button>
            </div>
          </div>
        </div>
      )}
      {toast && <div className="toast-notification success"><CheckCircle size={16} />{toast}</div>}
    </div>
  );
}
