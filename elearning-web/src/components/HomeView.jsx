import React, { useState, useMemo, useEffect } from 'react';
import { Calendar, Bell, BookOpen, Users, Clock, FileText, Edit3, Check, Settings, Share, AlertCircle } from 'lucide-react';
import CalendarWidget from './CalendarWidget';

const DAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// --- Custom Toast Component ---
function Toast({ message, type, onClose }) {
  useEffect(() => {
    const timer = setTimeout(onClose, 3000);
    return () => clearTimeout(timer);
  }, [onClose]);

  return (
    <div className={`toast-notification ${type}`}>
      {type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
      <span>{message}</span>
    </div>
  );
}



export default function HomeView({ courses, role, email, onSelectCourse }) {
  const [toast, setToast] = useState(null);
  
  // Interactive states
  const [isEditingHome, setIsEditingHome] = useState(false);
  const [homeText, setHomeText] = useState(
    `Hệ thống E-Learning EduTrack cho phép ${role === 'lecturer' ? 'Giảng viên tạo và quản lý' : 'Sinh viên tham gia'} các bài kiểm tra trắc nghiệm, câu hỏi ngắn và tự luận trực tuyến. Bạn có thể xem lịch học, theo dõi thông báo và quản lý tài liệu tại đây.`
  );
  const [showMotdOptions, setShowMotdOptions] = useState(false);

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
  };

  const handleEditHome = () => {
    if (role !== 'lecturer' && role !== 'admin') {
      showToast('Chỉ Giảng viên/Quản trị viên mới có thể chỉnh sửa.', 'error');
      return;
    }
    if (isEditingHome) {
      showToast('Đã lưu thông tin trang chủ!', 'success');
    }
    setIsEditingHome(!isEditingHome);
  };

  const handlePublishCalendar = () => {
    showToast('Đã xuất bản lịch trình ở chế độ Riêng tư.', 'success');
  };

  const handleCalendarOptions = () => {
    showToast('Đang mở cài đặt Lịch...', 'success');
  };

  const handleDayClick = (type, day) => {
    showToast(`Đã chọn ngày ${day} trên lịch.`, 'success');
  };

  return (
    <div className="sakai-home">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <div className="sakai-home-grid">
        {/* === Left Column === */}
        <div className="sakai-home-left">
          {/* Message Of The Day */}
          <div className="sakai-card slide-up-anim" style={{ animationDelay: '0ms' }}>
            <div className="sakai-card-title-bar">Message Of The Day</div>
            <div className="sakai-card-body">
              <div className="sakai-motd-options" style={{ position: 'relative' }}>
                <button 
                  className="sakai-btn-outline" 
                  onClick={() => setShowMotdOptions(!showMotdOptions)}
                >
                  <Settings size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: 'text-top' }} /> 
                  Options
                </button>
                
                {showMotdOptions && (
                  <div className="popover-menu">
                    <button onClick={() => { showToast('Đã đánh dấu là đã đọc'); setShowMotdOptions(false); }}>Mark as Read</button>
                    <button onClick={() => { showToast('Tính năng ẩn thông báo đang phát triển'); setShowMotdOptions(false); }}>Hide Message</button>
                  </div>
                )}
              </div>
              <div className="sakai-motd-content">
                <h4>Hướng dẫn sử dụng Hệ thống E-Learning EduTrack</h4>
                <p className="sakai-motd-meta">(PHÒNG ĐÀO TẠO · {new Date().toLocaleDateString('vi-VN')})</p>
                <p>
                  Chào mừng {role === 'lecturer' ? 'Giảng viên' : 'Sinh viên'} đến với hệ thống E-Learning. 
                  Chọn môn học ở menu bên trái hoặc trong mục Recent để truy cập bài kiểm tra trực tuyến.
                </p>
              </div>
            </div>
          </div>

          {/* Home Information Display */}
          <div className="sakai-card slide-up-anim" style={{ animationDelay: '100ms' }}>
            <div className="sakai-info-bar">
              <span>Home Information Display</span>
              <button 
                className={`sakai-btn-edit ${isEditingHome ? 'active' : ''}`}
                onClick={handleEditHome}
              >
                {isEditingHome ? <Check size={12} /> : <Edit3 size={12} />} 
                {isEditingHome ? ' Save' : ' Edit'}
              </button>
            </div>
            <div className="sakai-card-body">
              <h3 className="sakai-welcome-title">Welcome to your personal workspace.</h3>
              
              {isEditingHome ? (
                <textarea 
                  className="sakai-home-textarea"
                  value={homeText}
                  onChange={(e) => setHomeText(e.target.value)}
                  rows={4}
                />
              ) : (
                <p className="sakai-welcome-text">
                  {homeText}
                </p>
              )}

              <p className="sakai-welcome-text" style={{ marginTop: 12 }}>
                Các môn học hiển thị dựa trên dữ liệu đăng ký của bạn. 
                Hiện tại bạn đang có <strong>{courses.length} môn học</strong> trong hệ thống.
              </p>
            </div>
          </div>

          {/* Recent Announcements - bottom of left col */}
          <div className="sakai-card slide-up-anim" style={{ animationDelay: '200ms' }}>
            <div className="sakai-card-title-bar">Recent Announcements</div>
            <div className="sakai-card-body">
              {courses.length > 0 ? (
                <div className="sakai-announcements">
                  {courses.slice(0, 3).map((c, i) => (
                    <div key={c.docId} className="sakai-announcement-item">
                      <div className="sakai-announcement-dot" />
                      <div>
                        <a className="sakai-announcement-link" onClick={() => onSelectCourse(c)}>
                          {c.courseName} ({c.classGroup}) — Bài kiểm tra đã sẵn sàng
                        </a>
                        <p className="sakai-announcement-meta">
                          {c.lecturerEmail || 'N/A'} · {c.semester} {c.academicYear}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p style={{color: '#6b7280', fontSize: 13}}>Chưa có thông báo mới.</p>
              )}
            </div>
          </div>
        </div>

        {/* === Right Column === */}
        <div className="sakai-home-right">
          {/* Calendar */}
          <div className="sakai-card slide-up-anim" style={{ animationDelay: '50ms' }}>
            <div className="sakai-card-title-bar">Calendar</div>
            <div className="sakai-card-body">
              <div className="sakai-cal-actions">
                <button className="sakai-btn-outline" onClick={handleCalendarOptions}>
                  <Settings size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: 'text-top' }} /> 
                  Options
                </button>
                <button className="sakai-btn-outline" onClick={handlePublishCalendar}>
                  <Share size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: 'text-top' }} /> 
                  Publish (private)
                </button>
              </div>
              <CalendarWidget onAction={handleDayClick} />
            </div>
          </div>

          {/* Quick Info */}
          <div className="sakai-card slide-up-anim" style={{ animationDelay: '150ms' }}>
            <div className="sakai-card-title-bar">
              {role === 'lecturer' ? 'Thống kê Giảng viên' : 'Thông tin Sinh viên'}
            </div>
            <div className="sakai-card-body">
              <div className="sakai-stats">
                <div className="sakai-stat-row hover-scale">
                  <BookOpen size={16} style={{color: '#60a5fa'}} />
                  <span>{courses.length} {role === 'lecturer' ? 'lớp đang dạy' : 'môn đã đăng ký'}</span>
                </div>
                {role === 'lecturer' && (
                  <div className="sakai-stat-row hover-scale">
                    <Users size={16} style={{color: '#34d399'}} />
                    <span>{courses.reduce((s, c) => s + (c.studentCount || 0), 0)} tổng sinh viên</span>
                  </div>
                )}
                <div className="sakai-stat-row hover-scale">
                  <Clock size={16} style={{color: '#fbbf24'}} />
                  <span>{new Date().toLocaleDateString('vi-VN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
