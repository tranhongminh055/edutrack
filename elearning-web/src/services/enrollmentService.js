import { doc, setDoc, deleteDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { getAuth } from 'firebase/auth';

export async function enroll(courseId, role = 'student') {
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) throw new Error('not authenticated');
  const id = `${courseId}_${user.uid}`;
  const ref = doc(db, 'enrollments', id);
  await setDoc(ref, { courseId, userId: user.uid, role, enrolledAt: serverTimestamp(), status: 'active' }, { merge: true });
}

export async function unenroll(courseId) {
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) throw new Error('not authenticated');
  const id = `${courseId}_${user.uid}`;
  const ref = doc(db, 'enrollments', id);
  // soft-delete by setting status removed is safer; here we'll remove the doc
  await deleteDoc(ref);
}

export async function getEnrollment(courseId, userId) {
  if (!courseId || !userId) throw new Error('courseId and userId required');
  const id = `${courseId}_${userId}`;
  const ref = doc(db, 'enrollments', id);
  const snap = await getDoc(ref);
  return snap.exists() ? { id: snap.id, ...snap.data() } : null;
}

export default { enroll, unenroll, getEnrollment };
