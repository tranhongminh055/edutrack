import React, { useState, useMemo, useEffect } from 'react';

const DAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export default function CalendarWidget({ selectedDate, onSelectDate, onAction }) {
  const now = new Date();
  
  // Initialize widget view to the selectedDate's month/year
  const [year, setYear] = useState(selectedDate ? selectedDate.getFullYear() : now.getFullYear());
  const [month, setMonth] = useState(selectedDate ? selectedDate.getMonth() : now.getMonth());

  // Update view if selectedDate changes externally
  useEffect(() => {
    if (selectedDate) {
      setYear(selectedDate.getFullYear());
      setMonth(selectedDate.getMonth());
    }
  }, [selectedDate]);

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  const days = useMemo(() => {
    const result = [];
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrevMonth = new Date(year, month, 0).getDate();

    for (let i = firstDay - 1; i >= 0; i--) {
      result.push({ day: daysInPrevMonth - i, isOther: true, monthOffset: -1 });
    }
    for (let i = 1; i <= daysInMonth; i++) {
      const isToday = i === now.getDate() && month === now.getMonth() && year === now.getFullYear();
      const isSelected = selectedDate && i === selectedDate.getDate() && month === selectedDate.getMonth() && year === selectedDate.getFullYear();
      result.push({
        day: i,
        isOther: false,
        isToday,
        isSelected,
        monthOffset: 0
      });
    }
    const remaining = 42 - result.length;
    for (let i = 1; i <= remaining; i++) {
      result.push({ day: i, isOther: true, monthOffset: 1 });
    }
    return result;
  }, [year, month, selectedDate]);

  const prevMonth = () => {
    if (month === 0) { setMonth(11); setYear(y => y - 1); }
    else setMonth(m => m - 1);
  };
  const nextMonth = () => {
    if (month === 11) { setMonth(0); setYear(y => y + 1); }
    else setMonth(m => m + 1);
  };
  const goToday = () => { setYear(now.getFullYear()); setMonth(now.getMonth()); };

  const handleDayClick = (d) => {
    let targetYear = year;
    let targetMonth = month + d.monthOffset;
    if (targetMonth < 0) { targetMonth = 11; targetYear--; }
    else if (targetMonth > 11) { targetMonth = 0; targetYear++; }

    const clickedDate = new Date(targetYear, targetMonth, d.day);
    if (onSelectDate) onSelectDate(clickedDate);
    if (onAction) onAction('calendar_day', d.day);
  };

  return (
    <div className="sakai-calendar">
      <div className="sakai-calendar-header">
        <h3>{monthNames[month]} {year}</h3>
        <div className="sakai-calendar-nav">
          <button onClick={prevMonth}>&lt;</button>
          <button onClick={goToday}>Today</button>
          <button onClick={nextMonth}>&gt;</button>
        </div>
      </div>
      <div className="sakai-calendar-grid">
        {DAY_LABELS.map(d => (
          <div key={d} className="sakai-cal-label">{d}</div>
        ))}
        {days.map((d, i) => (
          <div
            key={i}
            className={`sakai-cal-day${d.isToday ? ' today' : ''}${d.isSelected ? ' selected' : ''}${d.isOther ? ' other' : ''}`}
            onClick={() => handleDayClick(d)}
            style={d.isSelected ? { background: '#3b82f6', color: 'white', fontWeight: 'bold' } : {}}
          >
            {d.day}
          </div>
        ))}
      </div>
    </div>
  );
}
