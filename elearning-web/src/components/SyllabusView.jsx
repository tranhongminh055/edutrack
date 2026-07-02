import React, { useState, useEffect } from 'react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import {
  BookOpen, ChevronRight, HelpCircle, Save, Edit3, Plus, Trash2,
  Target, Calendar, Award, Library, FileText, Loader2, CheckCircle,
  GraduationCap, Clock, Percent
} from 'lucide-react';

const EMPTY_SYLLABUS = {
  description: '',
  objectives: [''],
  weeklySchedule: [{ week: 1, topic: '', details: '' }],
  grading: [{ component: '', weight: '' }],
  textbooks: [{ title: '', author: '', type: 'required' }],
  policies: '',
};

export default function SyllabusView({ course, role, email }) {
  const [syllabus, setSyllabus] = useState(null);
  const [editing, setEditing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [form, setForm] = useState(EMPTY_SYLLABUS);

  const docId = course?.docId;
  const courseTitle = `${course?.courseId || ''} ${course?.courseName} (${course?.classGroup})`;
  const isLecturer = role === 'lecturer';

  useEffect(() => {
    if (!docId) return;
    setLoading(true);
    getDoc(doc(db, 'elearning_syllabi', docId)).then(snap => {
      if (snap.exists()) {
        const data = snap.data();
        setSyllabus(data);
        setForm({
          description: data.description || '',
          objectives: data.objectives?.length ? data.objectives : [''],
          weeklySchedule: data.weeklySchedule?.length ? data.weeklySchedule : [{ week: 1, topic: '', details: '' }],
          grading: data.grading?.length ? data.grading : [{ component: '', weight: '' }],
          textbooks: data.textbooks?.length ? data.textbooks : [{ title: '', author: '', type: 'required' }],
          policies: data.policies || '',
        });
      } else {
        setSyllabus(null);
        setForm(EMPTY_SYLLABUS);
      }
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [docId]);

  const showToast = (msg, type = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await setDoc(doc(db, 'elearning_syllabi', docId), {
        ...form,
        courseDocId: docId,
        courseId: course.courseId,
        courseName: course.courseName,
        classGroup: course.classGroup,
        updatedAt: serverTimestamp(),
        updatedBy: email,
      });
      setSyllabus(form);
      setEditing(false);
      showToast('Đã lưu syllabus thành công!');
    } catch (e) {
      console.error(e);
      showToast('Lỗi khi lưu!', 'error');
    }
    setSaving(false);
  };

  // Form helpers
  const updateField = (field, value) => setForm(f => ({ ...f, [field]: value }));

  const updateListItem = (field, idx, value) => {
    setForm(f => {
      const arr = [...f[field]];
      arr[idx] = typeof arr[idx] === 'string' ? value : { ...arr[idx], ...value };
      return { ...f, [field]: arr };
    });
  };

  const addListItem = (field, item) => setForm(f => ({ ...f, [field]: [...f[field], item] }));

  const removeListItem = (field, idx) => {
    setForm(f => {
      const arr = f[field].filter((_, i) => i !== idx);
      return { ...f, [field]: arr.length ? arr : (typeof f[field][0] === 'string' ? [''] : [f[field][0]]) };
    });
  };

  // Styles
  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff' },
    bannerTitle: { display: 'flex', alignItems: 'center', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 960, margin: '0 auto' },
    section: { border: '1px solid #2a2d38', borderRadius: 6, overflow: 'hidden', backgroundColor: '#1e2129', marginBottom: 20 },
    sectionHeader: { backgroundColor: '#2a2d38', padding: '12px 16px', fontSize: 14, fontWeight: 700, borderBottom: '1px solid #33363f', display: 'flex', alignItems: 'center', gap: 8, color: '#e0e0e0' },
    sectionBody: { padding: '16px 20px' },
    textarea: { width: '100%', minHeight: 80, padding: '10px 12px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, resize: 'vertical', fontFamily: 'inherit', outline: 'none' },
    input: { width: '100%', padding: '8px 12px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, fontFamily: 'inherit', outline: 'none' },
    inputSm: { width: 70, padding: '8px 10px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, textAlign: 'center', outline: 'none' },
    row: { display: 'flex', gap: 10, alignItems: 'flex-start', marginBottom: 10 },
    addBtn: { display: 'inline-flex', alignItems: 'center', gap: 4, padding: '6px 14px', background: 'rgba(59,130,246,0.15)', border: '1px solid rgba(59,130,246,0.3)', borderRadius: 6, color: '#60a5fa', fontSize: 12, fontWeight: 600, cursor: 'pointer', marginTop: 6 },
    delBtn: { background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer', padding: 4, flexShrink: 0, marginTop: 4 },
    tag: { display: 'inline-flex', alignItems: 'center', gap: 4, padding: '3px 10px', borderRadius: 4, fontSize: 11, fontWeight: 600 },
    primaryBtn: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 20px', background: '#2563eb', color: 'white', border: 'none', borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
    outlineBtn: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 20px', background: 'transparent', color: '#9ca3af', border: '1px solid #3f4350', borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
    text: { fontSize: 13, color: '#c8ccd0', lineHeight: 1.7, whiteSpace: 'pre-wrap' },
    label: { fontSize: 12, color: '#6b7280', marginBottom: 4, display: 'block' },
    weekBadge: { minWidth: 44, height: 44, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 700, flexShrink: 0 },
    empty: { textAlign: 'center', padding: '50px 20px', color: '#6b7280' },
  };

  if (loading) {
    return (
      <div style={s.page}>
        <div style={{ ...s.empty, minHeight: 300, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <Loader2 size={32} style={{ color: '#3b82f6', animation: 'spin 1s linear infinite', marginBottom: 12 }} />
          <span>Đang tải syllabus...</span>
        </div>
      </div>
    );
  }

  // No syllabus yet
  if (!syllabus && !editing) {
    return (
      <div style={s.page}>
        <div style={s.banner}>
          <div style={s.bannerTitle}>{courseTitle} <ChevronRight size={16} style={{ margin: '0 8px' }} /> Syllabus</div>
          <HelpCircle size={18} />
        </div>
        <div style={s.empty}>
          <BookOpen size={48} style={{ opacity: 0.2, marginBottom: 16 }} />
          <p style={{ fontSize: 16, fontWeight: 600, color: '#9ca3af', marginBottom: 8 }}>Chưa có Syllabus</p>
          <p style={{ fontSize: 13, color: '#6b7280', marginBottom: 20 }}>
            {isLecturer ? 'Hãy tạo syllabus cho môn học này.' : 'Giảng viên chưa tạo syllabus cho môn này.'}
          </p>
          {isLecturer && (
            <button style={s.primaryBtn} onClick={() => { setForm(EMPTY_SYLLABUS); setEditing(true); }}>
              <Plus size={14} /> Tạo Syllabus
            </button>
          )}
        </div>
      </div>
    );
  }

  // Edit mode
  if (editing && isLecturer) {
    return (
      <div style={s.page}>
        <div style={s.banner}>
          <div style={s.bannerTitle}>{courseTitle} <ChevronRight size={16} style={{ margin: '0 8px' }} /> Chỉnh sửa Syllabus</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={s.outlineBtn} onClick={() => { setEditing(false); if (syllabus) setForm(syllabus); }}>Hủy</button>
            <button style={{ ...s.primaryBtn, opacity: saving ? 0.6 : 1 }} onClick={handleSave} disabled={saving}>
              {saving ? <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> : <Save size={14} />}
              {saving ? 'Đang lưu...' : 'Lưu Syllabus'}
            </button>
          </div>
        </div>
        <div style={s.container}>
          {/* Description */}
          <div style={s.section}>
            <div style={s.sectionHeader}><FileText size={15} /> Mô tả môn học</div>
            <div style={s.sectionBody}>
              <textarea style={s.textarea} value={form.description} onChange={e => updateField('description', e.target.value)} placeholder="Nhập mô tả môn học..." />
            </div>
          </div>

          {/* Objectives */}
          <div style={s.section}>
            <div style={s.sectionHeader}><Target size={15} /> Mục tiêu môn học</div>
            <div style={s.sectionBody}>
              {form.objectives.map((obj, i) => (
                <div key={i} style={s.row}>
                  <span style={{ color: '#3b82f6', fontWeight: 700, fontSize: 13, marginTop: 8, minWidth: 24 }}>{i + 1}.</span>
                  <input style={{ ...s.input, flex: 1 }} value={obj} onChange={e => updateListItem('objectives', i, e.target.value)} placeholder="Mục tiêu..." />
                  <button style={s.delBtn} onClick={() => removeListItem('objectives', i)}><Trash2 size={14} /></button>
                </div>
              ))}
              <button style={s.addBtn} onClick={() => addListItem('objectives', '')}><Plus size={12} /> Thêm mục tiêu</button>
            </div>
          </div>

          {/* Weekly Schedule */}
          <div style={s.section}>
            <div style={s.sectionHeader}><Calendar size={15} /> Lịch trình giảng dạy</div>
            <div style={s.sectionBody}>
              {form.weeklySchedule.map((w, i) => (
                <div key={i} style={{ ...s.row, padding: '10px 0', borderBottom: i < form.weeklySchedule.length - 1 ? '1px solid #2a2d38' : 'none' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                    <span style={s.label}>Tuần</span>
                    <input style={s.inputSm} type="number" min={1} value={w.week} onChange={e => updateListItem('weeklySchedule', i, { week: parseInt(e.target.value) || 1 })} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <span style={s.label}>Chủ đề</span>
                    <input style={{ ...s.input, marginBottom: 6 }} value={w.topic} onChange={e => updateListItem('weeklySchedule', i, { topic: e.target.value })} placeholder="Chủ đề tuần..." />
                    <span style={s.label}>Chi tiết</span>
                    <input style={s.input} value={w.details} onChange={e => updateListItem('weeklySchedule', i, { details: e.target.value })} placeholder="Nội dung chi tiết..." />
                  </div>
                  <button style={s.delBtn} onClick={() => removeListItem('weeklySchedule', i)}><Trash2 size={14} /></button>
                </div>
              ))}
              <button style={s.addBtn} onClick={() => addListItem('weeklySchedule', { week: form.weeklySchedule.length + 1, topic: '', details: '' })}>
                <Plus size={12} /> Thêm tuần
              </button>
            </div>
          </div>

          {/* Grading */}
          <div style={s.section}>
            <div style={s.sectionHeader}><Award size={15} /> Chính sách chấm điểm</div>
            <div style={s.sectionBody}>
              {form.grading.map((g, i) => (
                <div key={i} style={s.row}>
                  <input style={{ ...s.input, flex: 1 }} value={g.component} onChange={e => updateListItem('grading', i, { component: e.target.value })} placeholder="Thành phần (VD: Giữa kỳ)..." />
                  <input style={{ ...s.inputSm, width: 90 }} value={g.weight} onChange={e => updateListItem('grading', i, { weight: e.target.value })} placeholder="%" />
                  <button style={s.delBtn} onClick={() => removeListItem('grading', i)}><Trash2 size={14} /></button>
                </div>
              ))}
              <button style={s.addBtn} onClick={() => addListItem('grading', { component: '', weight: '' })}>
                <Plus size={12} /> Thêm thành phần
              </button>
            </div>
          </div>

          {/* Textbooks */}
          <div style={s.section}>
            <div style={s.sectionHeader}><Library size={15} /> Tài liệu tham khảo</div>
            <div style={s.sectionBody}>
              {form.textbooks.map((t, i) => (
                <div key={i} style={{ ...s.row, alignItems: 'center' }}>
                  <select style={{ ...s.inputSm, width: 100, cursor: 'pointer' }} value={t.type} onChange={e => updateListItem('textbooks', i, { type: e.target.value })}>
                    <option value="required">Bắt buộc</option>
                    <option value="reference">Tham khảo</option>
                  </select>
                  <input style={{ ...s.input, flex: 1 }} value={t.title} onChange={e => updateListItem('textbooks', i, { title: e.target.value })} placeholder="Tên sách/tài liệu..." />
                  <input style={{ ...s.input, flex: 0.6 }} value={t.author} onChange={e => updateListItem('textbooks', i, { author: e.target.value })} placeholder="Tác giả..." />
                  <button style={s.delBtn} onClick={() => removeListItem('textbooks', i)}><Trash2 size={14} /></button>
                </div>
              ))}
              <button style={s.addBtn} onClick={() => addListItem('textbooks', { title: '', author: '', type: 'reference' })}>
                <Plus size={12} /> Thêm tài liệu
              </button>
            </div>
          </div>

          {/* Policies */}
          <div style={s.section}>
            <div style={s.sectionHeader}><FileText size={15} /> Quy định lớp học</div>
            <div style={s.sectionBody}>
              <textarea style={{ ...s.textarea, minHeight: 100 }} value={form.policies} onChange={e => updateField('policies', e.target.value)} placeholder="Quy định về điểm danh, nộp bài, gian lận..." />
            </div>
          </div>
        </div>
        {toast && <div className={`toast-notification ${toast.type}`}>{toast.type === 'success' ? <CheckCircle size={16} /> : null}{toast.msg}</div>}
      </div>
    );
  }

  // Read-only view
  const data = syllabus || form;
  return (
    <div style={s.page}>
      <div style={s.banner}>
        <div style={s.bannerTitle}>{courseTitle} <ChevronRight size={16} style={{ margin: '0 8px' }} /> Syllabus</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {isLecturer && (
            <button style={{ ...s.outlineBtn, color: '#fff', borderColor: 'rgba(255,255,255,0.3)' }} onClick={() => setEditing(true)}>
              <Edit3 size={14} /> Chỉnh sửa
            </button>
          )}
          <HelpCircle size={18} />
        </div>
      </div>
      <div style={s.container}>
        {/* Description */}
        {data.description && (
          <div style={s.section}>
            <div style={s.sectionHeader}><FileText size={15} /> Mô tả môn học</div>
            <div style={s.sectionBody}>
              <p style={s.text}>{data.description}</p>
            </div>
          </div>
        )}

        {/* Objectives */}
        {data.objectives?.filter(o => o).length > 0 && (
          <div style={s.section}>
            <div style={s.sectionHeader}><Target size={15} /> Mục tiêu môn học</div>
            <div style={s.sectionBody}>
              {data.objectives.filter(o => o).map((obj, i) => (
                <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', marginBottom: 8 }}>
                  <CheckCircle size={14} style={{ color: '#10b981', marginTop: 3, flexShrink: 0 }} />
                  <span style={s.text}>{obj}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Weekly Schedule */}
        {data.weeklySchedule?.filter(w => w.topic).length > 0 && (
          <div style={s.section}>
            <div style={s.sectionHeader}><Calendar size={15} /> Lịch trình giảng dạy</div>
            <div style={s.sectionBody}>
              {data.weeklySchedule.filter(w => w.topic).map((w, i) => (
                <div key={i} style={{ display: 'flex', gap: 14, alignItems: 'flex-start', padding: '12px 0', borderBottom: i < data.weeklySchedule.filter(x => x.topic).length - 1 ? '1px solid #2a2d38' : 'none' }}>
                  <div style={{ ...s.weekBadge, background: 'rgba(59,130,246,0.15)', border: '1px solid rgba(59,130,246,0.3)', color: '#60a5fa' }}>
                    W{w.week}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, color: '#e0e0e0', marginBottom: 4 }}>{w.topic}</div>
                    {w.details && <div style={{ fontSize: 12, color: '#9ca3af', lineHeight: 1.6 }}>{w.details}</div>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Grading */}
        {data.grading?.filter(g => g.component).length > 0 && (
          <div style={s.section}>
            <div style={s.sectionHeader}><Award size={15} /> Chính sách chấm điểm</div>
            <div style={s.sectionBody}>
              {data.grading.filter(g => g.component).map((g, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 0', borderBottom: i < data.grading.filter(x => x.component).length - 1 ? '1px solid #2a2d38' : 'none' }}>
                  <span style={{ fontSize: 13, color: '#c8ccd0' }}>{g.component}</span>
                  <span style={{ ...s.tag, background: 'rgba(245,158,11,0.15)', border: '1px solid rgba(245,158,11,0.3)', color: '#fbbf24' }}>
                    <Percent size={11} /> {g.weight}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Textbooks */}
        {data.textbooks?.filter(t => t.title).length > 0 && (
          <div style={s.section}>
            <div style={s.sectionHeader}><Library size={15} /> Tài liệu tham khảo</div>
            <div style={s.sectionBody}>
              {data.textbooks.filter(t => t.title).map((t, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 0', borderBottom: i < data.textbooks.filter(x => x.title).length - 1 ? '1px solid #2a2d38' : 'none' }}>
                  <BookOpen size={14} style={{ color: '#8b5cf6', flexShrink: 0 }} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: '#e0e0e0' }}>{t.title}</div>
                    {t.author && <div style={{ fontSize: 12, color: '#6b7280' }}>{t.author}</div>}
                  </div>
                  <span style={{ ...s.tag, background: t.type === 'required' ? 'rgba(239,68,68,0.15)' : 'rgba(107,114,128,0.2)', border: `1px solid ${t.type === 'required' ? 'rgba(239,68,68,0.3)' : 'rgba(107,114,128,0.3)'}`, color: t.type === 'required' ? '#f87171' : '#9ca3af' }}>
                    {t.type === 'required' ? 'Bắt buộc' : 'Tham khảo'}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Policies */}
        {data.policies && (
          <div style={s.section}>
            <div style={s.sectionHeader}><FileText size={15} /> Quy định lớp học</div>
            <div style={s.sectionBody}>
              <p style={s.text}>{data.policies}</p>
            </div>
          </div>
        )}
      </div>
      {toast && <div className={`toast-notification ${toast.type}`}>{toast.type === 'success' ? <CheckCircle size={16} /> : null}{toast.msg}</div>}
    </div>
  );
}
