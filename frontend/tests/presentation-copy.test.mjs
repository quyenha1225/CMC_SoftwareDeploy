import test from "node:test";
import assert from "node:assert/strict";
import { cleanPresentationCopy } from "../src/data/presentationCopy.js";
import { normalizeState } from "../src/data/workflows.js";
import { initialState } from "../src/data/portalData.js";

test("legacy labels are cleaned without changing identifiers or attachments", () => {
  const old = { id: "DEMO-1", documents: [{ data: "data:application/pdf;base64,demo", name: "sample.pdf" }], payments: [{ method: "Ghi nhận thủ công (demo)", note: "Khoản thu giả lập" }], email: "person.demo@campus.edu.vn" };
  const result = cleanPresentationCopy(old);
  assert.equal(result.id, old.id);
  assert.equal(result.documents[0].data, old.documents[0].data);
  assert.equal(result.payments[0].method, "Ghi nhận thủ công");
  assert.equal(result.payments[0].note, "Khoản nộp học phí");
  assert.equal(result.email, "person@campus.edu.vn");
});
test("migration runs once and preserves subsequent user data", () => {
  const first = normalizeState(structuredClone(initialState));
  assert.equal(first.presentationCopyVersion, 1);
  first.payments[0].note = "Nội dung do người dùng nhập";
  const second = normalizeState(first);
  assert.equal(second.payments[0].note, first.payments[0].note);
});
