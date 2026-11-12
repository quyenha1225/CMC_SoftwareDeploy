import React, { useState } from "react";
import "./Pagination.css";

export function usePagination(items, resetKey = "", initialSize = 10) {
  const [settings, setSettings] = useState({ page: 1, size: initialSize, key: resetKey });
  const totalPages = Math.max(1, Math.ceil(items.length / settings.size));
  const page = settings.key === resetKey ? Math.min(settings.page, totalPages) : 1;
  const start = (page - 1) * settings.size;
  return { rows: items.slice(start, start + settings.size), page, pageSize: settings.size, total: items.length, totalPages,
    onPage: value => setSettings({ ...settings, page: Math.max(1, Math.min(value, totalPages)), key: resetKey }),
    onSize: size => setSettings({ page: 1, size, key: resetKey }),
  };
}

export default function Pagination({ page, pageSize, total, totalPages, onPage, onSize }) {
  return <nav className="pagination" aria-label="Phân trang dữ liệu">
    <span>{total ? `${(page - 1) * pageSize + 1}–${Math.min(page * pageSize, total)}` : "0"} / {total} bản ghi</span>
    <label>Số dòng <select value={pageSize} onChange={event => onSize(Number(event.target.value))}>{[5, 10, 20, 50].map(size => <option key={size}>{size}</option>)}</select></label>
    <div className="pagination-controls"><button disabled={page === 1} onClick={() => onPage(1)} aria-label="Trang đầu">«</button><button disabled={page === 1} onClick={() => onPage(page - 1)} aria-label="Trang trước">‹</button>
      {Array.from({ length: Math.min(5, totalPages) }, (_, index) => Math.max(1, Math.min(page - 2, totalPages - 4)) + index).map(value => <button key={value} aria-current={value === page ? "page" : undefined} onClick={() => onPage(value)}>{value}</button>)}
      <button disabled={page === totalPages} onClick={() => onPage(page + 1)} aria-label="Trang sau">›</button><button disabled={page === totalPages} onClick={() => onPage(totalPages)} aria-label="Trang cuối">»</button></div>
  </nav>;
}
