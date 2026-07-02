import { collection, addDoc, query, orderBy, getDocs, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { getAuth } from 'firebase/auth';

export async function createNotification(userId, { title, body, link = null, type = 'info' }) {
  if (!userId) throw new Error('userId required');
  const payload = { title, body, link, type, read: false, createdAt: serverTimestamp() };
  const ref = await addDoc(collection(db, `notifications_${userId}`), payload);
  return ref.id;
}

export async function listNotifications(userId, limit = 50) {
  if (!userId) throw new Error('userId required');
  const q = query(collection(db, `notifications_${userId}`), orderBy('createdAt', 'desc'));
  const snaps = await getDocs(q);
  const items = [];
  snaps.forEach(s => items.push({ id: s.id, ...s.data() }));
  return items.slice(0, limit);
}

export default { createNotification, listNotifications };
