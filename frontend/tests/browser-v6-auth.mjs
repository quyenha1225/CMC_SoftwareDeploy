// Optional UI smoke test: uses the locally installed Chrome, no extra npm packages.
import { spawn } from "node:child_process";
import { mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import assert from "node:assert/strict";



const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const profile = await mkdtemp(path.join(os.tmpdir(), "eduportal-smoke-"));
const browser = spawn(process.env.CHROME_PATH || "C:/Program Files/Google/Chrome/Application/chrome.exe", ["--headless=new", "--no-sandbox", "--disable-gpu", "--disable-software-rasterizer", "--no-first-run", "--remote-debugging-port=9225", `--user-data-dir=${profile}`, "about:blank"], { windowsHide: true, stdio: "ignore" });
let ws;
try {
  let targets;
  for (let attempt = 0; attempt < 40; attempt++) { try { targets = await fetch("http://127.0.0.1:9225/json").then(response => response.json()); break; } catch {} await sleep(150); }
  if (!targets) throw new Error("Chrome unavailable. Set CHROME_PATH to a local Chrome executable.");
  ws = new WebSocket(targets.find(target => target.type === "page").webSocketDebuggerUrl);
  await new Promise(resolve => ws.addEventListener("open", resolve, { once: true }));
  let id = 0; const pending = new Map(), errors = [];
  ws.onmessage = event => { const message = JSON.parse(event.data); if (message.method === "Runtime.exceptionThrown") errors.push(message.params.exceptionDetails.exception?.description || message.params.exceptionDetails.text); if (pending.has(message.id)) { pending.get(message.id)(message); pending.delete(message.id); } };
  const call = (method, params = {}) => new Promise(resolve => { const current = ++id; pending.set(current, resolve); ws.send(JSON.stringify({ id: current, method, params })); });
  const evaluate = async expression => { const response = await call("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true }); if (response.result.exceptionDetails) throw new Error(response.result.exceptionDetails.exception?.description || response.result.exceptionDetails.text); return response.result.result.value; };
  const run = (fn, ...args) => evaluate(`(${fn.toString()})(...${JSON.stringify(args)})`);
  const wait = async expression => { for (let attempt = 0; attempt < 60; attempt++) { if (await evaluate(expression)) return; await sleep(100); } throw new Error(`Timed out: ${expression}`); };
  const click = async (text, selector = "button") => { const result = await run((text, selector) => { const button = [...document.querySelectorAll(selector)].find(element => (element.classList.contains("nav-item") ? element.querySelector("span").textContent : element.textContent).trim() === text); if (!button) return false; button.click(); return true; }, text, selector); assert.ok(result, `Missing button: ${text}`); await sleep(150); };
  const select = async (selector, value) => { await run((selector, value) => { const element = document.querySelector(selector); Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, "value").set.call(element, value); element.dispatchEvent(new Event("change", { bubbles: true })); }, selector, value); await sleep(200); };
  const input = async (selector, value) => run((selector, value) => { const element = document.querySelector(selector); Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set.call(element, value); element.dispatchEvent(new Event("input", { bubbles: true })); }, selector, value);
  const nav = async text => { await wait(`[...document.querySelectorAll('.navigation button')].some(item => (item.classList.contains("nav-item") ? item.querySelector("span").textContent : item.textContent).trim() === ${JSON.stringify(text)})`); await click(text, ".navigation button"); await wait("!!document.querySelector('.page-content h1')"); await sleep(200); assert.ok(await run(() => !/\b(demo|frontend|backend|localStorage)\b|mô phỏng|dữ liệu mẫu/i.test(document.body.innerText)), `Technical labels remain on ${text}`); };
  await call("Runtime.enable");await call("Page.enable");
  await call("Emulation.setDeviceMetricsOverride",{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
  await call("Page.navigate",{url:"http://127.0.0.1:5173"});
  await wait("!!document.querySelector('.public-login-button')");
  await click("Đăng nhập",".public-login-button");
  await wait("!!document.querySelector('.login-campus-photo')");await sleep(850);
  assert.equal(await evaluate("document.querySelectorAll('input').length"),2);
  assert.equal(await evaluate("document.querySelector('.login-campus-photo').naturalWidth>0"),true);
  assert.equal(await evaluate("/Đăng ký tài khoản|Đăng ký ứng viên|Tạo tài khoản ứng viên/.test(document.body.innerText)"),false);
  assert.equal(await evaluate("document.documentElement.scrollWidth<=innerWidth"),true);
  const desktop=await call("Page.captureScreenshot",{format:"png"});await writeFile('../screenshots/v6-login-desktop.png',Buffer.from(desktop.result.data,'base64'));
  await call("Emulation.setDeviceMetricsOverride",{width:390,height:844,deviceScaleFactor:1,mobile:true});await sleep(250);
  assert.equal(await evaluate("document.documentElement.scrollWidth<=innerWidth"),true);
  const mobile=await call("Page.captureScreenshot",{format:"png",captureBeyondViewport:true});await writeFile('../screenshots/v6-login-mobile.png',Buffer.from(mobile.result.data,'base64'));
  await click("Quên mật khẩu?", ".auth-text-button");await wait("!!document.querySelector('input[type=email]')");
  assert.equal(await evaluate("document.querySelectorAll('input[type=password]').length"),0);
  await call("Emulation.setDeviceMetricsOverride",{width:1440,height:1000,deviceScaleFactor:1,mobile:false});await sleep(200);
  const recovery=await call("Page.captureScreenshot",{format:"png"});await writeFile('../screenshots/v6-forgot-password.png',Buffer.from(recovery.result.data,'base64'));
  await call("Page.navigate",{url:"http://127.0.0.1:5173/#reset-password/"+'a'.repeat(43)});await wait("document.querySelectorAll('input[type=password]').length===2");
  assert.deepEqual(errors,[]);console.log('PASS: desktop/mobile login, image, no standalone registration, no runtime exceptions');
}finally{ws?.close();browser.kill();}
