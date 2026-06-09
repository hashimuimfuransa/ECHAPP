/**
 * fix_instructor_roles.js
 *
 * Usage:
 *
 *  Audit (no args) — print all instructors and recent students:
 *    node fix_instructor_roles.js
 *
 *  Fix role of an existing account (by email, firebaseUid, or MongoDB _id):
 *    node fix_instructor_roles.js user@example.com
 *    node fix_instructor_roles.js user1@example.com user2@example.com
 *
 *  Link a Firebase UID to an existing MongoDB instructor (e.g. mubi@gmail.com
 *  has no firebaseUid but the instructor logs in via a Firebase student account):
 *    node fix_instructor_roles.js --link <instructorEmail> <firebaseUidOrStudentEmail>
 *    e.g.: node fix_instructor_roles.js --link mubi@gmail.com student_firebase_uid_here
 *          node fix_instructor_roles.js --link mubi@gmail.com otheremail@gmail.com
 */

require('dotenv').config();
const mongoose = require('mongoose');
const admin = require('./src/config/firebase');

async function main() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB\n');

  const User = require('./src/models/User');
  const args = process.argv.slice(2);

  // ── --link mode: merge a Firebase student account INTO an existing instructor ──
  if (args[0] === '--link') {
    const instructorIdentifier = args[1];
    const studentIdentifier = args[2];

    if (!instructorIdentifier || !studentIdentifier) {
      console.error('Usage: node fix_instructor_roles.js --link <instructorEmail> <studentEmailOrFirebaseUid>');
      process.exit(1);
    }

    // Find instructor (MongoDB-only account)
    let instructor = await User.findOne({ email: instructorIdentifier.toLowerCase() });
    if (!instructor && instructorIdentifier.match(/^[0-9a-fA-F]{24}$/)) {
      try { instructor = await User.findById(instructorIdentifier); } catch (_) {}
    }
    if (!instructor) {
      console.error(`✗ Instructor not found: ${instructorIdentifier}`);
      process.exit(1);
    }
    console.log(`Instructor: ${instructor.fullName} | ${instructor.email} | role: ${instructor.role} | firebaseUid: ${instructor.firebaseUid || 'none'}`);

    // Find the student account (Firebase-linked duplicate)
    let student = await User.findOne({ email: studentIdentifier.toLowerCase() });
    if (!student) student = await User.findOne({ firebaseUid: studentIdentifier });
    if (!student && studentIdentifier.match(/^[0-9a-fA-F]{24}$/)) {
      try { student = await User.findById(studentIdentifier); } catch (_) {}
    }

    let firebaseUidToLink = studentIdentifier; // assume it's a raw UID if not found as email

    if (student) {
      console.log(`Student (duplicate): ${student.fullName} | ${student.email} | role: ${student.role} | firebaseUid: ${student.firebaseUid || 'none'}`);
      if (!student.firebaseUid) {
        console.error('✗ Student account has no firebaseUid — cannot link.');
        process.exit(1);
      }
      firebaseUidToLink = student.firebaseUid;

      // Delete the student duplicate to avoid firebaseUid conflict
      console.log(`\nDeleting duplicate student account (id: ${student._id})...`);
      await User.findByIdAndDelete(student._id);
      console.log('✓ Duplicate student account removed');
    } else {
      console.log(`No MongoDB student found for "${studentIdentifier}" — treating as raw Firebase UID`);
    }

    // Link firebaseUid to instructor and ensure role=instructor
    instructor.firebaseUid = firebaseUidToLink;
    instructor.role = 'instructor';
    await instructor.save();
    console.log(`✓ Linked firebaseUid ${firebaseUidToLink} to instructor account`);

    // Set Firebase custom claims
    try {
      await admin.auth().setCustomUserClaims(firebaseUidToLink, { role: 'instructor' });
      console.log('✓ Firebase custom claims set to instructor');
    } catch (err) {
      console.warn('⚠ Firebase claims update failed:', err.message);
    }

    console.log(`\n✓ Done. The instructor can now log in via Firebase and will have role=instructor.`);
    console.log('  They must log out and log back in for the new claims to take effect.');
    await mongoose.connection.close();
    return;
  }

  const targets = args; // emails or firebaseUids passed as args

  // ── PART 1: Fix roles ───────────────────────────────────────────────────────
  if (targets.length === 0) {
    // No args → just audit: show all instructors and all students
    const instructors = await User.find({ role: 'instructor' }).select('fullName email phone firebaseUid role createdAt');
    console.log(`=== Current INSTRUCTOR accounts (${instructors.length}) ===`);
    instructors.forEach((u, i) => {
      console.log(`  ${i + 1}. ${u.fullName || '(no name)'} | ${u.email || u.phone || '(no contact)'} | firebaseUid: ${u.firebaseUid || 'none'} | created: ${u.createdAt}`);
    });

    const students = await User.find({ role: 'student' }).select('fullName email phone firebaseUid role createdAt').sort({ createdAt: -1 }).limit(20);
    console.log(`\n=== Latest STUDENT accounts (showing last 20 of ${await User.countDocuments({ role: 'student' })}) ===`);
    students.forEach((u, i) => {
      console.log(`  ${i + 1}. ${u.fullName || '(no name)'} | ${u.email || u.phone || '(no contact)'} | firebaseUid: ${u.firebaseUid || 'none'} | created: ${u.createdAt}`);
    });

    console.log('\nTo fix a specific user run:');
    console.log('  node fix_instructor_roles.js <email_or_firebaseUid> [<email_or_firebaseUid> ...]');
  } else {
    // Fix each target
    for (const identifier of targets) {
      console.log(`\nProcessing: ${identifier}`);

      // Find by email first, then by firebaseUid
      let user = await User.findOne({ email: identifier.toLowerCase() });
      if (!user) user = await User.findOne({ firebaseUid: identifier });
      if (!user && identifier.match(/^[0-9a-fA-F]{24}$/)) {
        try { user = await User.findById(identifier); } catch (_) {}
      }

      if (!user) {
        console.log(`  ✗ User not found for identifier: ${identifier}`);
        continue;
      }

      console.log(`  Found: ${user.fullName || '(no name)'} | current role: ${user.role}`);

      if (user.role === 'instructor') {
        console.log('  ✓ Already has instructor role, skipping.');
        continue;
      }

      // Update MongoDB
      user.role = 'instructor';
      await user.save();
      console.log('  ✓ MongoDB role updated to instructor');

      // Update Firebase custom claims if the user has a firebaseUid
      if (user.firebaseUid) {
        try {
          await admin.auth().setCustomUserClaims(user.firebaseUid, { role: 'instructor' });
          console.log('  ✓ Firebase custom claims updated to instructor');
        } catch (err) {
          console.warn('  ⚠ Firebase claims update failed (non-fatal):', err.message);
        }
      } else {
        console.log('  ⚠ No firebaseUid — Firebase claims not updated (user uses JWT auth only)');
      }

      console.log(`  ✓ Done. User ${user.email || user.phone} is now an instructor.`);
    }
  }

  // ── PART 2: Registration audit ─────────────────────────────────────────────
  console.log('\n=== Registration flow audit ===');

  // Check: new firebase signups default to 'student'
  const recentUsers = await User.find({ role: 'student', firebaseUid: { $exists: true, $ne: null } })
    .sort({ createdAt: -1 }).limit(5)
    .select('fullName email phone firebaseUid role createdAt');

  console.log('Last 5 Firebase-registered students (expected role=student):');
  recentUsers.forEach((u, i) => {
    const ok = u.role === 'student' ? '✓' : '✗ WRONG ROLE';
    console.log(`  ${i + 1}. [${ok}] ${u.fullName || '(no name)'} | ${u.email || u.phone} | role: ${u.role} | created: ${u.createdAt}`);
  });

  // Check: teachers created via createTeacher have role=instructor
  const recentTeachers = await User.find({ role: 'instructor' })
    .sort({ createdAt: -1 }).limit(5)
    .select('fullName email phone firebaseUid role createdAt');

  console.log('\nLast 5 instructor accounts (expected role=instructor):');
  recentTeachers.forEach((u, i) => {
    const ok = u.role === 'instructor' ? '✓' : '✗ WRONG ROLE';
    console.log(`  ${i + 1}. [${ok}] ${u.fullName || '(no name)'} | ${u.email || u.phone} | role: ${u.role} | created: ${u.createdAt}`);
  });

  // Check: any instructor-role user missing firebaseUid (would break Firebase auth)
  const instructorsWithoutFirebase = await User.find({ role: 'instructor', $or: [{ firebaseUid: null }, { firebaseUid: { $exists: false } }] })
    .select('fullName email phone role');

  if (instructorsWithoutFirebase.length > 0) {
    console.log(`\n⚠ ${instructorsWithoutFirebase.length} instructor(s) have NO firebaseUid (they use JWT/password auth only):`);
    instructorsWithoutFirebase.forEach(u => console.log(`   - ${u.fullName} | ${u.email || u.phone}`));
  } else {
    console.log('\n✓ All instructors have a firebaseUid');
  }

  await mongoose.connection.close();
  console.log('\nDone.');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
