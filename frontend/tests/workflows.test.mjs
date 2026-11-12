import test from "node:test";
import assert from "node:assert/strict";
import { initialState, STUDENT_ID } from "../src/data/portalData.js";
import { normalizeState, roster, invoices, recordPayment, forwardApplication, approveStudent, allocateToFund, createHandover, confirmHandover } from "../src/data/workflows.js";

const fresh = () => normalizeState(structuredClone(initialState));
test("migration preserves registrations, payments and catalogue changes", () => {
  let state = fresh(); state.courses[0] = { ...state.courses[0], name: "Updated course" };
  state = normalizeState(state);
  assert.equal(state.courses[0].name, "Updated course");
  assert.equal(new Set(state.enrollments.map(item => `${item.studentId}:${item.sectionId}`)).size, state.enrollments.length);
  assert.ok(state.payments.every(item => item.invoiceId && item.semester));
  assert.ok(state.users.some(item => item.role === "affairs"));
});
test("roster follows enrollment and removes cancelled registrations", () => {
  let state = fresh();
  assert.ok(roster(state, "SEC-03").some(item => item.id === STUDENT_ID));
  state = normalizeState({ ...state, enrollmentIds: state.enrollmentIds.filter(id => id !== "SEC-03") });
  assert.ok(!roster(state, "SEC-03").some(item => item.id === STUDENT_ID));
});
test("invoice isolates student and semester, payment freezes prices", () => {
  let state = fresh(); const bill = invoices(state).find(item => item.studentId === STUDENT_ID);
  assert.ok(bill.balance > 0);
  state = recordPayment(state, bill.id, 1000);
  const after = invoices(state).find(item => item.id === bill.id);
  assert.equal(after.balance, bill.balance - 1000);
  assert.equal(state.payments.at(-1).invoiceId, bill.id);
  state.courses = state.courses.map(item => ({ ...item, credits: item.credits + 5 }));
  assert.equal(invoices(state).find(item => item.id === bill.id).total, bill.total);
});
test("reject invalid amounts and invoice IDs", () => {
  const state = fresh(); const bill = invoices(state).find(item => item.studentId === STUDENT_ID);
  for (const amount of [0, -1, 0.5, NaN, Infinity, bill.balance + 1]) assert.throws(() => recordPayment(state, bill.id, amount));
  assert.throws(() => recordPayment(state, "missing", 1));
});
test("CTSV forwards once, school approval creates linked student/account/email", () => {
  let state = fresh();
  state.applications = [{ id: "HS-TEST", status: "ACCEPTED", name: "Test Applicant", email: "test@example.com", phone: "0901234567", major: "Công nghệ thông tin", documents: [], history: [] }];
  assert.throws(() => forwardApplication(state, "HS-TEST", "QTKD24A"));
  state = forwardApplication(state, "HS-TEST", "CNTT24B");
  assert.throws(() => forwardApplication(state, "HS-TEST", "CNTT24B"));
  const request = state.studentApprovals.at(-1);
  state = approveStudent(state, request.id, true);
  const student = state.students.find(item => item.id === request.student.id);
  assert.equal(student.className, "CNTT24B");
  assert.ok(student.schoolEmail.endsWith("@student.campus.edu.vn"));
  assert.ok(state.users.some(item => item.studentId === student.id));
  assert.equal(state.applications[0].status, "ENROLLED");
  assert.throws(() => approveStudent(state, request.id, true));
});
test("school rejection requires reason and does not create a student", () => {
  let state = fresh(); const count = state.students.length;
  state.studentApprovals = [{ id: "REQ", status: "PENDING", student: { id: "NEW", name: "Test", email: "test@example.com" } }];
  assert.throws(() => approveStudent(state, "REQ", false));
  state = approveStudent(state, "REQ", false, "Missing evidence");
  assert.equal(state.students.length, count);
  assert.equal(state.studentApprovals[0].reason, "Missing evidence");
});
test("funds cannot allocate payment twice or hand over a receipt twice", () => {
  let state = fresh(); const payment = state.payments[0];
  state = allocateToFund(state, payment.id);
  assert.throws(() => allocateToFund(state, payment.id));
  const receipt = state.fundReceipts[0];
  assert.throws(() => createHandover(state, [receipt.id], ""));
  state = createHandover(state, [receipt.id, receipt.id], "Accounting");
  assert.equal(state.handovers[0].amount, payment.amount);
  assert.equal(state.handovers[0].receiptIds.length, 1);
  assert.throws(() => createHandover(state, [receipt.id], "Accounting"));
  state = confirmHandover(state, state.handovers[0].id);
  assert.equal(state.handovers[0].status, "CONFIRMED");
  assert.throws(() => confirmHandover(state, state.handovers[0].id));
});
