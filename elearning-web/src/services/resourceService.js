import { collection, addDoc, serverTimestamp, getDocs, query, where, deleteDoc, doc } from 'firebase/firestore';
import { getStorage, ref as storageRef, uploadBytesResumable, getDownloadURL, deleteObject } from 'firebase/storage';
import { db } from '../firebase';
import { getAuth } from 'firebase/auth'; 

export async function uploadFile(courseId, file, onProgress = null) {
  if (!courseId || !file) throw new Error('courseId and file required');
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) throw new Error('not authenticated');
// ham khoi tao kho luu tru tai nguyen e-learning
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

export async function uploadLecturerEvaluationForm(file, onProgress = null) {
  if (!file) throw new Error('file required');
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) throw new Error('not authenticated');

  const storage = getStorage();
  const path = `lecturer_evaluations/${Date.now()}_${file.name}`;
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
          fileName: file.name,
          storagePath: path,
          mimeType: file.type || 'application/octet-stream',
          sizeBytes: file.size || 0,
          uploadedBy: user.uid,
          uploadedAt: serverTimestamp(),
          downloadUrl: url,
        };
        const docRef = await addDoc(collection(db, 'lecturer_evaluation_forms'), meta);
        resolve({ formId: docRef.id, storagePath: path, downloadUrl: url });
      } catch (err) {
        reject(err);
      }
    });
  });
}

export async function getLecturerEvaluationForms() {
  const q = query(collection(db, 'lecturer_evaluation_forms'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

export async function deleteLecturerEvaluationForm(formId, storagePath) {
  try {
    await deleteDoc(doc(db, 'lecturer_evaluation_forms', formId));
    const storage = getStorage();
    const sref = storageRef(storage, storagePath);
    await deleteObject(sref);
    return true;
  } catch (err) {
    console.error('Error deleting evaluation form:', err);
    throw err;
  }
}

export default { uploadFile, uploadLecturerEvaluationForm, getLecturerEvaluationForms, deleteLecturerEvaluationForm };
