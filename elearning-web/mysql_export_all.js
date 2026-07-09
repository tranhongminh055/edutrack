import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import mysql from 'mysql2/promise';

const firebaseConfig = {
  apiKey: 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c',
  appId: '1:17492164047:web:ffd5e7de0f7508226ee6ba',
  projectId: 'edu---track',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

function parseDate(seconds) {
  if (!seconds) return null;
  return new Date(seconds * 1000);
}

const collectionsToExport = [
  'users', 'available_courses', 'registrations', 'grades', 'invoices',
  'mail_messages', 'library_resources', 'forum_posts', 'comments',
  'notifications', 'elearning_links', 'elearning_materials',
  'elearning_assignments', 'elearning_submissions', 'elearning_quizzes',
  'elearning_quiz_attempts', 'schedules', 'system_logs'
];

async function exportAllToMySql() {
  console.log('Đang kết nối đến MySQL...');
  const conn = await mysql.createConnection({
    host: '127.0.0.1',
    user: 'root',
    password: 'Hieuthi22032005'
  });

  await conn.query('CREATE DATABASE IF NOT EXISTS EduTrack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
  await conn.query('USE EduTrack;');
  console.log('Đã chọn Database EduTrack.');

  for (const colName of collectionsToExport) {
    const snap = await getDocs(collection(db, colName));
    console.log(`Fetched ${snap.size} documents from collection: ${colName}`);
    if (snap.size === 0) continue;

    if (colName === 'users') {
      await conn.query(`
        CREATE TABLE IF NOT EXISTS Users (
            Id VARCHAR(100) PRIMARY KEY,
            Email VARCHAR(255),
            FullName VARCHAR(255),
            StudentId VARCHAR(100),
            Role VARCHAR(50),
            Status VARCHAR(50),
            CreatedAt DATETIME,
            Major VARCHAR(255),
            RawData JSON
        )
      `);
      // Clear old data for a fresh export
      await conn.query('TRUNCATE TABLE Users');

      for (const doc of snap.docs) {
        const data = doc.data();
        const createdAt = data.createdAt?.seconds ? parseDate(data.createdAt.seconds) : null;
        await conn.execute(
          'INSERT INTO Users (Id, Email, FullName, StudentId, Role, Status, CreatedAt, Major, RawData) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [doc.id, data.email || null, data.fullName || 'Chưa cập nhật', data.studentId || 'Chưa có', data.role || 'student', data.status || 'active', createdAt, data.major || 'Chưa phân loại', JSON.stringify(data)]
        );
      }
    } 
    else if (colName === 'available_courses') {
      await conn.query(`
        CREATE TABLE IF NOT EXISTS AvailableCourses (
            Id VARCHAR(100) PRIMARY KEY,
            CourseCode VARCHAR(100),
            CourseName VARCHAR(255),
            Credits INT,
            LecturerId VARCHAR(100),
            LecturerName VARCHAR(255),
            Semester VARCHAR(100),
            MaxSlots INT,
            CurrentSlots INT,
            Status VARCHAR(50),
            RawData JSON
        )
      `);
      await conn.query('TRUNCATE TABLE AvailableCourses');

      for (const doc of snap.docs) {
        const data = doc.data();
        await conn.execute(
          'INSERT INTO AvailableCourses (Id, CourseCode, CourseName, Credits, LecturerId, LecturerName, Semester, MaxSlots, CurrentSlots, Status, RawData) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [doc.id, data.courseId || 'N/A', data.courseName || null, data.credits || 0, data.lecturerEmail || 'N/A', data.lecturerName || null, data.semester || null, data.maxSlots || 40, data.currentSlots || 0, data.status || 'active', JSON.stringify(data)]
        );
      }
    }
    else if (colName === 'registrations') {
      await conn.query(`
        CREATE TABLE IF NOT EXISTS Registrations (
            Id VARCHAR(100) PRIMARY KEY,
            StudentId VARCHAR(100),
            CourseDocId VARCHAR(100),
            Semester VARCHAR(100),
            Status VARCHAR(50),
            RegisteredAt DATETIME,
            RawData JSON
        )
      `);
      await conn.query('TRUNCATE TABLE Registrations');

      for (const doc of snap.docs) {
        const data = doc.data();
        const registeredAt = data.registeredAt?.seconds ? parseDate(data.registeredAt.seconds) : null;
        await conn.execute(
          'INSERT INTO Registrations (Id, StudentId, CourseDocId, Semester, Status, RegisteredAt, RawData) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [doc.id, data.studentId || null, data.courseDocId || null, data.semester || null, data.status || 'active', registeredAt, JSON.stringify(data)]
        );
      }
    }
    else {
      const tableName = colName;
      await conn.query(`
        CREATE TABLE IF NOT EXISTS ${tableName} (
            Id VARCHAR(100) PRIMARY KEY,
            RawData JSON
        )
      `);
      await conn.query(`TRUNCATE TABLE ${tableName}`);

      for (const doc of snap.docs) {
        await conn.execute(
          `INSERT INTO ${tableName} (Id, RawData) VALUES (?, ?)`,
          [doc.id, JSON.stringify(doc.data())]
        );
      }
    }
  }

  console.log('Thành công! Toàn bộ dữ liệu đã được xuất thẳng vào MySQL.');
  await conn.end();
  process.exit(0);
}

exportAllToMySql().catch(err => {
  console.error('Lỗi khi chạy export:', err);
  process.exit(1);
});
