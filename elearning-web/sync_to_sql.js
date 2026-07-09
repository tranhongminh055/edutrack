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

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
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

async function exportToSql() {
  console.log('Starting export from Firestore...');
  let sqlContent = `-- Auto-generated SQL Export from Firestore\n\n`;

  // 1. Users table
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
GO
`;

  const usersSnap = await getDocs(collection(db, 'users'));
  console.log(`Fetched ${usersSnap.size} users.`);
  for (const doc of usersSnap.docs) {
    const data = doc.data();
    sqlContent += `INSERT INTO Users (Id, Email, FullName, StudentId, Role, Status, CreatedAt, Major, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data.email)}, ${escapeSql(data.fullName)}, ${escapeSql(data.studentId)}, ${escapeSql(data.role)}, ${escapeSql(data.status)}, ${escapeSql(data.createdAt)}, ${escapeSql(data.major)}, ${escapeSql(data)});\n`;
  }
  sqlContent += 'GO\n\n';

  // 2. Available Courses
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
GO
`;
  const coursesSnap = await getDocs(collection(db, 'available_courses'));
  console.log(`Fetched ${coursesSnap.size} courses.`);
  for (const doc of coursesSnap.docs) {
    const data = doc.data();
    sqlContent += `INSERT INTO AvailableCourses (Id, CourseCode, CourseName, Credits, LecturerId, LecturerName, Semester, MaxSlots, CurrentSlots, Status, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data.courseCode)}, ${escapeSql(data.courseName)}, ${escapeSql(data.credits)}, ${escapeSql(data.lecturerId)}, ${escapeSql(data.lecturerName)}, ${escapeSql(data.semester)}, ${escapeSql(data.maxSlots)}, ${escapeSql(data.currentSlots)}, ${escapeSql(data.status)}, ${escapeSql(data)});\n`;
  }
  sqlContent += 'GO\n\n';

  // 3. Registrations
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
GO
`;
  const regSnap = await getDocs(collection(db, 'registrations'));
  console.log(`Fetched ${regSnap.size} registrations.`);
  for (const doc of regSnap.docs) {
    const data = doc.data();
    sqlContent += `INSERT INTO Registrations (Id, StudentId, CourseDocId, Semester, Status, RegisteredAt, RawData) VALUES (${escapeSql(doc.id)}, ${escapeSql(data.studentId)}, ${escapeSql(data.courseDocId)}, ${escapeSql(data.semester)}, ${escapeSql(data.status)}, ${escapeSql(data.registeredAt)}, ${escapeSql(data)});\n`;
  }
  sqlContent += 'GO\n\n';

  // Write to export.sql
  const sqlFilePath = 'export.sql';
  fs.writeFileSync(sqlFilePath, sqlContent);
  console.log(`SQL file generated at ${sqlFilePath}. Size: ${sqlContent.length} bytes.`);

  // Execute using sqlcmd
  console.log('Executing SQL script to import data into SQL Server (EduTrack)...');
  try {
    execSync('sqlcmd -S localhost\\\\SQLEXPRESS -d EduTrack -E -i export.sql', { stdio: 'inherit' });
    console.log('Successfully imported data into SQL Server!');
  } catch (err) {
    console.error('Failed to execute sqlcmd. Make sure SQL Server is running and accessible.');
  }
}

exportToSql().catch(console.error);
