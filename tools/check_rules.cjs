// Run through Firebase emulators; no production accounts or reports are changed.
const { createRequire } = require('node:module');
const fs = require('node:fs');
const dependencyRoot = process.env.QUICKFIX_TEST_DEPS;
const testRequire = dependencyRoot ? createRequire(dependencyRoot + '/package.json') : require;
const { initializeTestEnvironment, assertFails, assertSucceeds } = testRequire('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp, collection, query, where, getDocs, runTransaction } = testRequire('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject } = testRequire('firebase/storage');

(async () => {
  const env = await initializeTestEnvironment({
    projectId: process.env.QUICKFIX_TEST_PROJECT || 'demo-quickfix',
    firestore: { host: '127.0.0.1', port: 8188, rules: fs.readFileSync('firestore.rules', 'utf8') },
    storage: { host: '127.0.0.1', port: 9299, rules: fs.readFileSync('storage.rules', 'utf8') },
  });
  try {
    await env.clearFirestore();
    await env.clearStorage();
    const alice = env.authenticatedContext('student-alice');
    const bob = env.authenticatedContext('student-bob');
    const guest = env.unauthenticatedContext();
    const report = doc(alice.firestore(), 'quickfix_reports/report-one');
    const path = 'quickfix/student-alice/report-one/problem.png';
    const image = Uint8Array.from(Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jk9sAAAAASUVORK5CYII=', 'base64'));
    const photo = ref(alice.storage(), path);
    await assertSucceeds(uploadBytes(photo, image, { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(bob.storage(), path), image, { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(alice.storage(), 'quickfix/student-alice/report-one/bad.txt'), image, { contentType: 'text/plain' }));
    await assertFails(uploadBytes(ref(alice.storage(), 'quickfix/student-alice/report-one/oversize.png'), new Uint8Array(5 * 1024 * 1024 + 1), { contentType: 'image/png' }));
    const values = {
      ownerId: 'student-alice', title: 'Broken classroom chair', description: 'The backrest is loose.',
      location: 'Building A, Room 204', category: 'Furniture', photoPath: path,
      latitude: 14.858, longitude: 120.815, status: 'Submitted', createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    };
    await assertSucceeds(runTransaction(alice.firestore(), async transaction => { transaction.set(report, values); }));
    await assertSucceeds(getDoc(report));
    await assertSucceeds(getBytes(photo));
    await assertSucceeds(getDocs(query(collection(alice.firestore(), 'quickfix_reports'), where('ownerId', '==', 'student-alice'))));
    await assertFails(getDoc(doc(bob.firestore(), 'quickfix_reports/report-one')));
    await assertFails(getDoc(doc(guest.firestore(), 'quickfix_reports/report-one')));
    await assertFails(getDocs(collection(alice.firestore(), 'quickfix_reports')));
    await assertFails(getBytes(ref(bob.storage(), path)));
    await assertFails(getBytes(ref(guest.storage(), path)));
    await assertSucceeds(updateDoc(report, { title: 'Broken chair in Room 204', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { ownerId: 'student-bob', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { status: 'Resolved', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { latitude: 200, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { title: '', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(report, { status: 'Under Review', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { title: 'Changed after review', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(report));
    await assertFails(deleteObject(photo));
    await assertFails(uploadBytes(ref(alice.storage(), 'quickfix/student-alice/report-one/replacement.png'), image, { contentType: 'image/png' }));
    await assertFails(updateDoc(report, { status: 'Submitted', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(report, { status: 'In Progress', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(report, { status: 'Resolved', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { status: 'Submitted', updatedAt: serverTimestamp() }));
    const pending = doc(alice.firestore(), 'quickfix_reports/delete-me');
    await assertSucceeds(setDoc(pending, { ...values, photoPath: 'quickfix/student-alice/delete-me/problem.png' }));
    const pendingPhoto = ref(alice.storage(), 'quickfix/student-alice/delete-me/problem.png');
    await assertSucceeds(uploadBytes(pendingPhoto, image, { contentType: 'image/png' }));
    await assertSucceeds(deleteDoc(pending));
    await assertSucceeds(deleteObject(pendingPhoto));
    await assertSucceeds(setDoc(doc(alice.firestore(), 'users/student-alice'), { fullName: 'Activity 5 compatibility check' }));
    await assertFails(getDoc(doc(bob.firestore(), 'users/student-alice')));
    console.log('PASS: report lifecycle, owner isolation, status restrictions, photo access/type/size, pending deletion, and Activity 5 profile compatibility.');
  } finally {
    await env.cleanup();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
