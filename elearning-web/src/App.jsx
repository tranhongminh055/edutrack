import React, { useState, useEffect } from 'react';
import './App.css';
import { BrowserRouter as Router, useSearchParams } from 'react-router-dom';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from './firebase';
import Sidebar from './components/Sidebar';
import TestPanel from './components/TestPanel';
import { BookOpen } from 'lucide-react';

function Dashboard() {
  const [searchParams] = useSearchParams();
  const userId = searchParams.get('userId');
  const role = searchParams.get('role'); // 'student' or 'lecturer'
  const email = searchParams.get('email');

  const [courses, setCourses] = useState([]);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!userId && !email) {
      setLoading(false);
      return;
    }

    let q;
    if (role === 'student') {
      q = query(collection(db, 'registrations'), where('userId', '==', userId));
    } else {
      q = query(collection(db, 'registrations'), where('lecturerEmail', '==', email));
    }

    const unsubscribe = onSnapshot(q, (snapshot) => {
      // Grouping courses by courseDocId since registrations might have multiple students for a lecturer
      const courseMap = new Map();
      snapshot.docs.forEach(doc => {
        const data = doc.data();
        if (!courseMap.has(data.courseDocId)) {
          courseMap.set(data.courseDocId, {
            docId: data.courseDocId,
            courseName: data.courseName,
            courseId: data.courseId,
            classGroup: data.classGroup,
            lecturerName: data.lecturerName
          });
        }
      });
      setCourses(Array.from(courseMap.values()));
      setLoading(false);
    }, (error) => {
      console.error('Error fetching courses:', error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [userId, role, email]);

  if (!userId && !email) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center text-white">
        <div className="text-center p-8 bg-gray-800 rounded-xl shadow-2xl border border-gray-700">
          <BookOpen className="w-16 h-16 mx-auto mb-4 text-blue-500" />
          <h1 className="text-2xl font-bold mb-2">Truy cập không hợp lệ</h1>
          <p className="text-gray-400">Vui lòng truy cập từ ứng dụng EduTrack để sử dụng chức năng này.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white flex flex-col h-screen overflow-hidden">
      {/* Top Navigation */}
      <header className="bg-gray-800/80 backdrop-blur-md border-b border-gray-700 p-4 shrink-0 flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-blue-500/20 rounded-lg">
            <BookOpen className="w-6 h-6 text-blue-400" />
          </div>
          <div>
            <h1 className="text-lg font-bold tracking-wide">TEST & QUIZ</h1>
            <p className="text-xs text-gray-400">Hệ thống Đánh giá Năng lực</p>
          </div>
        </div>
        <div className="flex items-center space-x-4">
          <div className={`px-3 py-1 rounded-full text-xs font-medium ${role === 'lecturer' ? 'bg-orange-500/20 text-orange-400 border border-orange-500/30' : 'bg-blue-500/20 text-blue-400 border border-blue-500/30'}`}>
            {role === 'lecturer' ? 'Giảng viên' : 'Sinh viên'}
          </div>
          <span className="text-sm font-medium text-gray-300">{email}</span>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex overflow-hidden">
        <Sidebar 
          courses={courses} 
          selectedCourse={selectedCourse} 
          onSelectCourse={setSelectedCourse} 
          loading={loading}
        />
        <div className="flex-1 flex flex-col bg-gray-900/50 relative">
          {selectedCourse ? (
            <TestPanel course={selectedCourse} role={role} userId={userId} email={email} />
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-gray-500">
              <BookOpen className="w-20 h-20 mb-4 opacity-20" />
              <p className="text-lg">Chọn một môn học bên trái để xem bài kiểm tra</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function App() {
  return (
    <Router>
      <Dashboard />
    </Router>
  );
}

export default App;
