import React, { useState } from 'react';
import { X, Home } from 'lucide-react';

export default function AllSitesModal({ courses, onClose, onSelectCourse }) {
  const [filter, setFilter] = useState('');
  
  // Group courses by semester/academicYear
  const groups = {};
  courses.forEach(c => {
    let term = '';
    if (c.semester && c.academicYear) {
      term = `${c.semester} - Năm Học ${c.academicYear}`;
    } else {
      // Extract from classGroup or default
      term = 'Học Kỳ - Năm Học (Other)';
    }
    
    if (!groups[term]) groups[term] = [];
    if (c.courseName.toLowerCase().includes(filter.toLowerCase()) || 
        (c.courseId && c.courseId.toLowerCase().includes(filter.toLowerCase()))) {
      groups[term].push(c);
    }
  });

  return (
    <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 9999, display: 'flex', justifyContent: 'center', alignItems: 'flex-start', paddingTop: '10vh' }}>
      <div style={{ backgroundColor: '#2a2d38', width: '90%', maxWidth: 800, borderRadius: 8, boxShadow: '0 10px 25px rgba(0,0,0,0.5)', display: 'flex', flexDirection: 'column', maxHeight: '80vh' }} className="slide-up-anim">
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 20px', backgroundColor: '#3f4350', borderTopLeftRadius: 8, borderTopRightRadius: 8 }}>
          <h2 style={{ fontSize: 16, fontWeight: 'bold', color: '#e0e0e0', margin: 0 }}>View All Sites</h2>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: '#9ca3af', cursor: 'pointer', padding: 4, display: 'flex' }}>
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <div style={{ padding: '20px', overflowY: 'auto' }} className="custom-scrollbar">
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
            <button className="sakai-btn-outline" style={{ fontSize: 13, padding: '6px 12px' }}>Edit Sites</button>
          </div>

          <div style={{ display: 'flex', gap: 24, borderBottom: '1px solid #3f4350', marginBottom: 20 }}>
            <div style={{ paddingBottom: 8, color: '#e0e0e0', borderBottom: '2px solid #60a5fa', fontWeight: 'bold', fontSize: 14 }}>Sites</div>
            <div style={{ paddingBottom: 8, color: '#9ca3af', fontSize: 14, cursor: 'pointer' }}>Organize Pinned</div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
            <span style={{ color: '#9ca3af', fontSize: 14 }}>Filter sites</span>
            <input 
              type="text" 
              value={filter}
              onChange={e => setFilter(e.target.value)}
              style={{ backgroundColor: '#1e2129', border: '1px solid #3f4350', borderRadius: 16, padding: '6px 12px', color: '#e0e0e0', width: 250, outline: 'none' }} 
            />
          </div>

          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
            {/* Left column: Semesters */}
            <div style={{ flex: 2, display: 'flex', flexDirection: 'column', gap: 20 }}>
              {Object.keys(groups).length === 0 ? (
                <div style={{ color: '#9ca3af', fontSize: 14 }}>Không tìm thấy môn học nào.</div>
              ) : Object.keys(groups).map(term => (
                <div key={term} style={{ backgroundColor: '#3f4350', borderRadius: 6, padding: 16 }}>
                  <h3 style={{ color: '#fff', fontSize: 15, fontWeight: 'bold', margin: '0 0 12px 0' }}>{term}</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {groups[term].map(c => (
                      <button 
                        key={c.docId}
                        onClick={() => { onSelectCourse(c); onClose(); }}
                        style={{ textAlign: 'left', backgroundColor: '#2a2d38', border: 'none', padding: '10px 16px', color: '#d1d5db', fontSize: 14, cursor: 'pointer', borderRadius: 4, transition: 'background 0.2s' }}
                        onMouseOver={e => e.currentTarget.style.backgroundColor = '#4b5563'}
                        onMouseOut={e => e.currentTarget.style.backgroundColor = '#2a2d38'}
                      >
                        {c.courseId} - {c.courseName} ({c.classGroup})
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>

            {/* Right column: OTHER (Home) */}
            <div style={{ flex: 1 }}>
              <div style={{ backgroundColor: '#3f4350', borderRadius: 6, padding: 16 }}>
                <h3 style={{ color: '#fff', fontSize: 15, fontWeight: 'bold', margin: '0 0 12px 0', textTransform: 'uppercase' }}>OTHER</h3>
                <button 
                  onClick={() => { onSelectCourse(null); onClose(); }} // Route to overview
                  style={{ width: '100%', textAlign: 'left', backgroundColor: '#cc0000', border: 'none', padding: '10px 16px', color: '#fff', fontSize: 14, cursor: 'pointer', borderRadius: 4, display: 'flex', alignItems: 'center', gap: 8 }}
                >
                  <Home size={16} /> Home
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
