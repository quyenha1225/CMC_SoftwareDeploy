import React, { useState } from "react";
import { STUDENT_ID } from "../../data/portalData.js";
import Icon from "../../components/common/Icon.jsx";
import { Button, Empty, Modal, PageHeader } from "../../components/ui.jsx";
import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import { filterPosts, POST_TYPES } from "../../data/campusPosts.js";
import CampusArticle, { eventDate } from "./CampusArticle.jsx";
import "./Events.css";

export default function Events({ state, update, publicView = false, onOpen, onLogin, search, onSearch }) {
  const [localSearch, setLocalSearch] = useState(""), [category, setCategory] = useState("ALL"), [onlyFollowed, setOnlyFollowed] = useState(false), [detail, setDetail] = useState(null);
  const query = search ?? localSearch;
  const follows = new Set((state.eventFollows || []).filter(item => item.studentId === STUDENT_ID).map(item => item.eventId));
  const rows = filterPosts(state.campusPosts, { query, category }).filter(post => !onlyFollowed || follows.has(post.id));
  const page = usePagination(rows, `${query}:${category}:${onlyFollowed}`, 5);
  function toggle(id) {
    if (publicView) return onLogin?.();
    update(previous => ({ ...previous, eventFollows: follows.has(id) ? previous.eventFollows.filter(item => !(item.studentId === STUDENT_ID && item.eventId === id)) : [...previous.eventFollows, { studentId: STUDENT_ID, eventId: id }] }));
  }
  return <section className={`campus-news ${publicView ? "landing-section" : ""}`} id={publicView ? "events" : undefined}>
    {publicView ? <div className="section-heading"><div><span className="section-kicker">NHỊP SỐNG HỌC ĐƯỜNG</span><h2>Tin tức & Sự kiện</h2></div><p>Kết nối với những hoạt động, hội thảo và thông tin mới từ nhà trường.</p></div> : <PageHeader title="Tin tức & Sự kiện" description="Tìm hoạt động của trường và lưu những sự kiện bạn quan tâm." />}
    <div className="campus-search"><Icon name="search" size={21} /><input aria-label="Tìm tin tức và sự kiện" type="search" placeholder="Tìm hội thảo, sự kiện, thông báo, đơn vị tổ chức…" value={query} onChange={event => (onSearch || setLocalSearch)(event.target.value)} />{query && <button onClick={() => (onSearch || setLocalSearch)("")} aria-label="Xóa tìm kiếm"><Icon name="x" size={18} /></button>}</div>
    <div className="campus-filters"><div>{["ALL", ...POST_TYPES].map(type => <button key={type} aria-pressed={category === type} onClick={() => setCategory(type)}>{type === "ALL" ? "Tất cả thông tin" : type}</button>)}</div>{!publicView && <button aria-pressed={onlyFollowed} onClick={() => setOnlyFollowed(!onlyFollowed)}><Icon name="bell" size={16} />Đang theo dõi ({follows.size})</button>}</div>
    <p className="campus-result" role="status">{rows.length} bài viết{query ? ` phù hợp với “${query}”` : " từ nhà trường"}</p>
    <div className="campus-post-grid">{page.rows.map(post => <article className="campus-post" key={post.id}>
      <div className={`campus-post-art campus-color-${post.category === "Hội thảo" ? "sage" : post.category === "Thông báo" ? "gold" : "green"}`}><span>{post.category}</span><Icon name={post.category === "Thông báo" ? "bell" : post.category === "Hội thảo" ? "bookopen" : "graduation"} size={54} /><small>EDUPORTAL · CAMPUS LIFE</small></div>
      <div className="campus-post-body"><p className="campus-post-date"><Icon name="calendar" size={16} />{eventDate(post.startsAt)}</p><h3><button onClick={() => onOpen ? onOpen(post.id) : setDetail(post.id)}>{post.title}</button></h3><p>{post.summary}</p><span className="campus-venue"><Icon name="building" size={16} />{post.venue}</span><div className="campus-post-actions"><button onClick={() => onOpen ? onOpen(post.id) : setDetail(post.id)}>Xem chi tiết <Icon name="arrow" size={16} /></button><button aria-label={`${follows.has(post.id) && !publicView ? "Bỏ theo dõi" : "Theo dõi"} ${post.title}`} aria-pressed={!publicView && follows.has(post.id)} onClick={() => toggle(post.id)}><Icon name={!publicView && follows.has(post.id) ? "checkcircle" : "bell"} size={18} />{!publicView && follows.has(post.id) ? "Đã theo dõi" : publicView ? "Đăng nhập để theo dõi" : "Theo dõi"}</button></div></div>
    </article>)}</div>
    {!rows.length && <Empty icon="search" title="Chưa tìm thấy thông tin phù hợp" description="Thử từ khóa khác hoặc chọn Tất cả thông tin." />}<Pagination {...page} />
    {detail && state.campusPosts.some(post => post.id === detail && post.status === "PUBLISHED") && <Modal title="Thông tin sự kiện" wide onClose={() => setDetail(null)}><CampusArticle post={state.campusPosts.find(post => post.id === detail)} followed={follows.has(detail)} onFollow={() => toggle(detail)} /></Modal>}
  </section>;
}
