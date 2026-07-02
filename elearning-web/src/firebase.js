import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: 'AIzaSyCKasCK2AL83NQYgbBDsmG9iBWGQncUJ7c',
  appId: '1:17492164047:web:ffd5e7de0f7508226ee6ba',
  messagingSenderId: '17492164047',
  projectId: 'edu---track',
  authDomain: 'edu---track.firebaseapp.com',
  storageBucket: 'edu---track.firebasestorage.app',
  measurementId: 'G-Z4EBNPSJ55',
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const storage = getStorage(app);
