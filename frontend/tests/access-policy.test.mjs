import test from "node:test";
import assert from "node:assert/strict";
import { canViewPage } from "../src/data/accessPolicy.js";

test("student navigation excludes administrative pages", () => {
  for (const page of ["accounts", "settings", "student-approvals", "catalog", "finance", "funds", "manage-events", "unknown"]) assert.equal(canViewPage("student", page), false);
  for (const page of ["dashboard", "payment", "enrollment", "grades", "profile-view"]) assert.equal(canViewPage("student", page), true);
});
test("staff navigation follows assigned functions and rejects unknown roles", () => {
  assert.equal(canViewPage("principal", "accounts"), true);
  assert.equal(canViewPage("training", "accounts"), false);
  assert.equal(canViewPage("lecturer", "grade-entry"), true);
  assert.equal(canViewPage("affairs", "applications"), true);
  assert.equal(canViewPage("unknown", "dashboard"), false);
});
