const admin = require('firebase-admin');
console.log('Initializing firebase...');
admin.initializeApp({
  projectId: 'edu---track'
});

const db = admin.firestore();

async function run() {
  console.log('Fetching active evaluation forms...');
  const formsSnapshot = await db.collection('evaluation_forms').get();
  console.log(`Found ${formsSnapshot.size} total forms.`);
  formsSnapshot.forEach(doc => {
    console.log(doc.id, '=> active:', doc.data().isActive, doc.data().title, doc.data().academicYear, doc.data().semester);
  });

  console.log('Fetching registrations...');
  const regsSnapshot = await db.collection('registrations').limit(10).get();
  console.log(`Found ${regsSnapshot.size} registrations.`);
  regsSnapshot.forEach(doc => {
    console.log(doc.id, '=>', doc.data().studentName, doc.data().academicYear, doc.data().semester, doc.data().lecturerName);
  });
  
  process.exit(0);
}

run().catch(err => {
  console.error('Error running query:', err);
  process.exit(1);
});
