import React, { useState } from 'react';
import { ChevronUp, ChevronDown } from 'lucide-react';

export default function PreferencesView() {
  const [activeTab, setActiveTab] = useState('notifications');

  const [sections, setSections] = useState({
    messages: true,
    announcements: true,
    assignments: true,
    conversations: true
  });

  const toggleSection = (sec) => {
    setSections(prev => ({ ...prev, [sec]: !prev[sec] }));
  };

  const tabs = [
    { id: 'notifications', label: 'Notifications' },
    { id: 'timezone', label: 'Time Zone' },
    { id: 'language', label: 'Language' },
    { id: 'privacy', label: 'Privacy Status' },
    { id: 'sites', label: 'Sites' },
    { id: 'editor', label: 'Editor' },
    { id: 'theme', label: 'Theme' }
  ];

  return (
    <div style={{ padding: '20px 30px', color: '#e0e0e0', maxWidth: 1000 }}>
      {/* Tabs */}
      <div style={{ display: 'flex', gap: 2, marginBottom: 24, flexWrap: 'wrap' }}>
        {tabs.map(t => (
          <button
            key={t.id}
            onClick={() => setActiveTab(t.id)}
            style={{
              padding: '8px 16px',
              backgroundColor: activeTab === t.id ? '#cc0000' : '#2a2d38',
              color: activeTab === t.id ? '#fff' : '#9ca3af',
              border: 'none',
              cursor: 'pointer',
              fontSize: 13,
              fontWeight: 500
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {activeTab === 'notifications' && (
        <div className="slide-up-anim">
          <h2 style={{ fontSize: 18, fontWeight: 'bold', marginBottom: 12, color: '#fff' }}>Notifications</h2>
          <p style={{ fontSize: 13, color: '#9ca3af', marginBottom: 20 }}>
            You will receive all high priority notifications via email. Set low priority notifications below.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {/* Messages */}
            <div style={{ border: '1px solid #3f4350', borderRadius: 4, overflow: 'hidden' }}>
              <div 
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', backgroundColor: '#3f4350', cursor: 'pointer' }}
                onClick={() => toggleSection('messages')}
              >
                <span style={{ fontSize: 14, fontWeight: 600 }}>Messages</span>
                {sections.messages ? <ChevronUp size={16} color="#9ca3af"/> : <ChevronDown size={16} color="#9ca3af"/>}
              </div>
              {sections.messages && (
                <div style={{ padding: '16px', backgroundColor: '#1e2129' }}>
                  <p style={{ fontSize: 13, color: '#9ca3af', marginBottom: 12 }}>
                    Configure an alternative messages forwarding email address in the 'Messages' tool.
                  </p>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', marginBottom: 8, cursor: 'pointer' }}>
                    <input type="radio" name="messages" />
                    Forward private messages from all my sites to my main email address
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', cursor: 'pointer' }}>
                    <input type="radio" name="messages" defaultChecked />
                    Do not forward private messages to my email address
                  </label>
                </div>
              )}
            </div>

            {/* Announcements */}
            <div style={{ border: '1px solid #3f4350', borderRadius: 4, overflow: 'hidden' }}>
              <div 
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', backgroundColor: '#3f4350', cursor: 'pointer' }}
                onClick={() => toggleSection('announcements')}
              >
                <span style={{ fontSize: 14, fontWeight: 600 }}>Announcements</span>
                {sections.announcements ? <ChevronUp size={16} color="#9ca3af"/> : <ChevronDown size={16} color="#9ca3af"/>}
              </div>
              {sections.announcements && (
                <div style={{ padding: '16px', backgroundColor: '#1e2129' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', marginBottom: 8, cursor: 'pointer' }}>
                    <input type="radio" name="announcements" />
                    Do not send me low priority announcements
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', marginBottom: 8, cursor: 'pointer' }}>
                    <input type="radio" name="announcements" />
                    Send me one email per day summarizing all low priority announcements
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', cursor: 'pointer' }}>
                    <input type="radio" name="announcements" defaultChecked />
                    Send me each notification separately
                  </label>
                </div>
              )}
            </div>

            {/* Assignments */}
            <div style={{ border: '1px solid #3f4350', borderRadius: 4, overflow: 'hidden' }}>
              <div 
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', backgroundColor: '#3f4350', cursor: 'pointer' }}
                onClick={() => toggleSection('assignments')}
              >
                <span style={{ fontSize: 14, fontWeight: 600 }}>Assignments</span>
                {sections.assignments ? <ChevronUp size={16} color="#9ca3af"/> : <ChevronDown size={16} color="#9ca3af"/>}
              </div>
              {sections.assignments && (
                <div style={{ padding: '16px', backgroundColor: '#1e2129' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', marginBottom: 8, cursor: 'pointer' }}>
                    <input type="radio" name="assignments" />
                    Do not send me assignment due date notifications
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', cursor: 'pointer' }}>
                    <input type="radio" name="assignments" defaultChecked />
                    Send me assignment due date notifications
                  </label>
                </div>
              )}
            </div>

            {/* Conversations */}
            <div style={{ border: '1px solid #3f4350', borderRadius: 4, overflow: 'hidden' }}>
              <div 
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', backgroundColor: '#3f4350', cursor: 'pointer' }}
                onClick={() => toggleSection('conversations')}
              >
                <span style={{ fontSize: 14, fontWeight: 600 }}>Conversations</span>
                {sections.conversations ? <ChevronUp size={16} color="#9ca3af"/> : <ChevronDown size={16} color="#9ca3af"/>}
              </div>
              {sections.conversations && (
                <div style={{ padding: '16px', backgroundColor: '#1e2129' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', marginBottom: 8, cursor: 'pointer' }}>
                    <input type="radio" name="conversations" />
                    Do not send me Conversations notifications
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#d1d5db', marginBottom: 12, cursor: 'pointer' }}>
                    <input type="radio" name="conversations" defaultChecked />
                    Send me Conversations notifications
                  </label>
                  <a href="#" style={{ fontSize: 13, color: '#60a5fa', textDecoration: 'underline' }}>Add a site</a>
                </div>
              )}
            </div>

          </div>
        </div>
      )}

      {/* Placeholder for other tabs */}
      {activeTab !== 'notifications' && (
        <div className="slide-up-anim" style={{ padding: 40, textAlign: 'center', color: '#6b7280' }}>
          <h3>{tabs.find(t => t.id === activeTab)?.label} Settings</h3>
          <p>These settings are currently under development.</p>
        </div>
      )}
    </div>
  );
}
