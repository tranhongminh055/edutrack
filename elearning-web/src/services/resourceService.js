import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { getStorage, ref as storageRef, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { db } from '../firebase';
import { getAuth } from 'firebase/auth';

export async function uploadFile(courseId, file, onProgress = null) {
  if (!courseId || !file) throw new Error('courseId and file required');
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) throw new Error('not authenticated');

  const storage = getStorage();
  const path = `courses/${courseId}/resources/${Date.now()}_${file.name}`;
  const sref = storageRef(storage, path);
  const uploadTask = uploadBytesResumable(sref, file);

  return new Promise((resolve, reject) => {
    uploadTask.on('state_changed', snapshot => {
      if (onProgress) {
        const pct = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        onProgress(pct, snapshot);
      }
    }, reject, async () => {
      try {
        const url = await getDownloadURL(sref);
        const meta = {
          courseId,
          fileName: file.name,
          storagePath: path,
          mimeType: file.type || 'application/octet-stream',
          sizeBytes: file.size || 0,
          uploadedBy: user.uid,
          uploadedAt: serverTimestamp(),
          visibility: 'course',
        };
        const docRef = await addDoc(collection(db, 'course_resources'), meta);
        resolve({ resourceId: docRef.id, storagePath: path, downloadUrl: url });
      } catch (err) {
        reject(err);
      }
    });
  });
}

export default { uploadFile };
