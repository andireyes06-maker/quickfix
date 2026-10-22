// Run through Firebase emulators; no production accounts or reports are changed.
// Photos are stored in Firestore (quickfix_photos), so only the Firestore emulator is needed.
const { createRequire } = require('node:module');
const fs = require('node:fs');
const dependencyRoot = process.env.QUICKFIX_TEST_DEPS;
const testRequire = dependencyRoot ? createRequire(dependencyRoot + '/package.json') : require;
const { initializeTestEnvironment, assertFails, assertSucceeds } = testRequire('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp, collection, query, where, getDocs, runTransaction } = testRequire('firebase/firestore');

// A 1x1 PNG, as base64 text, like the app stores.
const tinyPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jk9sAAAAASUVORK5CYII=';

function reportFor(uid, id) {
  return {
    ownerId: uid, title: 'Broken classroom chair', description: 'The backrest is loose.',
    location: 'Building A, Room 204', category: 'Furniture', photoPath: 'quickfix_photos/' + id,
    latitude: 14.858, longitude: 120.815, status: 'Submitted', createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  };
}

function photoFor(uid, overrides) {
  return { ownerId: uid, contentType: 'image/png', data: tinyPng, updatedAt: serverTimestamp(), ...overrides };
}

// Saves a report and its photo together, the way the app does.
function createWithPhoto(context, uid, id, reportOverrides, photoOverrides) {
  const db = context.firestore();
  return runTransaction(db, async transaction => {
    transaction.set(doc(db, 'quickfix_reports/' + id), { ...reportFor(uid, id), ...reportOverrides });
    transaction.set(doc(db, 'quickfix_photos/' + id), photoFor(uid, photoOverrides));
  });
}

(async () => {
  const env = await initializeTestEnvironment({
    projectId: process.env.QUICKFIX_TEST_PROJECT || 'demo-quickfix',
    firestore: { host: '127.0.0.1', port: 8188, rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
  // Reads with rules turned off, so a missing document does not look like a permission error.
  // The callback's return value is discarded by this library, so keep the answer in a variable.
  async function exists(path) {
    let found = false;
    await env.withSecurityRulesDisabled(async context => {
      found = (await getDoc(doc(context.firestore(), path))).exists();
    });
    return found;
  }
  try {
    await env.clearFirestore();
    const alice = env.authenticatedContext('student-alice');
    const bob = env.authenticatedContext('student-bob');
    const guest = env.unauthenticatedContext();
    const db = alice.firestore();
    const report = doc(db, 'quickfix_reports/report-one');
    const photo = doc(db, 'quickfix_photos/report-one');

    // Create, read, and owner isolation.
    await assertSucceeds(createWithPhoto(alice, 'student-alice', 'report-one'));
    await assertSucceeds(getDoc(report));
    await assertSucceeds(getDoc(photo));
    await assertSucceeds(getDocs(query(collection(db, 'quickfix_reports'), where('ownerId', '==', 'student-alice'))));
    await assertFails(getDoc(doc(bob.firestore(), 'quickfix_reports/report-one')));
    await assertFails(getDoc(doc(guest.firestore(), 'quickfix_reports/report-one')));
    await assertFails(getDocs(collection(db, 'quickfix_reports')));
    await assertFails(getDoc(doc(bob.firestore(), 'quickfix_photos/report-one')));
    await assertFails(getDoc(doc(guest.firestore(), 'quickfix_photos/report-one')));
    await assertFails(getDocs(collection(db, 'quickfix_photos')));

    // A report needs its photo, and a photo needs its report.
    await assertFails(runTransaction(db, async transaction => {
      transaction.set(doc(db, 'quickfix_reports/no-photo'), reportFor('student-alice', 'no-photo'));
    }));
    await assertFails(setDoc(doc(db, 'quickfix_photos/orphan'), photoFor('student-alice')));
    await assertFails(setDoc(doc(guest.firestore(), 'quickfix_photos/guest-photo'), photoFor('student-alice')));

    // Photo field checks on create.
    await assertFails(createWithPhoto(alice, 'student-alice', 'bad-type', {}, { contentType: 'image/gif' }));
    await assertFails(createWithPhoto(alice, 'student-alice', 'too-big', {}, { data: 'A'.repeat(700001) }));
    await assertFails(createWithPhoto(alice, 'student-alice', 'empty-photo', {}, { data: '' }));
    await assertFails(createWithPhoto(alice, 'student-alice', 'number-photo', {}, { data: 12345 }));
    await assertFails(createWithPhoto(alice, 'student-alice', 'extra-field', {}, { note: 'extra' }));
    await assertFails(createWithPhoto(alice, 'student-alice', 'wrong-owner', {}, { ownerId: 'student-bob' }));
    await assertFails(createWithPhoto(alice, 'student-alice', 'wrong-path', { photoPath: 'quickfix_photos/other-report' }));
    await assertSucceeds(createWithPhoto(alice, 'student-alice', 'max-size', {}, { data: 'A'.repeat(700000) }));

    // One student cannot touch another student's photo.
    await assertFails(setDoc(doc(bob.firestore(), 'quickfix_photos/report-one'), photoFor('student-bob')));
    await assertFails(updateDoc(doc(bob.firestore(), 'quickfix_photos/report-one'), { data: 'changed', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(bob.firestore(), 'quickfix_photos/report-one')));

    // While pending: report edits and photo replacement are allowed.
    await assertSucceeds(updateDoc(report, { title: 'Broken chair in Room 204', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(photo, { contentType: 'image/jpeg', data: 'replacement', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(photo, { ownerId: 'student-bob', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(photo, { contentType: 'image/gif', updatedAt: serverTimestamp() }));
    await assertSucceeds(createWithPhoto(alice, 'student-alice', 'edit-me'));
    await assertSucceeds(runTransaction(db, async transaction => {
      transaction.update(doc(db, 'quickfix_reports/edit-me'), { title: 'Edited together', updatedAt: serverTimestamp() });
      transaction.update(doc(db, 'quickfix_photos/edit-me'), { data: 'edited', updatedAt: serverTimestamp() });
    }));

    // Report field checks and legal status steps.
    await assertFails(updateDoc(report, { ownerId: 'student-bob', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { status: 'Resolved', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { latitude: 200, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { title: '', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { photoPath: 'quickfix/student-alice/report-one/old.png', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(report, { status: 'Under Review', updatedAt: serverTimestamp() }));

    // After review starts: no edits, no photo changes, no deletes.
    await assertFails(updateDoc(report, { title: 'Changed after review', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(report));
    await assertFails(updateDoc(photo, { data: 'too late', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(photo));
    await assertFails(runTransaction(db, async transaction => {
      transaction.delete(report);
      transaction.delete(photo);
    }));
    if (!(await exists('quickfix_photos/report-one')) || !(await exists('quickfix_reports/report-one'))) {
      throw new Error('A failed delete must leave both documents in place.');
    }
    await assertFails(updateDoc(report, { status: 'Submitted', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(report, { status: 'In Progress', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(report, { status: 'Resolved', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { status: 'Submitted', updatedAt: serverTimestamp() }));

    // Pending delete removes both documents together.
    await assertSucceeds(createWithPhoto(alice, 'student-alice', 'delete-me'));
    await assertSucceeds(runTransaction(db, async transaction => {
      transaction.delete(doc(db, 'quickfix_reports/delete-me'));
      transaction.delete(doc(db, 'quickfix_photos/delete-me'));
    }));
    if ((await exists('quickfix_photos/delete-me')) || (await exists('quickfix_reports/delete-me'))) {
      throw new Error('A pending delete must remove both documents.');
    }

    // A leftover photo with no report can be cleaned up by its owner only.
    await env.withSecurityRulesDisabled(async context => {
      await setDoc(doc(context.firestore(), 'quickfix_photos/leftover'), { ownerId: 'student-alice', contentType: 'image/png', data: tinyPng, updatedAt: new Date() });
    });
    await assertFails(deleteDoc(doc(bob.firestore(), 'quickfix_photos/leftover')));
    await assertSucceeds(deleteDoc(doc(db, 'quickfix_photos/leftover')));

    // Activity 5 profile access is unchanged.
    await assertSucceeds(setDoc(doc(db, 'users/student-alice'), { fullName: 'Activity 5 compatibility check' }));
    await assertFails(getDoc(doc(bob.firestore(), 'users/student-alice')));
    console.log('PASS: report and photo lifecycle in Firestore, owner isolation, status restrictions, photo type/size limits, atomic pending deletion, and Activity 5 profile compatibility.');
  } finally {
    await env.cleanup();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
