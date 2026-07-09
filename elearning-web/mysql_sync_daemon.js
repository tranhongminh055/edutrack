import { initializeApp } from 'firebase/app';
import { getFirestore, collection, onSnapshot } from 'firebase/firestore';
import mysql from 'mysql2/promise';

const firebaseConfig = {
  apiKey: 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c',
  appId: '1:17492164047:web:ffd5e7de0f7508226ee6ba',
  projectId: 'edu---track',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

let pool;

function parseDate(seconds) {
  if (!seconds) return null;
  return new Date(seconds * 1000);
}

async function upsertUser(id, data) {
  const createdAt = data.createdAt?.seconds ? parseDate(data.createdAt.seconds) : null;
  await pool.execute(`
    INSERT INTO Users (Id, Email, FullName, StudentId, Role, Status, CreatedAt, Major, RawData)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      Email = VALUES(Email),
      FullName = VALUES(FullName),
      StudentId = VALUES(StudentId),
      Role = VALUES(Role),
      Status = VALUES(Status),
      CreatedAt = VALUES(CreatedAt),
      Major = VALUES(Major),
      RawData = VALUES(RawData)
  `, [
    id, data.email || null, data.fullName || 'Chưa cập nhật', data.studentId || 'Chưa có', 
    data.role || 'student', data.status || 'active', createdAt, 
    data.major || 'Chưa phân loại', JSON.stringify(data)
  ]);
}

async function upsertCourse(id, data) {
  await pool.execute(`
    INSERT INTO AvailableCourses (Id, CourseCode, CourseName, Credits, LecturerId, LecturerName, Semester, MaxSlots, CurrentSlots, Status, RawData)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      CourseCode = VALUES(CourseCode),
      CourseName = VALUES(CourseName),
      Credits = VALUES(Credits),
      LecturerId = VALUES(LecturerId),
      LecturerName = VALUES(LecturerName),
      Semester = VALUES(Semester),
      MaxSlots = VALUES(MaxSlots),
      CurrentSlots = VALUES(CurrentSlots),
      Status = VALUES(Status),
      RawData = VALUES(RawData)
  `, [
    id, data.courseId || 'N/A', data.courseName || null, data.credits || 0, 
    data.lecturerEmail || 'N/A', data.lecturerName || null, data.semester || null, 
    data.maxSlots || 40, data.currentSlots || 0, data.status || 'active', JSON.stringify(data)
  ]);
}

async function upsertRegistration(id, data) {
  const registeredAt = data.registeredAt?.seconds ? parseDate(data.registeredAt.seconds) : null;
  await pool.execute(`
    INSERT INTO Registrations (Id, StudentId, CourseDocId, Semester, Status, RegisteredAt, RawData)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      StudentId = VALUES(StudentId),
      CourseDocId = VALUES(CourseDocId),
      Semester = VALUES(Semester),
      Status = VALUES(Status),
      RegisteredAt = VALUES(RegisteredAt),
      RawData = VALUES(RawData)
  `, [
    id, data.studentId || null, data.courseDocId || null, data.semester || null, 
    data.status || 'active', registeredAt, JSON.stringify(data)
  ]);
}

async function upsertGeneric(tableName, id, data) {
  await pool.execute(`
    INSERT INTO ${tableName} (Id, RawData)
    VALUES (?, ?)
    ON DUPLICATE KEY UPDATE
      RawData = VALUES(RawData)
  `, [id, JSON.stringify(data)]);
}

async function deleteDoc(tableName, id) {
  await pool.execute(`DELETE FROM ${tableName} WHERE Id = ?`, [id]);
}

const collectionsToSync = [
  'users', 'available_courses', 'registrations', 'grades', 'invoices',
  'mail_messages', 'library_resources', 'forum_posts', 'comments',
  'notifications', 'elearning_links', 'elearning_materials',
  'elearning_assignments', 'elearning_submissions', 'elearning_quizzes',
  'elearning_quiz_attempts', 'schedules', 'system_logs'
];

async function startDaemon() {
  console.log('Khởi tạo kết nối đến MySQL...');
  try {
    pool = await mysql.createPool({
      host: '127.0.0.1',
      user: 'root',
      password: 'Hieuthi22032005',
      database: 'EduTrack',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });
    console.log('Kết nối MySQL thành công! Đang thiết lập Lắng nghe (Listeners)...');
  } catch (err) {
    console.error('Lỗi kết nối MySQL:', err.message);
    process.exit(1);
  }

  const initialLoadCompleted = new Set();

  for (const colName of collectionsToSync) {
    let tableName = colName;
    if (colName === 'users') tableName = 'Users';
    else if (colName === 'available_courses') tableName = 'AvailableCourses';
    else if (colName === 'registrations') tableName = 'Registrations';

    onSnapshot(collection(db, colName), (snapshot) => {
      snapshot.docChanges().forEach(async (change) => {
        const data = change.doc.data();
        const id = change.doc.id;

        try {
          if (change.type === 'added') {
            if (colName === 'users') await upsertUser(id, data);
            else if (colName === 'available_courses') await upsertCourse(id, data);
            else if (colName === 'registrations') await upsertRegistration(id, data);
            else await upsertGeneric(tableName, id, data);

            if (initialLoadCompleted.has(colName)) {
              console.log(`[MYSQL-SYNC] [${tableName}] THÊM MỚI: ${id}`);
            }
          }
          if (change.type === 'modified') {
            if (colName === 'users') await upsertUser(id, data);
            else if (colName === 'available_courses') await upsertCourse(id, data);
            else if (colName === 'registrations') await upsertRegistration(id, data);
            else await upsertGeneric(tableName, id, data);
            console.log(`[MYSQL-SYNC] [${tableName}] CẬP NHẬT: ${id}`);
          }
          if (change.type === 'removed') {
            await deleteDoc(tableName, id);
            console.log(`[MYSQL-SYNC] [${tableName}] ĐÃ XÓA: ${id}`);
          }
        } catch (err) {
          console.error(`[LỖI] khi đồng bộ document ${id} thuộc ${tableName}:`, err.message);
        }
      });

      initialLoadCompleted.add(colName);
    }, (error) => {
      console.error(`Lỗi listener ở collection ${colName}:`, error);
    });
  }

  console.log('====================================================');
  console.log('🚀 MYSQL REAL-TIME DAEMON ĐANG CHẠY!');
  console.log('Tiến trình này sẽ lắng nghe Firebase và đẩy vào MySQL 24/7.');
  console.log('====================================================');
}

startDaemon();
