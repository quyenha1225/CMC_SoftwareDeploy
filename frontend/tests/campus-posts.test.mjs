import test from "node:test";
import assert from "node:assert/strict";
import { campusPosts, filterPosts, savePost } from "../src/data/campusPosts.js";

test("public search ignores Vietnamese accents and searches content and location", () => {
  assert.ok(filterPosts(campusPosts, { query: "tri tue nhan tao" }).some(post => post.id === "EVT-AI-2026"));
  assert.ok(filterPosts(campusPosts, { query: "B201" }).some(post => post.id === "EVT-AI-2026"));
  assert.equal(filterPosts(campusPosts, { query: "missing-phrase" }).length, 0);
});
test("draft stays private until published and existing post edits preserve ID", () => {
  const draft = { ...campusPosts[0], id: undefined, title: "Draft workshop" };
  let posts = savePost([], draft, "DRAFT");
  assert.equal(filterPosts(posts).length, 0);
  const id = posts[0].id;
  posts = savePost(posts, posts[0], "PUBLISHED");
  assert.equal(posts[0].id, id);
  assert.equal(filterPosts(posts).length, 1);
  posts = savePost(posts, { ...posts[0], title: "Updated workshop" }, "PUBLISHED");
  assert.equal(posts.length, 1);
  assert.equal(posts[0].title, "Updated workshop");
});
test("event validation rejects missing fields and reversed dates", () => {
  assert.throws(() => savePost([], { ...campusPosts[0], title: "" }, "PUBLISHED"));
  assert.throws(() => savePost([], { ...campusPosts[0], endsAt: "2020-01-01T00:00" }, "PUBLISHED"));
});
