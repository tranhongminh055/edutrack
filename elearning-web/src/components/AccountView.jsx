import React from 'react';

export default function AccountView({ email, role }) {
  // Extract simple parts from email for demonstration if no real name is provided
  const userId = email ? email.split('@')[0] : 'user';
  
  // A crude way to split a name like "tranhongminh" into First and Last for the UI
  // In a real app, this would come from a user profile database.
  let firstName = '';
  let lastName = '';
  if (userId.includes('.')) {
    const parts = userId.split('.');
    lastName = parts[parts.length - 1];
    firstName = parts.slice(0, -1).join(' ');
  } else {
    // Just put the whole thing in First Name, or split arbitrarily
    firstName = userId;
    lastName = '';
  }

  return (
    <div style={{ padding: '20px 30px', color: '#e0e0e0', maxWidth: 1000 }} className="slide-up-anim">
      <h2 style={{ fontSize: 18, fontWeight: 'bold', marginBottom: 20, color: '#fff' }}>My Account Details</h2>
      
      <div style={{ marginBottom: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: 16 }}>
          <h3 style={{ fontSize: 16, fontWeight: 'bold', color: '#fff', margin: 0, paddingRight: 16 }}>User</h3>
          <div style={{ flex: 1, height: 1, backgroundColor: '#3f4350' }}></div>
        </div>

        <div style={{ border: '1px solid #3f4350', borderRadius: 4, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <tbody>
              <tr style={{ borderBottom: '1px solid #3f4350' }}>
                <td style={{ padding: '12px 16px', fontWeight: 'bold', width: '25%', backgroundColor: '#1e2129' }}>User Id</td>
                <td style={{ padding: '12px 16px', backgroundColor: '#1e2129' }}>{userId}</td>
              </tr>
              <tr style={{ borderBottom: '1px solid #3f4350' }}>
                <td style={{ padding: '12px 16px', fontWeight: 'bold', backgroundColor: '#1e2129' }}>First Name</td>
                <td style={{ padding: '12px 16px', backgroundColor: '#1e2129' }}>{firstName}</td>
              </tr>
              <tr style={{ borderBottom: '1px solid #3f4350' }}>
                <td style={{ padding: '12px 16px', fontWeight: 'bold', backgroundColor: '#1e2129' }}>Last Name</td>
                <td style={{ padding: '12px 16px', backgroundColor: '#1e2129' }}>{lastName}</td>
              </tr>
              <tr style={{ borderBottom: '1px solid #3f4350' }}>
                <td style={{ padding: '12px 16px', fontWeight: 'bold', backgroundColor: '#1e2129' }}>Email</td>
                <td style={{ padding: '12px 16px', backgroundColor: '#1e2129' }}>{email}</td>
              </tr>
              <tr>
                <td style={{ padding: '12px 16px', fontWeight: 'bold', backgroundColor: '#1e2129' }}>Type</td>
                <td style={{ padding: '12px 16px', backgroundColor: '#1e2129' }}>{role}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
