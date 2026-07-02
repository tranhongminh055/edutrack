import { addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { getAuth } from 'firebase/auth';

export async function createAnnouncement({ courseId, title, content, publishAt = null, pinned = false }) {
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) throw new Error('not authenticated');
  const payload = {
    courseId,
    authorId: user.uid,
    title,
    content,
    createdAt: serverTimestamp(),
    publishAt: publishAt || null,
    pinned: !!pinned,
  };
  const ref = await addDoc(collection(db, 'announcements'), payload);
  return ref.id;
}

export default { createAnnouncement };
