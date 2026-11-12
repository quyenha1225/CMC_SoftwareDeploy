import React from "react";
import Icon from "../../components/common/Icon.jsx";
import "./Events.css";

export const eventDate = value => value ? new Date(value).toLocaleString("vi-VN", { dateStyle: "long", timeStyle: "short" }) : "Chưa cập nhật";
export default function CampusArticle({ post, followed, onFollow }) {
  return <article className="campus-article">
    <div className={`campus-article-banner campus-color-${post.category === "Hội thảo" ? "sage" : post.category === "Thông báo" ? "gold" : "green"}`}><Icon name={post.category === "Thông báo" ? "bell" : "graduation"} size={46} /><span>{post.category}</span><h1>{post.title}</h1></div>
    <div className="campus-article-body"><p className="campus-lead">{post.summary}</p>
      <dl className="campus-facts"><div><dt>Thời gian bắt đầu</dt><dd>{eventDate(post.startsAt)}</dd></div><div><dt>Kết thúc</dt><dd>{eventDate(post.endsAt)}</dd></div><div><dt>Địa điểm</dt><dd>{post.venue}</dd></div><div><dt>Đơn vị tổ chức</dt><dd>{post.organizer}</dd></div></dl>
      {onFollow && <button className={`campus-follow ${followed ? "is-followed" : ""}`} aria-pressed={followed} onClick={onFollow}><Icon name={followed ? "checkcircle" : "bell"} size={18} />{followed ? "Đang theo dõi · Bỏ theo dõi" : "Theo dõi sự kiện"}</button>}
      <div className="campus-article-text">{post.content}</div>
      <p className="campus-updated">Cập nhật: {eventDate(post.updatedAt || post.publishedAt)}</p>
    </div>
  </article>;
}
