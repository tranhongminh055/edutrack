import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { ChevronRight, Plus, Trash2, Edit3, Loader2, BookOpen, FileText, Video, Link as LinkIcon, GripVertical, X, Save, CheckCircle, Eye } from 'lucide-react';

export default function LessonsView({ course, role, email }) {
  const [lessons, setLessons] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [editId, setEditId] = useState(null);
  const [expandedId, setExpandedId] = useState(null);
  const [form, setForm] = useState({ title: '', content: '', type: 'text', linkUrl: '', order: 1 });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const isLecturer = role === 'lecturer';

  useEffect(() => {
    const q = query(collection(db, 'elearning_lessons'), where('courseDocId', '==', course.docId));
    const unsub = onSnapshot(q, snap => {
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      data.sort((a, b) => (a.order || 0) - (b.order || 0));
      setLessons(data);
      setLoading(false);
    }, () => setLoading(false));
    return unsub;
  }, [course.docId]);

  const handleSave = async () => {
    if (!form.title) return;
    setSaving(true);
    try {
      if (editId) {
        await updateDoc(doc(db, 'elearning_lessons', editId), { ...form, updatedAt: serverTimestamp() });
      } else {
        await addDoc(collection(db, 'elearning_lessons'), { ...form, courseDocId: course.docId, createdBy: email, createdAt: serverTimestamp() });
      }
      setShowAdd(false); setEditId(null);
      setForm({ title: '', content: '', type: 'text', linkUrl: '', order: lessons.length + 1 });
      setToast(editId ? 'Đã cập nhật!' : 'Đã thêm bài học!');
      setTimeout(() => setToast(null), 2500);
    } catch(e) { console.error(e); }
    setSaving(false);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Xóa bài học này?')) return;
    await deleteDoc(doc(db, 'elearning_lessons', id));
  };

  const startEdit = (lesson) => {
    setForm({ title: lesson.title, content: lesson.content || '', type: lesson.type || 'text', linkUrl: lesson.linkUrl || '', order: lesson.order || 1 });
    setEditId(lesson.id);
    setShowAdd(true);
  };

  const typeIcons = { text: <FileText size={18} />, video: <Video size={18} />, link: <LinkIcon size={18} />, reading: <BookOpen size={18} /> };
  const typeColors = { text: '#3b82f6', video: '#8b5cf6', link: '#10b981', reading: '#f59e0b' };
  const typeLabels = { text: 'Bài giảng', video: 'Video', link: 'Liên kết', reading: 'Đọc thêm' };

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 900, margin: '0 auto' },
    card: { border: '1px solid #2a2d38', borderRadius: 6, overflow: 'hidden', backgroundColor: '#1e2129', marginBottom: 10, transition: 'border-color 0.2s' },
    cardHeader: { backgroundColor: '#2a2d38', padding: '12px 16px', fontSize: 14, fontWeight: 700, borderBottom: '1px solid #33363f', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#e0e0e0' },
    btn: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '7px 16px', background: '#2563eb', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' },
    input: { width: '100%', padding: '8px 12px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, outline: 'none', fontFamily: 'inherit' },
    overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    modal: { background: '#1e2129', border: '1px solid #2a2d38', borderRadius: 10, padding: 24, width: 500, maxHeight: '80vh', overflowY: 'auto' },
    iconBtn: { background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer', padding: 4 },
  };

  return (
    <div style={s.page}>
      <div style={s.banner}>
        <span>{course.courseId} {course.courseName} ({course.classGroup}) <ChevronRight size={16} style={{ margin: '0 8px', verticalAlign: 'middle' }} /> Lessons</span>
        {isLecturer && <button style={{ ...s.btn, background: 'rgba(255,255,255,0.15)' }} onClick={() => { setEditId(null); setForm({ title: '', content: '', type: 'text', linkUrl: '', order: lessons.length + 1 }); setShowAdd(true); }}><Plus size={14} /> Thêm bài học</button>}
      </div>
      <div style={s.container}>
        {loading ? (
          <div style={{ textAlign: 'center', padding: 60 }}><Loader2 size={32} style={{ color: '#3b82f6', animation: 'spin 1s linear infinite' }} /></div>
        ) : lessons.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 60, color: '#6b7280' }}>
            <BookOpen size={48} style={{ opacity: 0.2, marginBottom: 12 }} />
            <p style={{ fontSize: 15, fontWeight: 600, color: '#9ca3af' }}>Chưa có bài học nào</p>
            <p style={{ fontSize: 13, marginTop: 4 }}>{isLecturer ? 'Bấm "Thêm bài học" để bắt đầu.' : 'Giảng viên chưa thêm bài học.'}</p>
          </div>
        ) : (
          lessons.map((lesson, i) => {
            const color = typeColors[lesson.type] || '#3b82f6';
            const expanded = expandedId === lesson.id;
            return (
              <div key={lesson.id} style={{ ...s.card, borderLeftColor: color, borderLeft: `3px solid ${color}` }}>
                <div
                  style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', cursor: 'pointer', gap: 12 }}
                  onClick={() => setExpandedId(expanded ? null : lesson.id)}
                >
                  <div style={{ width: 36, height: 36, borderRadius: 8, background: color + '20', display: 'flex', alignItems: 'center', justifyContent: 'center', color, flexShrink: 0 }}>
                    {typeIcons[lesson.type] || typeIcons.text}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, color: '#e0e0e0' }}>Bài {lesson.order || i + 1}: {lesson.title}</div>
                    <span style={{ fontSize: 11, color, background: color + '15', padding: '1px 8px', borderRadius: 3, marginTop: 2, display: 'inline-block' }}>{typeLabels[lesson.type] || 'Bài giảng'}</span>
                  </div>
                  {isLecturer && (
                    <div style={{ display: 'flex', gap: 4 }} onClick={e => e.stopPropagation()}>
                      <button style={s.iconBtn} onClick={() => startEdit(lesson)}><Edit3 size={14} /></button>
                      <button style={s.iconBtn} onClick={() => handleDelete(lesson.id)}><Trash2 size={14} /></button>
                    </div>
                  )}
                  <ChevronRight size={16} style={{ color: '#6b7280', transform: expanded ? 'rotate(90deg)' : 'none', transition: 'transform 0.2s' }} />
                </div>
                {expanded && (
                  <div style={{ padding: '0 16px 16px 64px', fontSize: 13, color: '#c8ccd0', lineHeight: 1.7, whiteSpace: 'pre-wrap' }}>
                    {lesson.content || 'Không có nội dung.'}
                    {lesson.linkUrl && (
                      <div style={{ marginTop: 10 }}>
                        <a href={lesson.linkUrl} target="_blank" rel="noreferrer" style={{ color: '#60a5fa', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12 }}>
                          <LinkIcon size={12} /> {lesson.linkUrl}
                        </a>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>

      {showAdd && (
        <div style={s.overlay} onClick={() => { setShowAdd(false); setEditId(null); }}>
          <div style={s.modal} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
              <h3 style={{ fontSize: 16, fontWeight: 700, color: '#e0e0e0' }}>{editId ? 'Chỉnh sửa bài học' : 'Thêm bài học'}</h3>
              <button onClick={() => { setShowAdd(false); setEditId(null); }} style={s.iconBtn}><X size={18} /></button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{ display: 'flex', gap: 10 }}>
                <div style={{ width: 70 }}><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Thứ tự</label><input type="number" min={1} style={s.input} value={form.order} onChange={e => setForm(f => ({...f, order: parseInt(e.target.value)||1}))} /></div>
                <div style={{ flex: 1 }}><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Tiêu đề *</label><input style={s.input} value={form.title} onChange={e => setForm(f => ({...f, title: e.target.value}))} /></div>
              </div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Loại</label>
                <select style={{...s.input, cursor:'pointer'}} value={form.type} onChange={e => setForm(f => ({...f, type: e.target.value}))}>
                  {Object.entries(typeLabels).map(([k,v]) => <option key={k} value={k}>{v}</option>)}
                </select>
              </div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Nội dung</label><textarea style={{...s.input, minHeight: 120, resize: 'vertical'}} value={form.content} onChange={e => setForm(f => ({...f, content: e.target.value}))} /></div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Link (nếu có)</label><input style={s.input} value={form.linkUrl} onChange={e => setForm(f => ({...f, linkUrl: e.target.value}))} placeholder="https://..." /></div>
              <button style={{...s.btn, justifyContent: 'center', padding: 10, opacity: saving ? 0.6 : 1}} onClick={handleSave} disabled={saving}>
                {saving ? <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> : <Save size={14} />} {editId ? 'Cập nhật' : 'Thêm'}
              </button>
            </div>
          </div>
        </div>
      )}
      {toast && <div className="toast-notification success"><CheckCircle size={16} />{toast}</div>}
    </div>
  );
}
