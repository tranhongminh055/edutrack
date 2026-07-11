import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import sql from 'mssql';

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

// Cấu hình SQL Server
const sqlConfig = {
  user: 'sa', 
  password: '123456', 
  server: '127.0.0.1', 
  port: 1433,
  database: 'EduTrack',
  options: {
    encrypt: false, 
    trustServerCertificate: true
  }
};

async function exportAllToSqlServer() {
  console.log('Đang kết nối đến SQL Server...');

  // Kết nối ban đầu đến master để tạo DB nếu chưa có
  const masterConfig = { ...sqlConfig, database: 'master' };
  let pool = await sql.connect(masterConfig);

  const checkDb = await pool.request().query("SELECT name FROM sys.databases WHERE name = N'EduTrack'");
  if (checkDb.recordset.length === 0) {
    await pool.request().query("CREATE DATABASE EduTrack");
    console.log('Đã tạo Database EduTrack mới.');
  }
  await pool.close();

  // Kết nối lại vào database EduTrack
  pool = await sql.connect(sqlConfig);
  console.log('Đã chọn Database EduTrack.');

  for (const colName of collectionsToExport) {
    const snap = await getDocs(collection(db, colName));
    console.log(`Fetched ${snap.size} documents from collection: ${colName}`);
    if (snap.size === 0) continue;

    if (colName === 'users') {
      await pool.request().query(`
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' and xtype='U')
        CREATE TABLE Users (
            Id VARCHAR(100) PRIMARY KEY,
            Email NVARCHAR(255),
            FullName NVARCHAR(255),
            StudentId VARCHAR(100),
            Role VARCHAR(50),
            Status VARCHAR(50),
            CreatedAt DATETIME,
            Major NVARCHAR(255),
            RawData NVARCHAR(MAX)
        )
      `);
      await pool.request().query('TRUNCATE TABLE Users');

      for (const doc of snap.docs) {
        const data = doc.data();
        const createdAt = data.createdAt?.seconds ? parseDate(data.createdAt.seconds) : null;

        await pool.request()
          .input('Id', sql.VarChar, doc.id)
          .input('Email', sql.NVarChar, data.email || null)
          .input('FullName', sql.NVarChar, data.fullName || 'Chưa cập nhật')
          .input('StudentId', sql.VarChar, data.studentId || 'Chưa có')
          .input('Role', sql.VarChar, data.role || 'student')
          .input('Status', sql.VarChar, data.status || 'active')
          .input('CreatedAt', sql.DateTime, createdAt)
          .input('Major', sql.NVarChar, data.major || 'Chưa phân loại')
          .input('RawData', sql.NVarChar, JSON.stringify(data))
          .query('INSERT INTO Users (Id, Email, FullName, StudentId, Role, Status, CreatedAt, Major, RawData) VALUES (@Id, @Email, @FullName, @StudentId, @Role, @Status, @CreatedAt, @Major, @RawData)');
      }
    }
    else if (colName === 'available_courses') {
      await pool.request().query(`
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AvailableCourses' and xtype='U')
        CREATE TABLE AvailableCourses (
            Id VARCHAR(100) PRIMARY KEY,
            CourseCode VARCHAR(100),
            CourseName NVARCHAR(255),
            Credits INT,
            LecturerId VARCHAR(100),
            LecturerName NVARCHAR(255),
            Semester VARCHAR(100),
            MaxSlots INT,
            CurrentSlots INT,
            Status VARCHAR(50),
            RawData NVARCHAR(MAX)
        )
      `);
      await pool.request().query('TRUNCATE TABLE AvailableCourses');

      for (const doc of snap.docs) {
        const data = doc.data();
        await pool.request()
          .input('Id', sql.VarChar, doc.id)
          .input('CourseCode', sql.VarChar, data.courseId || 'N/A')
          .input('CourseName', sql.NVarChar, data.courseName || null)
          .input('Credits', sql.Int, data.credits || 0)
          .input('LecturerId', sql.VarChar, data.lecturerEmail || 'N/A')
          .input('LecturerName', sql.NVarChar, data.lecturerName || null)
          .input('Semester', sql.VarChar, data.semester || null)
          .input('MaxSlots', sql.Int, data.maxSlots || 40)
          .input('CurrentSlots', sql.Int, data.currentSlots || 0)
          .input('Status', sql.VarChar, data.status || 'active')
          .input('RawData', sql.NVarChar, JSON.stringify(data))
          .query('INSERT INTO AvailableCourses (Id, CourseCode, CourseName, Credits, LecturerId, LecturerName, Semester, MaxSlots, CurrentSlots, Status, RawData) VALUES (@Id, @CourseCode, @CourseName, @Credits, @LecturerId, @LecturerName, @Semester, @MaxSlots, @CurrentSlots, @Status, @RawData)');
      }
    }
    else if (colName === 'registrations') {
      await pool.request().query(`
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Registrations' and xtype='U')
        CREATE TABLE Registrations (
            Id VARCHAR(100) PRIMARY KEY,
            StudentId VARCHAR(100),
            CourseDocId VARCHAR(100),
            Semester VARCHAR(100),
            Status VARCHAR(50),
            RegisteredAt DATETIME,
            RawData NVARCHAR(MAX)
        )
      `);
      await pool.request().query('TRUNCATE TABLE Registrations');

      for (const doc of snap.docs) {
        const data = doc.data();
        const registeredAt = data.registeredAt?.seconds ? parseDate(data.registeredAt.seconds) : null;
        await pool.request()
          .input('Id', sql.VarChar, doc.id)
          .input('StudentId', sql.VarChar, data.studentId || null)
          .input('CourseDocId', sql.VarChar, data.courseDocId || null)
          .input('Semester', sql.VarChar, data.semester || null)
          .input('Status', sql.VarChar, data.status || 'active')
          .input('RegisteredAt', sql.DateTime, registeredAt)
          .input('RawData', sql.NVarChar, JSON.stringify(data))
          .query('INSERT INTO Registrations (Id, StudentId, CourseDocId, Semester, Status, RegisteredAt, RawData) VALUES (@Id, @StudentId, @CourseDocId, @Semester, @Status, @RegisteredAt, @RawData)');
      }
    }
    else {
      const tableName = colName;
      await pool.request().query(`
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='${tableName}' and xtype='U')
        CREATE TABLE ${tableName} (
            Id VARCHAR(100) PRIMARY KEY,
            RawData NVARCHAR(MAX)
        )
      `);
      await pool.request().query(`TRUNCATE TABLE ${tableName}`);

      for (const doc of snap.docs) {
        await pool.request()
          .input('Id', sql.VarChar, doc.id)
          .input('RawData', sql.NVarChar, JSON.stringify(doc.data()))
          .query(`INSERT INTO ${tableName} (Id, RawData) VALUES (@Id, @RawData)`);
      }
    }
  }

  console.log('Thành công! Toàn bộ dữ liệu đã được xuất thẳng vào SQL Server.');
  await pool.close();
  process.exit(0);
}

exportAllToSqlServer().catch(err => {
  console.error('Lỗi khi chạy export:', err);
  process.exit(1);
});
