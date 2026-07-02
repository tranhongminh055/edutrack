import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, updateDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c',
  appId: '1:17492164047:web:ffd5e7de0f7508226ee6ba',
  projectId: 'edu---track',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function backfillMajor() {
  try {
    // 1. Get all available courses to map docId -> major
    const coursesSnapshot = await getDocs(collection(db, 'available_courses'));
    const coursesMap = {};
    coursesSnapshot.forEach(doc => {
      coursesMap[doc.id] = doc.data().major || 'Chưa phân loại';
    });

    console.log(`Found ${Object.keys(coursesMap).length} courses.`);

    // 2. Get all registrations and update if major is missing
    const regsSnapshot = await getDocs(collection(db, 'registrations'));
    let updatedCount = 0;

    for (const regDoc of regsSnapshot.docs) {
      const data = regDoc.data();
      if (!data.major) {
        const major = coursesMap[data.courseDocId] || 'Chưa phân loại';
        await updateDoc(doc(db, 'registrations', regDoc.id), { major });
        updatedCount++;
        console.log(`Updated registration ${regDoc.id} with major: ${major}`);
      }
    }

    console.log(`Backfill completed. Updated ${updatedCount} registrations.`);
  } catch (e) {
    console.error('Error during backfill:', e);
  }
}

backfillMajor();
