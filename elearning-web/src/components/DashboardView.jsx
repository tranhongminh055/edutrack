import React from 'react';
import { BookOpen, Users, GraduationCap, ExternalLink } from 'lucide-react';

export default function DashboardView({ courses, role, email, onSelectCourse }) {
  // Group by major is not strictly necessary for a table, but we can sort by it
  const sortedCourses = [...courses].sort((a, b) => (a.major || '').localeCompare(b.major || ''));

  return (
    <div className="sakai-home">
      <div className="sakai-page-header slide-up-anim" style={{ animationDelay: '0ms' }}>
        <h2>📚 Dashboard</h2>
        <p>Tổng quan tất cả các môn học {role === 'lecturer' ? 'bạn đang giảng dạy' : 'bạn đã đăng ký'}</p>
      </div>

      {/* Stats bar */}
      <div className="dashboard-stats-bar slide-up-anim" style={{ animationDelay: '50ms' }}>
        <div className="dash-stat hover-scale">
          <div className="dash-stat-icon" style={{background: 'rgba(59, 130, 246, 0.15)', color: '#60a5fa'}}>
            <BookOpen size={24} />
          </div>
          <div>
            <div className="dash-stat-num">{courses.length}</div>
            <div className="dash-stat-label">{role === 'lecturer' ? 'Lớp đang dạy' : 'Môn đã đăng ký'}</div>
          </div>
        </div>
        
        {role === 'lecturer' && (
          <div className="dash-stat hover-scale">
            <div className="dash-stat-icon" style={{background: 'rgba(52, 211, 153, 0.15)', color: '#34d399'}}>
              <Users size={24} />
            </div>
            <div>
              <div className="dash-stat-num">{courses.reduce((s, c) => s + (c.studentCount || 0), 0)}</div>
              <div className="dash-stat-label">Tổng sinh viên</div>
            </div>
          </div>
        )}
        
        <div className="dash-stat hover-scale">
          <div className="dash-stat-icon" style={{background: 'rgba(251, 191, 36, 0.15)', color: '#fbbf24'}}>
            <GraduationCap size={24} />
          </div>
          <div>
            <div className="dash-stat-num">{new Set(courses.map(c => c.major)).size}</div>
            <div className="dash-stat-label">Ngành học</div>
          </div>
        </div>
      </div>

      {/* Course Table */}
      <div className="sakai-card slide-up-anim" style={{ animationDelay: '100ms' }}>
        <div className="sakai-card-title-bar">
          Danh sách môn học
        </div>
        <div className="sakai-card-body" style={{ padding: 0 }}>
          {courses.length > 0 ? (
            <div className="sakai-table-container">
              <table className="sakai-table">
                <thead>
                  <tr>
                    <th>Mã MH</th>
                    <th>Tên Môn Học</th>
                    <th>Lớp</th>
                    <th>{role === 'lecturer' ? 'Sĩ số' : 'Giảng viên'}</th>
                    <th>Ngành</th>
                    <th>Học kỳ</th>
                  </tr>
                </thead>
                <tbody>
                  {sortedCourses.map((course) => (
                    <tr key={course.docId} onClick={() => onSelectCourse(course)}>
                      <td><span className="course-code-badge">{course.courseId}</span></td>
                      <td className="course-name-cell">{course.courseName}</td>
                      <td>{course.classGroup}</td>
                      <td>{role === 'lecturer' ? `${course.studentCount} SV` : (course.lecturerEmail || 'N/A')}</td>
                      <td>{course.major || 'Chưa phân loại'}</td>
                      <td>{course.semester} - {course.academicYear}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="empty-state">
              <BookOpen />
              <p>{role === 'student' ? 'Bạn chưa đăng ký môn học nào.' : 'Chưa có lớp nào.'}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
