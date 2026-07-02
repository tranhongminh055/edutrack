import React, { useState, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Clock, Settings, Share } from 'lucide-react';
import CalendarWidget from './CalendarWidget';

const DAY_LABELS = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];

// Helper to format float hour (e.g. 7.5) to HH:MM (e.g. "07:30")
function formatTime(hourFloat) {
  const h = Math.floor(hourFloat);
  const m = Math.round((hourFloat - h) * 60);
  return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
}

export default function CalendarView({ courses }) {
  const now = new Date();
  const [selectedDate, setSelectedDate] = useState(new Date(now.getFullYear(), now.getMonth(), now.getDate()));

  // Lọc lịch học theo ngày được chọn
  const coursesOnDay = useMemo(() => {
    // getDay() trả về: 0 (Sun), 1 (Mon), ..., 6 (Sat)
    // dayOfWeek trong DB: 2 (Thứ 2), 3 (Thứ 3), ..., 7 (Thứ 7), 8 hoặc 1 (Chủ Nhật)
    const jsDay = selectedDate.getDay();
    const dbDay = jsDay === 0 ? 8 : jsDay + 1; 

    return courses.filter(c => {
      // Cho phép Chủ nhật là 1 hoặc 8
      if (jsDay === 0 && (c.dayOfWeek === 1 || c.dayOfWeek === 8)) return true;
      return c.dayOfWeek === dbDay;
    }).sort((a, b) => a.startHour - b.startHour);
  }, [courses, selectedDate]);

  return (
    <div className="sakai-home">
      <div className="sakai-page-header slide-up-anim" style={{ animationDelay: '0ms' }}>
        <h2>📅 Calendar</h2>
        <p>Lịch học và sự kiện</p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 20, maxWidth: 400, margin: '0 auto' }}>
        {/* Mini Calendar Widget */}
        <div className="sakai-card slide-up-anim" style={{ animationDelay: '50ms' }}>
          <div className="sakai-card-title-bar">Mini Calendar</div>
          <div className="sakai-card-body">
            <div className="sakai-cal-actions">
              <button className="sakai-btn-outline">
                <Settings size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: 'text-top' }} /> 
                Options
              </button>
              <button className="sakai-btn-outline">
                <Share size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: 'text-top' }} /> 
                Publish (private)
              </button>
            </div>
            <CalendarWidget 
              selectedDate={selectedDate}
              onSelectDate={setSelectedDate}
            />
          </div>
        </div>

        {/* Today's schedule */}
        <div className="sakai-card slide-up-anim" style={{ animationDelay: '100ms' }}>
          <div className="sakai-card-title-bar">
            📋 Lịch học ngày {selectedDate.toLocaleDateString('vi-VN')} ({DAY_LABELS[selectedDate.getDay()]})
          </div>
          <div className="sakai-card-body">
            {coursesOnDay.length > 0 ? (
              <div className="today-schedule">
                {coursesOnDay.map((c) => {
                  const startTime = formatTime(c.startHour);
                  const endTime = formatTime(c.startHour + c.duration);
                  
                  return (
                    <div key={c.docId} className="today-schedule-item">
                      <div className="today-time">
                        <Clock size={14} />
                        <span>{startTime} - {endTime}</span>
                      </div>
                      <div className="today-info">
                        <h4>{c.courseName}</h4>
                        <p>Lớp {c.classGroup} · Phòng: {c.room || 'Chưa xếp'}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <p style={{color: '#6b7280', fontSize: 13}}>Không có lịch học trong ngày này.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
