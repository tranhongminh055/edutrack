import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { ChevronRight, ChevronLeft, Plus, Trash2, Clock, MapPin, Loader2, CalendarDays, X, CheckCircle } from 'lucide-react';

const COLORS = { lecture: '#3b82f6', exam: '#ef4444', assignment: '#f59e0b', event: '#8b5cf6', holiday: '#10b981' };
const TYPE_LABELS = { lecture: 'Buổi học', exam: 'Thi', assignment: 'Bài tập', event: 'Sự kiện', holiday: 'Nghỉ lễ' };

export default function CourseCalendarView({ course, role, email }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentDate, setCurrentDate] = useState(new Date());
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({ title: '', date: '', time: '', location: '', type: 'lecture', description: '' });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const isLecturer = role === 'lecturer';

  useEffect(() => {
    const q = query(collection(db, 'elearning_events'), where('courseDocId', '==', course.docId));
    const unsub = onSnapshot(q, snap => {
      setEvents(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    }, () => setLoading(false));
    return unsub;
  }, [course.docId]);

  const year = currentDate.getFullYear(), month = currentDate.getMonth();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const today = new Date();
  const monthNames = ['Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5','Tháng 6','Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'];
  const dayLabels = ['CN','T2','T3','T4','T5','T6','T7'];

  const getEventsForDay = (d) => {
    const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    return events.filter(e => e.date === dateStr);
  };

  const handleAdd = async () => {
    if (!form.title || !form.date) return;
    setSaving(true);
    try {
      await addDoc(collection(db, 'elearning_events'), { ...form, courseDocId: course.docId, createdBy: email, createdAt: serverTimestamp() });
      setShowAdd(false);
      setForm({ title: '', date: '', time: '', location: '', type: 'lecture', description: '' });
      setToast('Đã thêm sự kiện!');
      setTimeout(() => setToast(null), 2500);
    } catch(e) { console.error(e); }
    setSaving(false);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Xóa sự kiện này?')) return;
    await deleteDoc(doc(db, 'elearning_events', id));
  };

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 1100, margin: '0 auto' },
    card: { border: '1px solid #2a2d38', borderRadius: 6, overflow: 'hidden', backgroundColor: '#1e2129', marginBottom: 20 },
    cardHeader: { backgroundColor: '#2a2d38', padding: '12px 16px', fontSize: 14, fontWeight: 700, borderBottom: '1px solid #33363f', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#e0e0e0' },
    btn: { display: 'inline-flex', alignItems: 'center', gap: 6, padding: '7px 16px', background: '#2563eb', color: '#fff', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' },
    navBtn: { padding: '4px 10px', background: '#2a2d38', border: '1px solid #3f4350', borderRadius: 4, color: '#9ca3af', cursor: 'pointer', fontSize: 12, fontWeight: 600 },
    input: { width: '100%', padding: '8px 12px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, outline: 'none', fontFamily: 'inherit' },
    overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    modal: { background: '#1e2129', border: '1px solid #2a2d38', borderRadius: 10, padding: 24, width: 440, maxHeight: '80vh', overflowY: 'auto' },
  };

  const calendarCells = [];
  for (let i = 0; i < firstDay; i++) calendarCells.push(null);
  for (let d = 1; d <= daysInMonth; d++) calendarCells.push(d);

  return (
    <div style={s.page}>
      <div style={s.banner}>
        <div style={{ display: 'flex', alignItems: 'center' }}>{course.courseId} {course.courseName} ({course.classGroup}) <ChevronRight size={16} style={{ margin: '0 8px' }} /> Calendar</div>
      </div>
      <div style={s.container}>
        <div style={{ display: 'flex', gap: 20 }}>
          {/* Calendar Grid */}
          <div style={{ flex: 2 }}>
            <div style={s.card}>
              <div style={s.cardHeader}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <button style={s.navBtn} onClick={() => setCurrentDate(new Date(year, month - 1))}><ChevronLeft size={14} /></button>
                  <span style={{ minWidth: 140, textAlign: 'center' }}>{monthNames[month]} {year}</span>
                  <button style={s.navBtn} onClick={() => setCurrentDate(new Date(year, month + 1))}><ChevronRight size={14} /></button>
                </div>
                {isLecturer && <button style={s.btn} onClick={() => setShowAdd(true)}><Plus size={14} /> Thêm sự kiện</button>}
              </div>
              <div style={{ padding: 16 }}>
                {loading ? (
                  <div style={{ textAlign: 'center', padding: 40 }}><Loader2 size={24} style={{ color: '#3b82f6', animation: 'spin 1s linear infinite' }} /></div>
                ) : (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 1 }}>
                    {dayLabels.map(d => <div key={d} style={{ textAlign: 'center', fontSize: 11, fontWeight: 700, color: '#6b7280', padding: '6px 0', textTransform: 'uppercase' }}>{d}</div>)}
                    {calendarCells.map((day, i) => {
                      if (!day) return <div key={'e'+i} />;
                      const dayEvents = getEventsForDay(day);
                      const isToday = day === today.getDate() && month === today.getMonth() && year === today.getFullYear();
                      return (
                        <div key={day} style={{ minHeight: 70, padding: 4, borderRadius: 4, background: isToday ? 'rgba(37,99,235,0.15)' : 'transparent', border: isToday ? '1px solid rgba(37,99,235,0.4)' : '1px solid transparent' }}>
                          <div style={{ fontSize: 12, fontWeight: isToday ? 700 : 400, color: isToday ? '#60a5fa' : '#c8ccd0', marginBottom: 2 }}>{day}</div>
                          {dayEvents.slice(0, 3).map(ev => (
                            <div key={ev.id} style={{ fontSize: 10, padding: '1px 4px', borderRadius: 3, marginBottom: 1, background: COLORS[ev.type] + '25', color: COLORS[ev.type], whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', cursor: 'default' }} title={ev.title}>
                              {ev.title}
                            </div>
                          ))}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Upcoming Events */}
          <div style={{ flex: 1 }}>
            <div style={s.card}>
              <div style={s.cardHeader}><span>Sự kiện sắp tới</span></div>
              <div style={{ padding: 12 }}>
                {events.filter(e => e.date >= new Date().toISOString().slice(0,10)).sort((a,b) => a.date.localeCompare(b.date)).slice(0, 10).map(ev => (
                  <div key={ev.id} style={{ display: 'flex', gap: 10, padding: '10px 0', borderBottom: '1px solid #2a2d38', alignItems: 'flex-start' }}>
                    <div style={{ width: 4, height: 36, borderRadius: 2, background: COLORS[ev.type], flexShrink: 0, marginTop: 2 }} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: '#e0e0e0' }}>{ev.title}</div>
                      <div style={{ fontSize: 11, color: '#6b7280', display: 'flex', gap: 8, marginTop: 2, flexWrap: 'wrap' }}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}><CalendarDays size={10} />{ev.date}</span>
                        {ev.time && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}><Clock size={10} />{ev.time}</span>}
                        {ev.location && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}><MapPin size={10} />{ev.location}</span>}
                      </div>
                      <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 3, background: COLORS[ev.type] + '20', color: COLORS[ev.type], marginTop: 4, display: 'inline-block' }}>{TYPE_LABELS[ev.type]}</span>
                    </div>
                    {isLecturer && <button onClick={() => handleDelete(ev.id)} style={{ background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer', padding: 2 }}><Trash2 size={13} /></button>}
                  </div>
                ))}
                {events.length === 0 && !loading && <div style={{ textAlign: 'center', padding: 20, color: '#6b7280', fontSize: 13 }}>Chưa có sự kiện nào</div>}
              </div>
            </div>
            {/* Legend */}
            <div style={s.card}>
              <div style={s.cardHeader}><span>Chú thích</span></div>
              <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 6 }}>
                {Object.entries(TYPE_LABELS).map(([k, v]) => (
                  <div key={k} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12 }}>
                    <div style={{ width: 10, height: 10, borderRadius: 2, background: COLORS[k] }} />
                    <span style={{ color: '#c8ccd0' }}>{v}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Add Event Modal */}
      {showAdd && (
        <div style={s.overlay} onClick={() => setShowAdd(false)}>
          <div style={s.modal} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
              <h3 style={{ fontSize: 16, fontWeight: 700, color: '#e0e0e0' }}>Thêm sự kiện</h3>
              <button onClick={() => setShowAdd(false)} style={{ background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer' }}><X size={18} /></button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Tiêu đề *</label><input style={s.input} value={form.title} onChange={e => setForm(f => ({...f, title: e.target.value}))} /></div>
              <div style={{ display: 'flex', gap: 10 }}>
                <div style={{ flex: 1 }}><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Ngày *</label><input type="date" style={s.input} value={form.date} onChange={e => setForm(f => ({...f, date: e.target.value}))} /></div>
                <div style={{ flex: 1 }}><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Giờ</label><input type="time" style={s.input} value={form.time} onChange={e => setForm(f => ({...f, time: e.target.value}))} /></div>
              </div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Loại</label>
                <select style={{...s.input, cursor:'pointer'}} value={form.type} onChange={e => setForm(f => ({...f, type: e.target.value}))}>
                  {Object.entries(TYPE_LABELS).map(([k,v]) => <option key={k} value={k}>{v}</option>)}
                </select>
              </div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Địa điểm</label><input style={s.input} value={form.location} onChange={e => setForm(f => ({...f, location: e.target.value}))} /></div>
              <div><label style={{ fontSize: 12, color: '#6b7280', display: 'block', marginBottom: 4 }}>Mô tả</label><textarea style={{...s.input, minHeight: 60, resize: 'vertical'}} value={form.description} onChange={e => setForm(f => ({...f, description: e.target.value}))} /></div>
              <button style={{...s.btn, justifyContent: 'center', padding: '10px', opacity: saving ? 0.6 : 1}} onClick={handleAdd} disabled={saving}>
                {saving ? <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> : <Plus size={14} />} Thêm
              </button>
            </div>
          </div>
        </div>
      )}
      {toast && <div className="toast-notification success"><CheckCircle size={16} />{toast}</div>}
    </div>
  );
}
