const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'schedulehq-cf87f'
});

const db = admin.firestore();
const auth = admin.auth();

async function syncEmployees() {
  console.log('Starting employee sync...');
  const snapshot = await db.collection('employees').get();
  console.log('Found', snapshot.size, 'employees');
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!data.email) {
      console.log('Skipping', doc.id, '- no email');
      continue;
    }
    if (data.uid) {
      console.log('Skipping', doc.id, '- already has UID:', data.uid);
      continue;
    }
    
    console.log('Processing', doc.id, 'email:', data.email);
    try {
      let user;
      try {
        user = await auth.getUserByEmail(data.email);
        console.log('  User exists:', user.uid);
      } catch (e) {
        if (e.code === 'auth/user-not-found') {
          user = await auth.createUser({ email: data.email });
          console.log('  Created user:', user.uid);
        } else {
          throw e;
        }
      }
      
      await doc.ref.update({ uid: user.uid });
      await db.collection('users').doc(user.uid).set({
        email: data.email,
        employeeId: parseInt(doc.id) || doc.id,
        role: 'employee'
      }, { merge: true });
      
      console.log('  Updated', doc.id, 'with uid', user.uid);
    } catch (err) {
      console.error('  Error for', doc.id, err.message);
    }
  }
  console.log('Done!');
  process.exit(0);
}

syncEmployees().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
