import test from 'node:test';
import assert from 'node:assert/strict';

test('V6 API uses server CSRF, credentials and JSON bodies',async()=>{
  const calls=[];
  const original=globalThis.fetch;
  globalThis.fetch=async(path,options)=>{calls.push({path,options});return new Response(JSON.stringify(path.endsWith('/csrf')?{token:'csrf-test',headerName:'X-XSRF-TOKEN'}:{id:7}),{status:200});};
  try{const {api}=await import('../src/v6/api.js?csrf');await api('/payments',{method:'POST',body:{amount:100}});await api('/requests',{method:'POST',body:{content:'test'}});assert.equal(calls.length,3);assert.equal(calls[1].options.credentials,'same-origin');assert.equal(calls[1].options.headers['X-XSRF-TOKEN'],'csrf-test');assert.deepEqual(JSON.parse(calls[1].options.body),{amount:100});}finally{globalThis.fetch=original;}
});

test('V6 failed API does not fall back to local data and expires session',async()=>{
  const original=globalThis.fetch,oldWindow=globalThis.window;
  let event;
  globalThis.window={dispatchEvent(value){event=value;}};
  globalThis.fetch=async()=>new Response(JSON.stringify({message:'Session expired'}),{status:401});
  try{const {api}=await import('../src/v6/api.js?expired');await assert.rejects(api('/resources/grades'),error=>error.status===401&&error.message==='Session expired');assert.equal(event.type,'session-expired');}finally{globalThis.fetch=original;globalThis.window=oldWindow;}
});

test('V6 sends uploaded files as FormData without a JSON content type',async()=>{
  const original=globalThis.fetch;let uploaded;
  globalThis.fetch=async(path,options)=>{if(path.endsWith('/csrf'))return new Response(JSON.stringify({token:'t',headerName:'X-XSRF-TOKEN'}));uploaded=options;return new Response(null,{status:204});};
  try{const {api}=await import('../src/v6/api.js?upload');const body=new FormData();body.append('file',new Blob(['%PDF-content']),'paper.pdf');await api('/admissions/1/documents',{method:'POST',body});assert.equal(uploaded.body,body);assert.equal(uploaded.headers['Content-Type'],undefined);}finally{globalThis.fetch=original;}
});


test('V6 SQL dates display as local calendar values without timezone conversion',async()=>{
  const {display}=await import('../src/v6/api.js');
  assert.equal(display('2026-11-12','date_of_birth'),'12/11/2026');
  assert.equal(display('2026-11-12T07:30:00','created_at'),'12/11/2026 07:30');
  assert.equal(display('07:30:00','starts_at'),'07:30:00');
});
