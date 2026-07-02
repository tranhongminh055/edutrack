import React from 'react';
import { Users, BookOpen, Mail, GraduationCap, Building } from 'lucide-react';

const COLORS = ['#3b82f6', '#8b5cf6', '#06b6d4', '#f59e0b', '#ef4444', '#10b981', '#ec4899', '#6366f1'];

export default function MembershipView({ courses, role, email }) {
  return (
    <div className="sakai-home">
      <div className="sakai-page-header">
        <h2>👥 Membership</h2>
        <p>{role === 'lecturer' ? 'Danh sách các lớp bạn đang giảng dạy' : 'Danh sách các môn học bạn đã đăng ký'}</p>
      </div>

      {/* Summary */}
      <div className="sakai-card" style={{marginBottom: 20}}>
        <div className="sakai-card-title-bar">Thông tin thành viên</div>
        <div className="sakai-card-body">
          <div className="membership-summary">
            <div className="membership-info-row">
              <Mail size={16} style={{color: '#60a5fa'}} />
              <span><strong>Email:</strong> {email}</span>
            </div>
            <div className="membership-info-row">
              <GraduationCap size={16} style={{color: '#fbbf24'}} />
              <span><strong>Vai trò:</strong> {role === 'lecturer' ? 'Giảng viên' : 'Sinh viên'}</span>
            </div>
            <div className="membership-info-row">
              <BookOpen size={16} style={{color: '#34d399'}} />
              <span><strong>Tổng số {role === 'lecturer' ? 'lớp' : 'môn'}:</strong> {courses.length}</span>
            </div>
            {role === 'lecturer' && (
              <div className="membership-info-row">
                <Users size={16} style={{color: '#f472b6'}} />
                <span><strong>Tổng sinh viên:</strong> {courses.reduce((s, c) => s + (c.studentCount || 0), 0)}</span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Course memberships table */}
      <div className="sakai-card">
        <div className="sakai-card-title-bar" style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <span>Danh sách {role === 'lecturer' ? 'lớp giảng dạy' : 'môn đã đăng ký'}</span>
          <span style={{fontSize: 12, color: '#6b7280'}}>{courses.length} mục</span>
        </div>
        <div className="sakai-card-body" style={{padding: 0}}>
          {courses.length === 0 ? (
            <div className="empty-state" style={{padding: 40}}>
              <Users />
              <p>Chưa có dữ liệu.</p>
            </div>
          ) : (
            <table className="sakai-table">
              <thead>
                <tr>
                  <th>STT</th>
                  <th>Môn học</th>
                  <th>Mã MH</th>
                  <th>Lớp</th>
                  <th>Ngành</th>
                  <th>Học kỳ</th>
                  {role === 'lecturer' && <th>Sĩ số</th>}
                  {role === 'student' && <th>Giảng viên</th>}
                  <th>Trạng thái</th>
                </tr>
              </thead>
              <tbody>
                {courses.map((c, i) => (
                  <tr key={c.docId}>
                    <td>{i + 1}</td>
                    <td>
                      <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
                        <span style={{
                          width: 8, height: 8, borderRadius: '50%',
                          background: COLORS[i % COLORS.length], flexShrink: 0
                        }} />
                        <strong>{c.courseName}</strong>
                      </div>
                    </td>
                    <td><code style={{color: '#60a5fa', fontSize: 12}}>{c.courseId}</code></td>
                    <td>{c.classGroup}</td>
                    <td>{c.major || 'N/A'}</td>
                    <td>{c.semester} {c.academicYear}</td>
                    {role === 'lecturer' && <td><strong>{c.studentCount}</strong> SV</td>}
                    {role === 'student' && <td style={{fontSize: 12}}>{c.lecturerEmail || 'N/A'}</td>}
                    <td>
                      <span className="status-badge active">Đang hoạt động</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
