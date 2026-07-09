import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import fs from 'fs';
import { execSync } from 'child_process';

const firebaseConfig = {
  apiKey: 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c',
  appId: '1:17492164047:web:ffd5e7de0f7508226ee6ba',
  projectId: 'edu---track',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

function escapeSql(str, defaultVal = 'NULL') {
  if (str === null || str === undefined || str === '') return defaultVal;
  if (typeof str === 'boolean') return str ? 1 : 0;
  if (typeof str === 'number') return str;
  if (typeof str === 'object') {
    if (str.seconds) {
      const d = new Date(str.seconds * 1000);
      return `'${d.toISOString()}'`;
    }
    return `N'${JSON.stringify(str).replace(/'/g, "''")}'`;
  }
  return `N'${String(str).replace(/'/g, "''")}'`;
}

const collectionsToExport = [
  'users',
  'available_courses',
  'registrations',
  'grades',
  'invoices',
  'mail_messages',
  'library_resources',
  'forum_posts',
  'comments',
  'notifications',
  'elearning_links',
  'elearning_materials',
  'elearning_assignments',
  'elearning_submissions',
  'elearning_quizzes',
  'elearning_quiz_attempts',
  'schedules',
  'system_logs'
];

async function exportAllToSql() {
  console.log('Bắt đầu xuất dữ liệu từ Firestore...');
  let sqlContent = `-- Auto-generated SQL Export from Firestore\nUSE EduTrack;\nGO\n\n`;

  for (const colName of collectionsToExport) {
    const snap = await getDocs(collection(db, colName));
    console.log(`Fetched ${snap.size} documents from collection: ${colName}`);
    
    if (snap.size === 0) continue; // Skip empty collections

    if (colName === 'users') {
      sqlContent += `
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
CREATE TABLE Users (
    Id VARCHAR(100) PRIMARY KEY,
    Email NVARCHAR(255),
    FullName NVARCHAR(255),
    StudentId NVARCHAR(100),
    Role NVARCHAR(50),
    Status NVARCHAR(50),
    CreatedAt DATETIME,
    Major NVARCHAR(255),
    RawData NVARCHAR(MAX)
);
GO\n`;
      for (const doc of snap.docs) {
        const data = doc.data();
        sqlContent += `INSERT INTO Users (Id, Email, FullName, StudentId, Role, Status, CreatedAt, Major, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data.email)}, ${escapeSql(data.fullName, "N'Chưa cập nhật'")}, ${escapeSql(data.studentId, "N'Chưa có'")}, ${escapeSql(data.role, "N'student'")}, ${escapeSql(data.status, "N'active'")}, ${escapeSql(data.createdAt)}, ${escapeSql(data.major, "N'Chưa phân loại'")}, ${escapeSql(data)});\n`;
      }
      sqlContent += 'GO\n\n';
    } 
    else if (colName === 'available_courses') {
      sqlContent += `
IF OBJECT_ID('AvailableCourses', 'U') IS NOT NULL DROP TABLE AvailableCourses;
CREATE TABLE AvailableCourses (
    Id VARCHAR(100) PRIMARY KEY,
    CourseCode NVARCHAR(100),
    CourseName NVARCHAR(255),
    Credits INT,
    LecturerId NVARCHAR(100),
    LecturerName NVARCHAR(255),
    Semester NVARCHAR(100),
    MaxSlots INT,
    CurrentSlots INT,
    Status NVARCHAR(50),
    RawData NVARCHAR(MAX)
);
GO\n`;
      for (const doc of snap.docs) {
        const data = doc.data();
        sqlContent += `INSERT INTO AvailableCourses (Id, CourseCode, CourseName, Credits, LecturerId, LecturerName, Semester, MaxSlots, CurrentSlots, Status, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data.courseId, "N'N/A'")}, ${escapeSql(data.courseName)}, ${escapeSql(data.credits, "0")}, ${escapeSql(data.lecturerEmail, "N'N/A'")}, ${escapeSql(data.lecturerName)}, ${escapeSql(data.semester)}, ${escapeSql(data.maxSlots, "40")}, ${escapeSql(data.currentSlots, "0")}, ${escapeSql(data.status, "N'active'")}, ${escapeSql(data)});\n`;
      }
      sqlContent += 'GO\n\n';
    }
    else if (colName === 'registrations') {
      sqlContent += `
IF OBJECT_ID('Registrations', 'U') IS NOT NULL DROP TABLE Registrations;
CREATE TABLE Registrations (
    Id VARCHAR(100) PRIMARY KEY,
    StudentId NVARCHAR(100),
    CourseDocId VARCHAR(100),
    Semester NVARCHAR(100),
    Status NVARCHAR(50),
    RegisteredAt DATETIME,
    RawData NVARCHAR(MAX)
);
GO\n`;
      for (const doc of snap.docs) {
        const data = doc.data();
        sqlContent += `INSERT INTO Registrations (Id, StudentId, CourseDocId, Semester, Status, RegisteredAt, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data.studentId)}, ${escapeSql(data.courseDocId)}, ${escapeSql(data.semester)}, ${escapeSql(data.status, "N'active'")}, ${escapeSql(data.registeredAt)}, ${escapeSql(data)});\n`;
      }
      sqlContent += 'GO\n\n';
    }
    else {
      // Generic tables for all other collections
      const tableName = colName;
      sqlContent += `
IF OBJECT_ID('${tableName}', 'U') IS NOT NULL DROP TABLE ${tableName};
CREATE TABLE ${tableName} (
    Id VARCHAR(100) PRIMARY KEY,
    RawData NVARCHAR(MAX)
);
GO\n`;
      for (const doc of snap.docs) {
        const data = doc.data();
        sqlContent += `INSERT INTO ${tableName} (Id, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data)});\n`;
      }
      sqlContent += 'GO\n\n';
    }
  }

  // Write to export_all.sql with UTF-8 BOM so sqlcmd and SSMS can read it properly
  const sqlFilePath = 'export_all.sql';
  fs.writeFileSync(sqlFilePath, '\\uFEFF' + sqlContent, 'utf8');
  console.log(`Đã tạo file SQL tại ${sqlFilePath}. Kích thước: ${sqlContent.length} bytes.`);

  // Execute using sqlcmd with UTF-8 encoding flag (-f 65001)
  console.log('Đang thực thi lệnh sqlcmd để đổ dữ liệu vào SQL Server...');
  try {
    execSync('sqlcmd -S .\\\\SQLEXPRESS -d EduTrack -E -f 65001 -i export_all.sql', { stdio: 'inherit' });
    console.log('Thành công! Toàn bộ dữ liệu đã được đưa vào SQL Server.');
  } catch (err) {
    console.error('Lỗi khi chạy sqlcmd:', err.message);
  }
}

exportAllToSql().catch(console.error);
