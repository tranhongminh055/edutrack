import React, { useState } from 'react';
import { Settings, Plus, Edit, Trash2, Users, LayoutList, Info, Shield, CheckCircle } from 'lucide-react';

export default function WorksiteSetupView({ courses, role }) {
  const [activeTab, setActiveTab] = useState('sites');

  return (
    <div className="sakai-home slide-up-anim">
      <div className="sakai-page-header">
        <h2><Settings size={22} style={{ display: 'inline', verticalAlign: 'sub', marginRight: 8 }}/> Worksite Setup</h2>
        <p>{role === 'lecturer' ? 'Quản lý, tạo mới và cấu hình các trang môn học của bạn' : 'Xem thông tin các trang môn học bạn đang tham gia'}</p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 20, borderBottom: '1px solid #3f4350', marginBottom: 24 }}>
        <button 
          className={`sakai-tab-btn ${activeTab === 'sites' ? 'active' : ''}`}
          onClick={() => setActiveTab('sites')}
          style={{ padding: '12px 0', background: 'transparent', border: 'none', color: activeTab === 'sites' ? '#60a5fa' : '#9ca3af', borderBottom: activeTab === 'sites' ? '2px solid #60a5fa' : '2px solid transparent', cursor: 'pointer', fontWeight: 600, fontSize: 14, transition: 'all 0.2s' }}
        >
          My Sites
        </button>
        {role === 'lecturer' && (
          <button 
            className={`sakai-tab-btn ${activeTab === 'new' ? 'active' : ''}`}
            onClick={() => setActiveTab('new')}
            style={{ padding: '12px 0', background: 'transparent', border: 'none', color: activeTab === 'new' ? '#60a5fa' : '#9ca3af', borderBottom: activeTab === 'new' ? '2px solid #60a5fa' : '2px solid transparent', cursor: 'pointer', fontWeight: 600, fontSize: 14, transition: 'all 0.2s' }}
          >
            Create New Site
          </button>
        )}
      </div>

      {activeTab === 'sites' && (
        <div className="sakai-card slide-up-anim" style={{ animationDelay: '50ms' }}>
          <div className="sakai-card-title-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span><LayoutList size={16} style={{ display: 'inline', marginRight: 8, verticalAlign: 'text-bottom' }}/> Các trang hiện tại</span>
            {role === 'lecturer' && (
              <button className="sakai-btn-primary" style={{ padding: '6px 12px', fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }} onClick={() => setActiveTab('new')}>
                <Plus size={14} /> Thêm Site Mới
              </button>
            )}
          </div>
          <div className="sakai-card-body" style={{ padding: 0 }}>
             <table className="sakai-table">
               <thead>
                 <tr>
                   <th>Site Name</th>
                   <th>Term</th>
                   <th>Status</th>
                   <th>Role</th>
                   <th style={{ textAlign: 'right' }}>Actions</th>
                 </tr>
               </thead>
               <tbody>
                 {courses.map(c => (
                   <tr key={c.docId}>
                     <td>
                       <div style={{ fontWeight: 600, color: '#e0e0e0' }}>{c.courseName}</div>
                       <div style={{ fontSize: 12, color: '#6b7280', marginTop: 4 }}>{c.courseId} - Lớp {c.classGroup}</div>
                     </td>
                     <td>
                       <div style={{ color: '#e0e0e0' }}>{c.semester}</div>
                       <div style={{ fontSize: 12, color: '#6b7280' }}>Năm học {c.academicYear}</div>
                     </td>
                     <td>
                       <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: 'rgba(16, 185, 129, 0.1)', color: '#34d399', padding: '4px 8px', borderRadius: 4, fontSize: 12, fontWeight: 600, border: '1px solid rgba(16, 185, 129, 0.2)' }}>
                         <CheckCircle size={12} /> Published
                       </span>
                     </td>
                     <td>
                       <span style={{ color: '#9ca3af', fontSize: 13 }}>
                         {role === 'lecturer' ? 'Instructor' : 'Student'}
                       </span>
                     </td>
                     <td style={{ textAlign: 'right' }}>
                       {role === 'lecturer' ? (
                         <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
                           <button className="sakai-btn-outline" style={{ padding: '6px' }} title="Edit Site Info"><Edit size={14} /></button>
                           <button className="sakai-btn-outline" style={{ padding: '6px' }} title="Manage Participants"><Users size={14} /></button>
                           <button className="sakai-btn-outline" style={{ padding: '6px', color: '#f87171', borderColor: 'rgba(248, 113, 113, 0.3)' }} title="Delete Site"><Trash2 size={14} /></button>
                         </div>
                       ) : (
                         <button className="sakai-btn-outline" style={{ padding: '6px 12px', fontSize: 12, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                           <Info size={14} /> Details
                         </button>
                       )}
                     </td>
                   </tr>
                 ))}
                 {courses.length === 0 && (
                   <tr>
                     <td colSpan="5" style={{ textAlign: 'center', padding: '60px 20px', color: '#6b7280' }}>
                       <Shield size={32} style={{ opacity: 0.3, margin: '0 auto 12px' }} />
                       Chưa có trang môn học nào.
                     </td>
                   </tr>
                 )}
               </tbody>
             </table>
          </div>
        </div>
      )}

      {activeTab === 'new' && role === 'lecturer' && (
        <div className="sakai-card slide-up-anim" style={{ animationDelay: '50ms' }}>
          <div className="sakai-card-title-bar">Tạo Worksite Mới</div>
          <div className="sakai-card-body">
            <div className="empty-state" style={{ minHeight: 250 }}>
               <Shield size={48} style={{ color: '#4b5563', marginBottom: 20 }} />
               <h3 style={{ color: '#e0e0e0', marginBottom: 8, fontSize: 18 }}>Tính năng đang được phát triển</h3>
               <p style={{ color: '#9ca3af', textAlign: 'center', maxWidth: 450, lineHeight: 1.6 }}>
                 Việc tạo mới Worksite hiện tại được đồng bộ tự động từ hệ thống Quản lý Đào tạo của trường. Việc tạo site thủ công sẽ sớm được ra mắt trong phiên bản tiếp theo.
               </p>
               <button className="sakai-btn-outline" style={{ marginTop: 24 }} onClick={() => setActiveTab('sites')}>
                 Quay lại danh sách
               </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
