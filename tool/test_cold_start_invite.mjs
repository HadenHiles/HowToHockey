import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createHash, randomBytes } from 'node:crypto';
import { createRequire } from 'node:module';
import { homedir } from 'node:os';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// No extra dependencies: use the backend's installed Firebase Admin SDK, against emulators only.
const require = createRequire(new URL('../functions/package.json', import.meta.url));
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const root = fileURLToPath(new URL('../', import.meta.url));
const platform = process.argv[2];
assert.ok(['android', 'ios'].includes(platform), 'Usage: node tool/test_cold_start_invite.mjs android|ios [device-id]');
for (const key of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  assert.match(process.env[key] ?? '', /^(127\.0\.0\.1|localhost):\d+$/, `${key} must point to a local Firebase emulator`);
}
assert.equal(process.env.GCLOUD_PROJECT, 'how-to-hockey', 'Run inside firebase emulators:exec --project how-to-hockey');
const device = process.argv[3] ?? (platform === 'android' ? 'emulator-5554' : '57C6D957-4A0B-40FD-B10F-73364BDF931B');
const bundle = 'com.howtohockey.app';
const adb = resolve(process.env.ANDROID_HOME ?? process.env.ANDROID_SDK_ROOT ?? `${homedir()}/Library/Android/sdk`, 'platform-tools/adb');
const uid = `cold-invite-${randomBytes(6).toString('hex')}`;
const email = `${uid}@example.com`;
const code = randomBytes(8).toString('hex').toUpperCase();
const codeKey = createHash('sha256').update(code).digest('hex');
const link = `howtohockey://app/join?code=${code}`;
const app = initializeApp({ projectId: 'how-to-hockey' }, uid);
const db = getFirestore(app);
let attach;

function run(command, args, { capture = false, allowFailure = false } = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, { cwd: root, stdio: capture ? ['ignore', 'pipe', 'pipe'] : 'inherit' });
    let output = '';
    if (capture) {
      child.stdout.on('data', (chunk) => { output += chunk; });
      child.stderr.on('data', (chunk) => { output += chunk; });
    }
    const timer = setTimeout(() => child.kill('SIGTERM'), 300_000);
    child.on('error', reject);
    child.on('exit', (status) => {
      clearTimeout(timer);
      if (status === 0 || allowFailure) resolvePromise({ status, output });
      else reject(new Error(`${command} ${args.join(' ')} exited ${status}\n${output}`));
    });
  });
}

function attachVm() {
  return new Promise((resolvePromise, reject) => {
    attach = spawn('flutter', ['attach', '--machine', '-d', device, '--app-id', bundle, '--no-dds'], { cwd: root, stdio: ['pipe', 'pipe', 'pipe'] });
    let buffer = '';
    const timer = setTimeout(() => reject(new Error('Timed out discovering the cold-launched VM service.')), 60_000);
    attach.on('error', reject);
    attach.on('exit', (status) => {
      clearTimeout(timer);
      reject(new Error(`Flutter attach exited ${status} before VM discovery.`));
    });
    attach.stderr.on('data', (chunk) => process.stderr.write(chunk));
    attach.stdout.on('data', (chunk) => {
      buffer += chunk;
      let newline;
      while ((newline = buffer.indexOf('\n')) >= 0) {
        const line = buffer.slice(0, newline);
        buffer = buffer.slice(newline + 1);
        if (!line.startsWith('[{')) {
          console.log(line);
          continue;
        }
        for (const event of JSON.parse(line)) {
          if (event.event === 'app.debugPort') {
            clearTimeout(timer);
            resolvePromise(event.params.wsUri);
          } else if (event.event === 'app.log') console.log(event.params.log);
        }
      }
    });
  });
}

try {
  await getAuth(app).createUser({ uid, email, password: 'local cold invite password' });
  await db.doc(`users/${uid}`).set({ roles: ['player', 'coach'] });
  await db.doc(`profiles/${uid}`).set({ ownerUid: uid, displayName: 'Cold H.', birthYear: 1990, isChild: false, teamIds: [] });
  await db.doc(`teams/${uid}`).set({
    name: 'Cold Start Team', searchName: 'cold start team', coachName: 'Cold H.', visibility: 'private',
    coachUids: [uid], joinCode: code, memberCount: 0, memberOwnerUids: [], memberProfileIds: [],
  });
  await db.doc(`teamCodes/${codeKey}`).set({ teamId: uid, kind: 'player' });
  const defines = ['--dart-define=USE_EMULATORS=true', `--dart-define=COLD_INVITE_EMAIL=${email}`, `--dart-define=COLD_INVITE_CODE=${code}`, `--dart-define=COLD_INVITE_PROFILE=${uid}`];
  const target = ['--target=integration_test/cold_start_invite_test.dart', ...defines];
  if (platform === 'android') {
    const abi = (await run(adb, ['-s', device, 'shell', 'getprop', 'ro.product.cpu.abi'], { capture: true })).output.trim();
    const architectures = { 'arm64-v8a': 'android-arm64', x86_64: 'android-x64', 'armeabi-v7a': 'android-arm' };
    assert.ok(architectures[abi], `Unsupported emulator ABI: ${abi}`);
    await run('flutter', ['build', 'apk', '--debug', `--target-platform=${architectures[abi]}`, ...target]);
    await run(adb, ['-s', device, 'install', '-r', 'build/app/outputs/flutter-apk/app-debug.apk']);
    await run(adb, ['-s', device, 'shell', 'am', 'start', '-n', `${bundle}/.MainActivity`]);
    const before = await run(adb, ['-s', device, 'shell', 'pidof', bundle], { capture: true });
    assert.match(before.output, /\d+/, 'The app must be running before termination.');
    await run(adb, ['-s', device, 'shell', 'am', 'force-stop', bundle]);
    const stopped = await run(adb, ['-s', device, 'shell', 'pidof', bundle], { capture: true, allowFailure: true });
    assert.notEqual(stopped.status, 0, 'The app process must be absent before opening the link.');
    await run(adb, ['-s', device, 'shell', 'am', 'start', '-W', '-a', 'android.intent.action.VIEW', '-c', 'android.intent.category.BROWSABLE', '-d', link]);
  } else {
    await run('flutter', ['build', 'ios', '--simulator', '--debug', ...target]);
    await run('xcrun', ['simctl', 'install', device, 'build/ios/iphonesimulator/Runner.app']);
    const before = await run('xcrun', ['simctl', 'launch', '--terminate-running-process', device, bundle], { capture: true });
    const pid = Number(before.output.match(/: (\d+)/)?.[1]);
    assert.ok(pid, 'Could not identify the simulator app process.');
    await run('xcrun', ['simctl', 'terminate', device, bundle]);
    const stopped = await run('/bin/ps', ['-p', String(pid), '-o', 'pid='], { capture: true, allowFailure: true });
    assert.notEqual(stopped.status, 0, 'The app process must be absent before opening the link.');
    await run('xcrun', ['simctl', 'openurl', device, link]);
  }
  console.log(`COLD START: ${platform} app was terminated; OS invitation URL opened.`);
  const vmUri = await attachVm();
  await run('flutter', ['drive', '-d', device, `--use-existing-app=${vmUri}`, '--driver=test_driver/integration_test.dart', '--no-keep-app-running']);
  console.log(`PASS: ${platform} native cold-start invite and authenticated join.`);
} finally {
  if (attach && attach.exitCode === null) attach.kill('SIGTERM');
  // Only this run's fixture documents and Auth user; never clear the emulator database.
  await db.recursiveDelete(db.doc(`teams/${uid}`));
  await db.recursiveDelete(db.doc(`profiles/${uid}`));
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.doc(`teamCodes/${codeKey}`).delete();
  await getAuth(app).deleteUsers([uid]);
  await deleteApp(app);
}
