import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

const fixture = process.env.SMS_UI_FIXTURE === 'true';
const debugPort = Number(process.env.SMS_UI_DEBUG_PORT || 9226);
const url = process.env.SMS_UI_BASE_URL || (fixture ? 'http://127.0.0.1:5175' : 'http://127.0.0.1:5173');
const output = path.resolve('../screenshots/recheck-2026-11-12', fixture ? 'six-roles' : process.env.SMS_UI_ROLE === 'STUDENT' ? 'student-restored' : 'mysql');
await mkdir(output, { recursive: true });
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
let vite;
if (fixture) {
  vite = spawn(process.execPath, ['node_modules/vite/bin/vite.js', '--host', '127.0.0.1', '--port', '5175', '--strictPort'], {
    windowsHide: true, stdio: 'ignore', env: { ...process.env, SMS_TEST_API_TARGET: 'http://127.0.0.1:8082' },
  });
}
const profile = await mkdtemp(path.join(os.tmpdir(), 'sms-full-ui-'));
const browser = spawn(process.env.CHROME_PATH || (process.platform === 'win32' ? 'C:/Program Files/Google/Chrome/Application/chrome.exe' : '/usr/bin/google-chrome'), [
  '--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', `--remote-debugging-port=${debugPort}`, `--user-data-dir=${profile}`, 'about:blank',
], { windowsHide: true, stdio: 'ignore' });
const report = { database: fixture ? 'isolated H2' : 'MySQL', screens: [], dialogs: [], issues: [], runtimeErrors: [] };
let ws;
try {
  let targets;
  for (let i = 0; i < 100; i++) {
    try { targets = await fetch(`http://127.0.0.1:${debugPort}/json`).then(r => r.json()); if ((await fetch(url)).ok) break; } catch {}
    await sleep(150);
  }
  assert.ok(targets, 'Chrome must start');
  ws = new WebSocket(targets.find(target => target.type === 'page').webSocketDebuggerUrl);
  await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
  let id = 0;
  const pending = new Map();
  ws.onmessage = event => {
    const message = JSON.parse(event.data);
    if (message.method === 'Runtime.exceptionThrown') report.runtimeErrors.push(message.params.exceptionDetails.exception?.description || message.params.exceptionDetails.text);
    if (pending.has(message.id)) { pending.get(message.id)(message); pending.delete(message.id); }
  };
  const call = (method, params = {}) => new Promise((resolve, reject) => {
    const current = ++id;
    const timer = setTimeout(() => { pending.delete(current); reject(new Error(`CDP timeout: ${method}`)); }, 20000);
    pending.set(current, response => { clearTimeout(timer); response.error ? reject(new Error(response.error.message)) : resolve(response.result); });
    ws.send(JSON.stringify({ id: current, method, params }));
  });
  const evaluate = async expression => {
    const result = await call('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
    return result.result.value;
  };
  const run = (fn, ...args) => evaluate(`(${fn.toString()})(...${JSON.stringify(args)})`);
  const wait = async expression => {
    for (let i = 0; i < 100; i++) { if (await evaluate(expression)) return; await sleep(100); }
    throw new Error(`UI timeout: ${expression}`);
  };
  const click = (text, selector = 'button') => run(async (text, selector) => {
    const element = [...document.querySelectorAll(selector)].find(item => item.textContent.trim() === text);
    if (!element) throw new Error(`Missing control: ${text}`);
    const group = element.closest('.nav-group');
    if(group?.querySelector('.nav-group-toggle')?.getAttribute('aria-expanded')==='false') { group.querySelector('.nav-group-toggle').click(); await new Promise(requestAnimationFrame); }
    element.click();
  }, text, selector);
  const input = (selector, value) => run((selector, value) => {
    const element = document.querySelector(selector);
    Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(element, value);
    element.dispatchEvent(new Event('input', { bubbles: true }));
  }, selector, value);
  const viewport = (width, height) => call('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: width < 600 });
  const screenshot = async name => {
    await sleep(200);
    const shot = await call('Page.captureScreenshot', { format: 'png' });
    await writeFile(path.join(output, `${name}.png`), Buffer.from(shot.data, 'base64'));
  };
  const inspect = async (name, role) => {
    await sleep(150);
    const state = await run(() => ({
      width: innerWidth, scrollWidth: document.documentElement.scrollWidth,
      topbarTop: document.querySelector('.topbar')?.getBoundingClientRect().top,
      errors: [...document.querySelectorAll('.v6-error,[role=alert]')].map(item => item.innerText),
      dialogs: [...document.querySelectorAll('[role=dialog]')].map(item => {
        const rect = item.getBoundingClientRect();
        return { top: rect.top, left: rect.left, right: rect.right, bottom: rect.bottom, height: innerHeight, width: innerWidth };
      }),
    }));
    report.screens.push({ role, name, width: state.width });
    if (state.scrollWidth > state.width + 1) report.issues.push({ role, name, type: 'page overflow', ...state });
    if (state.topbarTop != null && Math.abs(state.topbarTop) > 1) report.issues.push({role,name,type:'header shifted outside viewport',top:state.topbarTop});
    if (state.errors.length) report.issues.push({ role, name, type: 'visible API error', errors: state.errors });
    if (state.dialogs.some(rect => rect.left < -1 || rect.right > rect.width + 1 || rect.top < -1 || rect.bottom > rect.height + 1)) report.issues.push({ role, name, type: 'dialog outside viewport', dialogs: state.dialogs });
  };
  const close = async () => {
    await run(() => document.querySelector('[role=dialog] button[aria-label="Đóng"]').click());
    await wait('!document.querySelector("[role=dialog]")');
  };
  await call('Runtime.enable');
  await call('Page.enable');
  await viewport(1440, 1000);
  await call('Page.navigate', { url });
  await wait('!!document.querySelector(".public-login-button")');
  await inspect('landing', 'PUBLIC'); await screenshot('landing-desktop');
  await viewport(390, 844); await inspect('landing-mobile', 'PUBLIC'); await screenshot('landing-mobile');
  await viewport(1440, 1000);
  await click('Nộp hồ sơ trực tuyến');
  await wait('!!document.querySelector(".login-card select")');
  await inspect('admission form', 'PUBLIC'); await screenshot('admission-form');
  await run(() => document.querySelector('.login-back').click());
  const credentials = fixture || process.env.SMS_UI_PASSWORD ? null : await readFile('../backend/.local/admin-credentials.txt', 'utf8');
  const password = process.env.SMS_UI_PASSWORD || (fixture ? process.env.SMS_UI_PASSWORD : credentials.match(/^Password: (.+)$/m)[1].trim());
  const roles = fixture ? ['PRINCIPAL', 'CTSV', 'TRAINING_OFFICE', 'LECTURER', 'STUDENT', 'APPLICANT'] : [process.env.SMS_UI_ROLE || 'PRINCIPAL'];
  for (const role of roles) {
    await viewport(1440, 1000);
    await call('Page.navigate', { url: url + '/?uiRole=' + role + '#top' });
    await sleep(300);
    await wait('!!document.querySelector(".public-login-button")');
    await run(() => document.querySelector('.public-login-button').click());
    await wait('!!document.querySelector("input[type=password]")');
    await input('.login-card input[type=text]', fixture ? role.toLowerCase() : process.env.SMS_UI_USERNAME || 'principal');
    await input('.login-card input[type=password]', password);
    await run(() => document.querySelector('.login-card form').requestSubmit());
    await wait('!!document.querySelector(".navigation") || !!document.querySelector(".v6-error")');
    assert.ok(await evaluate('!!document.querySelector(".navigation")'), `Login failed: ${role}`);
    if(role==='STUDENT') { await wait('document.querySelector("[data-overview-ready=true]") !== null'); assert.equal(await evaluate('!!document.querySelector("[data-page=mailboxes]")'),false,'School email stays in the profile, not a separate student menu'); }
    await inspect('overview', role); await screenshot(`${role}-overview`);
    await viewport(390,844); await inspect('overview mobile',role); await screenshot(`${role}-overview-mobile`); await viewport(1440,1000);
    const menus = await run(() => [...document.querySelectorAll('.navigation [data-page]')].filter(item=>item.dataset.page!=='overview').map(item => item.innerText.trim()));
    for (const menu of menus) {
      await click(menu, '.navigation .nav-item');
      await wait('!!document.querySelector(".pagination,.v6-timetable,.academic-toolbar,[data-exam-list],[data-profile-page] .student-profile-detail,[data-tuition-page] .data-table,[data-notifications-page=ready],.v6-error")');
      await inspect(menu, role);
      const controls = await run(() => [...document.querySelectorAll('.page-header button')].map(item => item.textContent.trim()));
      for (const control of controls) {
        await click(control, '.page-header button'); await wait('!!document.querySelector("[role=dialog]")');
        await inspect(`${menu}: ${control}`, role); await viewport(390,844); await inspect(`${menu}: ${control} mobile`,role); await viewport(1440,1000); report.dialogs.push({ role, menu, control });
        await close();
      }
      if (role==='STUDENT' && menu==='Tra cứu lớp học phần') assert.equal(await run(()=>[...document.querySelectorAll('.academic-action button')].some(button=>/^(Đăng ký|Hủy đăng ký)$/.test(button.textContent.trim()))),false,'Catalog must be read-only; registration has a separate purpose');
      if (role==='STUDENT' && menu==='Thông báo' && await evaluate("!!document.querySelector('.student-notice-list button')")) {
        await run(()=>document.querySelector('.student-notice-list button').click()); await wait('!!document.querySelector("[role=dialog]")'); await inspect('Read notification',role); await close();
      }
      // Read-only detail panels; never submit mutations against seed data.
      const details = await run(() => [...new Set([...document.querySelectorAll('.v6-row-actions button,.academic-action button,[data-tuition-page] tbody button')].map(item => item.textContent.trim()))].filter(text => /chi tiết|Chi tiết|Hồ sơ \/ ảnh|Lịch sử|Nội dung|Giấy tờ yêu cầu|Lịch các buổi|Xem bảng điểm|Học phần trong chương trình|Người nhận|^Sửa$|Gán vai trò|Cấu hình hộp thư|Thêm \/ sửa loại giấy tờ|Gửi theo vai trò/.test(text)));
      for (const detail of details) {
        await click(detail, '.v6-row-actions button,.academic-action button,[data-tuition-page] tbody button');
        await wait('!!document.querySelector("[role=dialog]") || !!document.querySelector(".toast-error")');
        if (await evaluate('!!document.querySelector("[role=dialog]")')) {
          await wait('!document.querySelector("[role=dialog] [role=status]")');
          await inspect(`${menu}: ${detail}`, role); await viewport(390,844); await inspect(`${menu}: ${detail} mobile`,role); await viewport(1440,1000); report.dialogs.push({ role, menu, control: detail }); await close();
        } else report.issues.push({ role, name: menu, type: 'detail request failed', detail });
      }
      if (['Thời khóa biểu','Lịch học'].includes(menu)) {
        for (const view of ['Ngày', 'Tháng', 'Tuần']) {
          await click(view, '.v6-calendar-tools button');
          await inspect(`${menu}: ${view}`, role);
          await viewport(390,844); await inspect(`${menu}: ${view} mobile`,role); await viewport(1440,1000);
        }
        await screenshot(`${role}-calendar-week`);
        const events = await evaluate("document.querySelectorAll('.hourly-event').length");
        if (events) { await run(() => document.querySelector('.hourly-event').click()); await inspect('Calendar event detail',role); await screenshot(`${role}-calendar-detail`); await close(); }
      }
      if (role === 'STUDENT' && ['Đăng ký học phần','Đăng ký / hủy học phần'].includes(menu)) {
        await click('Chọn lớp để đăng ký'); await inspect('Available sections',role); await screenshot('STUDENT-registration-catalog');
        await click('Đã đăng ký'); await inspect('Registered sections',role);
      }
      if (['Thời khóa biểu','Lịch học'].includes(menu)) assert.ok(await evaluate("!document.querySelector('.v6-calendar-tools select').textContent.includes('T17:')"), 'Calendar labels must not expose UTC timestamp dates');
      if (['Sinh viên', 'Hồ sơ cá nhân', 'Hồ sơ nhập học', 'Thời khóa biểu','Lịch học','Lớp học phần','Đăng ký học phần','Điểm cá nhân','Lịch thi'].includes(menu)) await screenshot(`${role}-${menus.indexOf(menu)}`);
      await viewport(390, 844); await inspect(`${menu} mobile`, role); await viewport(1440, 1000);
    }
    await viewport(390, 844);
    await run(() => document.querySelector('button[aria-label="Mở menu"]').click());
    await wait('!!document.querySelector(".sidebar-open")'); await screenshot(`${role}-mobile-menu`);
    await run(() => document.querySelector('.mobile-overlay')?.click());
    await run(() => document.querySelector('button[aria-label="Đăng xuất"]').click());
    await wait('!!document.querySelector("input[type=password]")');
  }
  assert.deepEqual(report.runtimeErrors, [], 'No JavaScript exceptions');
  assert.deepEqual(report.issues, [], 'No broken pages, dialogs or overflow');
  console.log(`PASS ${report.database}: ${report.screens.length} screen checks, ${report.dialogs.length} dialogs, ${roles.length} roles`);
} finally {
  await writeFile(path.join(output, 'report.json'), JSON.stringify(report, null, 2));
  ws?.close(); browser.kill(); vite?.kill();
}
