import React from 'react';
import {
  Home, LayoutDashboard, Users, Calendar, FolderOpen, Bell, Settings,
  UserCircle, ChevronRight, ChevronDown, ChevronLeft, Pin, Clock, Loader2, BookOpen, MessageSquare, CheckCircle, FileText
} from 'lucide-react';

export default function Sidebar({ courses, selectedCourse, onSelectCourse, onNavClick, onViewAllSites, currentView, loading, role }) {
  const homeMenuItems = [
    { icon: <LayoutDashboard size={15} />, label: 'Overview', id: 'overview' },
    { icon: <Home size={15} />, label: 'Dashboard', id: 'dashboard' },
    { icon: <Users size={15} />, label: 'Membership', id: 'membership' },
    { icon: <Calendar size={15} />, label: 'Calendar', id: 'calendar' },
    { icon: <FolderOpen size={15} />, label: 'Resources', id: 'resources' },
    { icon: <Bell size={15} />, label: 'Announcements', id: 'announcements' },
    { icon: <FileText size={15} />, label: 'Phiếu Đánh Giá', id: 'lecturer_evaluation' },
    { icon: <Settings size={15} />, label: 'Worksite Setup', id: 'worksite_setup' },
    { icon: <UserCircle size={15} />, label: 'Preferences', id: 'preferences' },
    { icon: <UserCircle size={15} />, label: 'Account', id: 'account' },
  ];

  const courseMenuItems = [
    { icon: <LayoutDashboard size={15} />, label: 'Home', id: 'course' },
    { icon: <BookOpen size={15} />, label: 'Syllabus', id: 'course_syllabus' },
    { icon: <Calendar size={15} />, label: 'Calendar', id: 'course_calendar' },
    { icon: <FolderOpen size={15} />, label: 'Lessons', id: 'course_lessons' },
    { icon: <Bell size={15} />, label: 'Announcements', id: 'course_announcements' },
    { icon: <FolderOpen size={15} />, label: 'Resources', id: 'course_resources' },
    { icon: <Settings size={15} />, label: 'Assignments', id: 'course_assignments' },
    { icon: <Settings size={15} />, label: 'Tests & Quizzes', id: 'course_tests' },
    { icon: <Settings size={15} />, label: 'Gradebook', id: 'course_gradebook' },
    ...(role === 'lecturer' ? [{ icon: <Users size={15} />, label: 'Roster', id: 'course_roster' }] : []),
  ];

  return (
    <div className="sidebar custom-scrollbar">
      {selectedCourse ? (
        <>
          {/* Back to Home Button */}
          <div style={{ padding: '10px 14px', borderBottom: '1px solid #2a2d38' }}>
            <button 
              onClick={() => onNavClick('overview')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                background: 'none',
                border: 'none',
                color: '#60a5fa',
                cursor: 'pointer',
                fontSize: '12px',
                fontWeight: '600',
                padding: '4px 0',
                width: '100%',
                textAlign: 'left'
              }}
            >
              <ChevronLeft size={14} />
              <span>Quay lại Trang chủ</span>
            </button>
          </div>

          {/* Course Menu */}
          <div className="sakai-section">
            <button className="sakai-section-header" onClick={() => onNavClick('course')}>
              <ChevronDown size={14} />
              <span>{selectedCourse.courseId || selectedCourse.courseName}</span>
            </button>
            <div className="sakai-menu">
              {courseMenuItems.map((item, idx) => (
                <button
                  key={item.id + idx}
                  className={`sakai-menu-item ${currentView === item.id || (item.id === 'course' && currentView === 'course') ? 'active' : ''}`}
                  onClick={() => onNavClick(item.id)}
                >
                  {item.icon}
                  <span>{item.label}</span>
                </button>
              ))}
            </div>
          </div>
        </>
      ) : (
        <>
          {/* Home Section */}
          <div className="sakai-section">
            <button className="sakai-section-header" onClick={() => onNavClick('overview')}>
              <ChevronDown size={14} />
              <span>Home</span>
            </button>
            <div className="sakai-menu">
              {homeMenuItems.map((item, idx) => (
                <button
                  key={item.id + idx}
                  className={`sakai-menu-item ${currentView === item.id ? 'active' : ''}`}
                  onClick={() => onNavClick(item.id)}
                >
                  {item.icon}
                  <span>{item.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Pinned */}
          <div className="sakai-divider-section">
            <div className="sakai-divider-title">
              <Pin size={12} />
              <span>Pinned</span>
            </div>
            <div className="sakai-empty-text">No pinned sites yet</div>
          </div>

          {/* Recent / My Courses */}
          <div className="sakai-divider-section">
            <div className="sakai-divider-title">
              <Clock size={12} />
              <span>Recent</span>
            </div>
            
            {loading ? (
              <div style={{display: 'flex', justifyContent: 'center', padding: '16px 0'}}>
                <Loader2 size={20} style={{color: '#3b82f6', animation: 'spin 1s linear infinite'}} />
              </div>
            ) : courses.length === 0 ? (
              <div className="sakai-empty-text">
                {role === 'student' ? 'Chưa đăng ký môn học.' : 'Chưa có lớp nào.'}
              </div>
            ) : (
              <div className="sakai-course-list">
                {courses.map((course) => {
                  const isActive = selectedCourse?.docId === course.docId && currentView === 'course';
                  return (
                    <button
                      key={course.docId}
                      className={`sakai-course-item ${isActive ? 'active' : ''}`}
                      onClick={() => onSelectCourse(course)}
                    >
                      <ChevronRight size={14} className="sakai-course-arrow" />
                      <div className="sakai-course-info">
                        <span className="sakai-course-name">{course.courseName}</span>
                        <span className="sakai-course-meta">({course.classGroup})</span>
                      </div>
                      {role === 'student' && course.hasGrade && (
                        <CheckCircle size={14} style={{ color: '#22c55e', marginLeft: 'auto' }} title="Đã có điểm" />
                      )}
                      <span className="sakai-pin-btn" title="Pin">
                        <Pin size={12} />
                      </span>
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </>
      )}

      <div style={{ flex: 1 }}></div>

      {/* View all */}
      <div className="sakai-view-all" onClick={onViewAllSites} style={{ marginTop: 'auto' }}>
        <BookOpen size={14} />
        <span>View all my sites</span>
      </div>
    </div>
  );
}
