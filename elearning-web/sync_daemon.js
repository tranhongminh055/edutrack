import { initializeApp } from 'firebase/app';
import { getFirestore, collection, onSnapshot } from 'firebase/firestore';
import sql from 'mssql/msnodesqlv8.js';

const firebaseConfig = {
  apiKey: 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c',
  appId: '1:17492164047:web:ffd5e7de0f7508226ee6ba',
  projectId: 'edu---track',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const sqlConfig = {
  server: 'localhost,1433',
  database: 'EduTrack',
  driver: 'ODBC Driver 17 for SQL Server',
  options: {
    trustedConnection: true
  }
};

let pool;

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

async function upsertUser(id, data) {
  const q = `
    IF EXISTS (SELECT 1 FROM Users WHERE Id = '${id}')
      UPDATE Users SET Email = ${escapeSql(data.email)}, FullName = ${escapeSql(data.fullName, "N'Chưa cập nhật'")}, StudentId = ${escapeSql(data.studentId, "N'Chưa có'")}, Role = ${escapeSql(data.role, "N'student'")}, Status = ${escapeSql(data.status, "N'active'")}, CreatedAt = ${escapeSql(data.createdAt)}, Major = ${escapeSql(data.major, "N'Chưa phân loại'")}, RawData = ${escapeSql(data)} WHERE Id = '${id}';
    ELSE
      INSERT INTO Users (Id, Email, FullName, StudentId, Role, Status, CreatedAt, Major, RawData) VALUES ('${id}', ${escapeSql(data.email)}, ${escapeSql(data.fullName, "N'Chưa cập nhật'")}, ${escapeSql(data.studentId, "N'Chưa có'")}, ${escapeSql(data.role, "N'student'")}, ${escapeSql(data.status, "N'active'")}, ${escapeSql(data.createdAt)}, ${escapeSql(data.major, "N'Chưa phân loại'")}, ${escapeSql(data)});
  `;
  await pool.request().query(q);
}

async function upsertCourse(id, data) {
  const q = `
    IF EXISTS (SELECT 1 FROM AvailableCourses WHERE Id = '${id}')
      UPDATE AvailableCourses SET CourseCode = ${escapeSql(data.courseId, "N'N/A'")}, CourseName = ${escapeSql(data.courseName)}, Credits = ${escapeSql(data.credits, "0")}, LecturerId = ${escapeSql(data.lecturerEmail, "N'N/A'")}, LecturerName = ${escapeSql(data.lecturerName)}, Semester = ${escapeSql(data.semester)}, MaxSlots = ${escapeSql(data.maxSlots, "40")}, CurrentSlots = ${escapeSql(data.currentSlots, "0")}, Status = ${escapeSql(data.status, "N'active'")}, RawData = ${escapeSql(data)} WHERE Id = '${id}';
    ELSE
      INSERT INTO AvailableCourses (Id, CourseCode, CourseName, Credits, LecturerId, LecturerName, Semester, MaxSlots, CurrentSlots, Status, RawData) VALUES ('${id}', ${escapeSql(data.courseId, "N'N/A'")}, ${escapeSql(data.courseName)}, ${escapeSql(data.credits, "0")}, ${escapeSql(data.lecturerEmail, "N'N/A'")}, ${escapeSql(data.lecturerName)}, ${escapeSql(data.semester)}, ${escapeSql(data.maxSlots, "40")}, ${escapeSql(data.currentSlots, "0")}, ${escapeSql(data.status, "N'active'")}, ${escapeSql(data)});
  `;
  await pool.request().query(q);
}

async function upsertRegistration(id, data) {
  const q = `
    IF EXISTS (SELECT 1 FROM Registrations WHERE Id = '${id}')
      UPDATE Registrations SET StudentId = ${escapeSql(data.studentId)}, CourseDocId = ${escapeSql(data.courseDocId)}, Semester = ${escapeSql(data.semester)}, Status = ${escapeSql(data.status, "N'active'")}, RegisteredAt = ${escapeSql(data.registeredAt)}, RawData = ${escapeSql(data)} WHERE Id = '${id}';
    ELSE
      INSERT INTO Registrations (Id, StudentId, CourseDocId, Semester, Status, RegisteredAt, RawData) VALUES ('${id}', ${escapeSql(data.studentId)}, ${escapeSql(data.courseDocId)}, ${escapeSql(data.semester)}, ${escapeSql(data.status, "N'active'")}, ${escapeSql(data.registeredAt)}, ${escapeSql(data)});
  `;
  await pool.request().query(q);
}

async function upsertGeneric(tableName, id, data) {
  const q = `
    IF EXISTS (SELECT 1 FROM ${tableName} WHERE Id = '${id}')
      UPDATE ${tableName} SET RawData = ${escapeSql(data)} WHERE Id = '${id}';
    ELSE
      INSERT INTO ${tableName} (Id, RawData) VALUES ('${id}', ${escapeSql(data)});
  `;
  await pool.request().query(q);
}

async function deleteDoc(tableName, id) {
  const q = `DELETE FROM ${tableName} WHERE Id = '${id}';`;
  await pool.request().query(q);
}

const collectionsToSync = [
  'users', 'available_courses', 'registrations', 'grades', 'invoices',
  'mail_messages', 'library_resources', 'forum_posts', 'comments',
  'notifications', 'elearning_links', 'elearning_materials',
  'elearning_assignments', 'elearning_submissions', 'elearning_quizzes',
  'elearning_quiz_attempts', 'schedules', 'system_logs'
];

async function startDaemon() {
  console.log('Khởi tạo kết nối đến SQL Server...');
  try {
    pool = await sql.connect(sqlConfig);
    console.log('Kết nối SQL Server thành công! Đang thiết lập Lắng nghe (Listeners)...');
  } catch (err) {
    console.error('Lỗi kết nối SQL Server:', err.message);
    process.exit(1);
  }

  // A set to keep track of collections that have finished their initial load
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
            // Ignore the noisy initial load logging, but still upsert to be safe
            if (colName === 'users') await upsertUser(id, data);
            else if (colName === 'available_courses') await upsertCourse(id, data);
            else if (colName === 'registrations') await upsertRegistration(id, data);
            else await upsertGeneric(tableName, id, data);

            if (initialLoadCompleted.has(colName)) {
              console.log(`[SYNC] [${tableName}] THÊM MỚI: ${id}`);
            }
          }
          if (change.type === 'modified') {
            if (colName === 'users') await upsertUser(id, data);
            else if (colName === 'available_courses') await upsertCourse(id, data);
            else if (colName === 'registrations') await upsertRegistration(id, data);
            else await upsertGeneric(tableName, id, data);
            console.log(`[SYNC] [${tableName}] CẬP NHẬT: ${id}`);
          }
          if (change.type === 'removed') {
            await deleteDoc(tableName, id);
            console.log(`[SYNC] [${tableName}] ĐÃ XÓA: ${id}`);
          }
        } catch (err) {
          console.error(`[LỖI] khi đồng bộ document ${id} thuộc ${tableName}:`, err.message);
        }
      });

      // Mark this collection's initial snapshot load as completed
      initialLoadCompleted.add(colName);
    }, (error) => {
      console.error(`Lỗi listener ở collection ${colName}:`, error);
    });
  }

  console.log('====================================================');
  console.log('🚀 REAL-TIME DAEMON ĐANG CHẠY!');
  console.log('Tiến trình này sẽ lắng nghe Firebase liên tục 24/7.');
  console.log('Nếu bạn muốn dừng, nhấn Ctrl + C.');
  console.log('====================================================');
}

startDaemon();
