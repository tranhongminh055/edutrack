import React, { useState, useEffect } from 'react';
import './App.css';
import { BrowserRouter as Router, useSearchParams } from 'react-router-dom';
import { collection, query, where, onSnapshot, getDoc, getDocs, doc } from 'firebase/firestore';
import { db } from './firebase';
import Sidebar from './components/Sidebar';
import HomeView from './components/HomeView';
import DashboardView from './components/DashboardView';
import CalendarView from './components/CalendarView';
import AnnouncementsView from './components/AnnouncementsView';
import ResourcesView from './components/ResourcesView';
import MembershipView from './components/MembershipView';
import PreferencesView from './components/PreferencesView';
import AccountView from './components/AccountView';
import WorksiteSetupView from './components/WorksiteSetupView';
import AllSitesModal from './components/AllSitesModal';
import CourseHomeView from './components/CourseHomeView';
import TestPanel from './components/TestPanel';
import SyllabusView from './components/SyllabusView';
import CourseCalendarView from './components/CourseCalendarView';
import LessonsView from './components/LessonsView';
import CourseAnnouncementsView from './components/CourseAnnouncementsView';
import CourseResourcesView from './components/CourseResourcesView';
import CourseAssignmentsView from './components/CourseAssignmentsView';
import GradebookView from './components/GradebookView';
import StudentRosterView from './components/StudentRosterView';
import LecturerEvaluationView from './components/LecturerEvaluationView';
import ForumView from './components/ForumView';
import { BookOpen, Loader2 } from 'lucide-react';

function ELearningApp() {
  const [searchParams] = useSearchParams();
  const userId = searchParams.get('userId');
  const role = searchParams.get('role');
  const email = searchParams.get('email');

  const [courses, setCourses] = useState([]);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showAllSitesModal, setShowAllSitesModal] = useState(false);
  const [currentView, setCurrentView] = useState('overview');

  useEffect(() => {
    const viewParam = searchParams.get('view');
    if (viewParam) {
      setCurrentView(viewParam);
    }
  }, [searchParams]);

  useEffect(() => {
    if (!userId && !email) { setLoading(false); return; }

    if (role === 'student') {
      const q = query(collection(db, 'registrations'), where('userId', '==', userId));
      const unsubscribe = onSnapshot(q, async (snapshot) => {
        const courseMap = new Map();
        snapshot.docs.forEach(doc => {
          const data = doc.data();
          const key = data.courseDocId;
          if (!courseMap.has(key)) {
            courseMap.set(key, {
              docId: data.courseDocId,
              courseName: data.courseName,
              courseId: data.courseId,
              classGroup: data.classGroup,
              lecturerName: data.lecturerName || '',
              lecturerEmail: data.lecturerEmail || '',
              major: data.major || '',
              semester: data.semester || '',
              academicYear: data.academicYear || '',
              dayOfWeek: data.dayOfWeek || 0,
              startHour: data.startHour || 0,
              duration: data.duration || 0,
              room: data.room || '',
              studentCount: 1,
              hasGrade: false,
            });
          } else {
            courseMap.get(key).studentCount += 1;
          }
        });

        // Check for grades for each course
        const coursesWithGrades = Array.from(courseMap.values());
        for (const course of coursesWithGrades) {
          // Check registration grades
          const regDoc = await getDoc(doc(db, 'registrations', `${userId}_${course.docId}`));
          if (regDoc.exists()) {
            const regData = regDoc.data();
            if (regData.attendanceScore !== undefined || regData.midtermScore !== undefined || regData.finalScore !== undefined) {
              course.hasGrade = true;
              continue;
            }
          }

          // Check quiz submissions
          const qQuiz = query(collection(db, 'quiz_submissions'), where('courseDocId', '==', course.docId), where('studentEmail', '==', email));
          const quizSnap = await getDocs(qQuiz);
          if (!quizSnap.empty) {
            course.hasGrade = true;
            continue;
          }

          // Check assignment submissions
          const qAssign = query(collection(db, 'elearning_submissions'), where('courseDocId', '==', course.docId), where('userEmail', '==', email));
          const assignSnap = await getDocs(qAssign);
          if (!assignSnap.empty) {
            course.hasGrade = true;
          }
        }

        setCourses(coursesWithGrades);
        setLoading(false);
      }, (error) => {
        console.error('Error fetching courses:', error);
        setLoading(false);
      });
      return () => unsubscribe();
    } else {
      let activeCourses = [];
      let activeRegistrations = [];

      const updateLecturerCourses = () => {
        const regCounts = {};
        activeRegistrations.forEach(reg => {
          const courseDocId = reg.courseDocId;
          regCounts[courseDocId] = (regCounts[courseDocId] || 0) + 1;
        });

        const mapped = activeCourses.map(c => ({
          docId: c.id,
          courseName: c.courseName,
          courseId: c.courseId,
          classGroup: c.classGroup,
          lecturerName: c.lecturerName || '',
          lecturerEmail: c.lecturerEmail || '',
          major: c.major || '',
          semester: c.semester || '',
          academicYear: c.academicYear || '',
          dayOfWeek: c.dayOfWeek || 0,
          startHour: c.startHour || 0,
          duration: c.duration || 0,
          room: c.room || '',
          studentCount: regCounts[c.id] || 0,
        }));
        setCourses(mapped);
        setLoading(false);
      };

      const qCourses = query(collection(db, 'available_courses'), where('lecturerEmail', '==', email));
      const qRegs = query(collection(db, 'registrations'), where('lecturerEmail', '==', email));

      const unsubCourses = onSnapshot(qCourses, (snap) => {
        activeCourses = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        updateLecturerCourses();
      }, (error) => {
        console.error('Error fetching lecturer courses:', error);
        setLoading(false);
      });

      const unsubRegs = onSnapshot(qRegs, (snap) => {
        activeRegistrations = snap.docs.map(d => d.data());
        updateLecturerCourses();
      }, (error) => {
        console.error('Error fetching registrations:', error);
      });

      return () => {
        unsubCourses();
        unsubRegs();
      };
    }
  }, [userId, role, email]);

  const handleSelectCourse = (course) => {
    setSelectedCourse(course);
    setCurrentView('course');
  };

  const handleNavClick = (viewId) => {
    // Only clear selectedCourse when navigating to a non-course view
    if (!viewId.startsWith('course')) {
      setSelectedCourse(null);
    }
    setCurrentView(viewId);
  };

  if (!userId && !email) {
    return (
      <div className="invalid-access">
        <div className="invalid-access-card">
          <BookOpen style={{width: 56, height: 56, color: '#3b82f6', margin: '0 auto'}} />
          <h1>Truy cập không hợp lệ</h1>
          <p>Vui lòng truy cập từ ứng dụng EduTrack để sử dụng chức năng E-Learning.</p>
        </div>
      </div>
    );
  }

  const renderContent = () => {
    if (loading) {
      return (
        <div className="loading-spinner">
          <Loader2 style={{width: 40, height: 40, color: '#3b82f6'}} />
          <span>Đang tải dữ liệu...</span>
        </div>
      );
    }

    switch (currentView) {
      case 'overview':
        return <HomeView courses={courses} role={role} email={email} onSelectCourse={handleSelectCourse} />;
      case 'dashboard':
        return <DashboardView courses={courses} role={role} email={email} onSelectCourse={handleSelectCourse} />;
      case 'calendar':
        return <CalendarView courses={courses} />;
      case 'announcements':
        return <AnnouncementsView courses={courses} role={role} email={email} />;
      case 'resources':
        return <ResourcesView courses={courses} role={role} email={email} />;
      case 'membership':
        return <MembershipView courses={courses} role={role} email={email} />;
      case 'worksite_setup':
        return <WorksiteSetupView courses={courses} role={role} />;
      case 'preferences':
        return <PreferencesView email={email} role={role} />;
      case 'account':
        return <AccountView email={email} role={role} />;
      case 'course':
      case 'course_home':
        return selectedCourse ? (
          <CourseHomeView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'course_tests':
        return selectedCourse ? (
          <TestPanel course={selectedCourse} role={role} userId={userId} email={email} />
        ) : null;
      case 'course_syllabus':
        return selectedCourse ? (
          <SyllabusView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'course_calendar':
        return selectedCourse ? (
          <CourseCalendarView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'course_lessons':
        return selectedCourse ? (
          <LessonsView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'course_announcements':
        return selectedCourse ? (
          <CourseAnnouncementsView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'course_resources':
        return selectedCourse ? (
          <CourseResourcesView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'course_assignments':
        return selectedCourse ? (
          <CourseAssignmentsView course={selectedCourse} role={role} email={email} userId={userId} />
        ) : null;
      case 'course_gradebook':
        return selectedCourse ? (
          <GradebookView course={selectedCourse} role={role} email={email} userId={userId} />
        ) : null;
      case 'course_roster':
        return selectedCourse ? (
          <StudentRosterView course={selectedCourse} role={role} email={email} />
        ) : null;
      case 'forum':
        return <ForumView />;
      case 'lecturer_evaluation':
        return <LecturerEvaluationView role={role} email={email} />;
      default:
        return <HomeView courses={courses} role={role} email={email} onSelectCourse={handleSelectCourse} />;
    }
  };

  // Forum is standalone, not part of e-learning layout
  if (currentView === 'forum') {
    return <ForumView />;
  }

  return (
    <div className="app-container">
      <header className="top-header">
        <div className="brand" onClick={() => handleNavClick('overview')} style={{ cursor: 'pointer' }}>
          <div className="brand-icon">
            <BookOpen style={{width: 20, height: 20, color: 'white'}} />
          </div>
          <div>
            <div className="brand-name">E-LEARNING</div>
            <div className="brand-sub">Hệ thống Quản lý Học tập Trực tuyến</div>
          </div>
        </div>
        <div className="user-info">
          <span className={`role-badge ${role}`}>
            {role === 'lecturer' ? '👨‍🏫 Giảng viên' : '🎓 Sinh viên'}
          </span>
          <span className="user-email">{email}</span>
        </div>
      </header>

      <div className="main-layout">
        <Sidebar
          courses={courses}
          selectedCourse={selectedCourse}
          onSelectCourse={handleSelectCourse}
          onNavClick={handleNavClick}
          onViewAllSites={() => setShowAllSitesModal(true)}
          currentView={currentView}
          loading={loading}
          role={role}
        />
        <div className="content-area custom-scrollbar">
          {renderContent()}
        </div>
      </div>
      
      {showAllSitesModal && (
        <AllSitesModal 
          courses={courses}
          onClose={() => setShowAllSitesModal(false)}
          onSelectCourse={(c) => {
            handleSelectCourse(c);
            if (!c) handleNavClick('overview');
          }}
        />
      )}
    </div>
  );
}

function App() {
  return (
    <Router>
      <ELearningApp />
    </Router>
  );
}

export default App;
