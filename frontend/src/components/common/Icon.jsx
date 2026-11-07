import React from "react";
const paths = {
  database: (
    <>
      <ellipse cx="12" cy="5" rx="9" ry="3" />
      <path d="M3 5v14c0 1.7 4 3 9 3s9-1.3 9-3V5M3 12c0 1.7 4 3 9 3s9-1.3 9-3" />
    </>
  ),
  dashboard: (
    <>
      <rect x="3" y="3" width="7" height="9" rx="1.5" />
      <rect x="14" y="3" width="7" height="5" rx="1.5" />
      <rect x="14" y="12" width="7" height="9" rx="1.5" />
      <rect x="3" y="16" width="7" height="5" rx="1.5" />
    </>
  ),
  book: (
    <>
      <path d="M4 19.5A2.5 2.5 0 016.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2z" />
    </>
  ),
  calendar: (
    <>
      <rect x="3" y="5" width="18" height="16" rx="2" />
      <path d="M16 3v4M8 3v4M3 10h18" />
    </>
  ),
  clock: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 2" />
    </>
  ),
  grades: (
    <>
      <path d="M8 3H5a2 2 0 00-2 2v16h18V5a2 2 0 00-2-2h-3" />
      <rect x="8" y="2" width="8" height="4" rx="1" />
      <path d="M8 12h8M8 16h5" />
    </>
  ),
  wallet: (
    <>
      <rect x="3" y="6" width="18" height="15" rx="2" />
      <path d="M3 9V5a2 2 0 012-2h14M15 13h6v4h-6a2 2 0 010-4z" />
    </>
  ),
  file: (
    <>
      <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z" />
      <path d="M14 2v6h6M8 13h8M8 17h8" />
    </>
  ),
  bell: (
    <>
      <path d="M18 8a6 6 0 00-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" />
    </>
  ),
  user: (
    <>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21a8 8 0 0116 0" />
    </>
  ),
  users: (
    <>
      <path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2M18 7a4 4 0 010 8M22 21v-2a4 4 0 00-3-3.87" />
      <circle cx="9" cy="7" r="4" />
    </>
  ),
  chart: (
    <>
      <path d="M3 3v18h18M7 16v-4M12 16V7M17 16v-7" />
    </>
  ),
  shield: (
    <>
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10" />
      <path d="m9 12 2 2 4-4" />
    </>
  ),
  gear: (
    <>
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.7 1.7 0 00.35 1.87l.03.03-2.88 2.88-.03-.03A1.7 1.7 0 0015 19.4a1.7 1.7 0 00-1.1 1.6v.05H10v-.05A1.7 1.7 0 008.9 19.4a1.7 1.7 0 00-1.87.35L7 19.78l-2.78-2.88.03-.03A1.7 1.7 0 004.6 15a1.7 1.7 0 00-1.6-1.1H3V10h.05A1.7 1.7 0 004.6 8.9a1.7 1.7 0 00-.35-1.87L4.22 7 7 4.22l.03.03A1.7 1.7 0 008.9 4.6 1.7 1.7 0 0010 3V3h3.9v.05A1.7 1.7 0 0015 4.6a1.7 1.7 0 001.87-.35l.03-.03L19.78 7l-.03.03A1.7 1.7 0 0019.4 8.9a1.7 1.7 0 001.6 1.1H21v3.9h-.05A1.7 1.7 0 0019.4 15z" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="7" />
      <path d="m20 20-4-4" />
    </>
  ),
  arrow: (
    <>
      <path d="M5 12h14m-6-6 6 6-6 6" />
    </>
  ),
  chevron: (
    <>
      <path d="m9 18 6-6-6-6" />
    </>
  ),
  down: (
    <>
      <path d="m6 9 6 6 6-6" />
    </>
  ),
  plus: (
    <>
      <path d="M12 5v14M5 12h14" />
    </>
  ),
  check: (
    <>
      <path d="m4 12 5 5 11-11" />
    </>
  ),
  x: (
    <>
      <path d="M18 6 6 18M6 6l12 12" />
    </>
  ),
  alert: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v6M12 17h.01" />
    </>
  ),
  filter: (
    <>
      <path d="M3 5h18l-7 8v6l-4 2v-8z" />
    </>
  ),
  download: (
    <>
      <path d="M12 3v12m-4-4 4 4 4-4M4 17v4h16v-4" />
    </>
  ),
  edit: (
    <>
      <path d="m15 5 4 4M4 20l4.8-1.1L20 7.7 16.3 4 5.1 15.2 4 20z" />
    </>
  ),
  send: (
    <>
      <path d="m22 2-7 20-4-9-9-4zM22 2 11 13" />
    </>
  ),
  home: (
    <>
      <path d="m3 10 9-7 9 7v11H3zM9 21v-7h6v7" />
    </>
  ),
  graduation: (
    <>
      <path d="m2 10 10-5 10 5-10 5-10-5zM6 12v5c4 3 8 3 12 0v-5M22 10v7" />
    </>
  ),
  menu: (
    <>
      <path d="M4 6h16M4 12h16M4 18h16" />
    </>
  ),
  logout: (
    <>
      <path d="M10 3H5a2 2 0 00-2 2v14a2 2 0 002 2h5M14 7l5 5-5 5M19 12H9" />
    </>
  ),
  close: (
    <>
      <path d="M18 6 6 18M6 6l12 12" />
    </>
  ),
  refresh: (
    <>
      <path d="M20 11a8 8 0 10-2.3 6M20 4v7h-7" />
    </>
  ),
  checkcircle: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m8 12 3 3 5-6" />
    </>
  ),
  sparkle: (
    <>
      <path d="m12 3 2.3 6.7L21 12l-6.7 2.3L12 21l-2.3-6.7L3 12l6.7-2.3z" />
    </>
  ),
  building: (
    <>
      <rect x="3" y="6" width="18" height="15" rx="1" />
      <path d="M8 6V3h8v3M7 10h2M15 10h2M7 14h2M15 14h2M10 21v-5h4v5" />
    </>
  ),
  list: (
    <>
      <path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" />
    </>
  ),
  copy: (
    <>
      <rect x="8" y="8" width="13" height="13" rx="2" />
      <path d="M16 8V5a2 2 0 00-2-2H5a2 2 0 00-2 2v9a2 2 0 002 2h3" />
    </>
  ),
  moon: (
    <>
      <path d="M20 16.5A8.5 8.5 0 017.5 4 8.5 8.5 0 1020 16.5z" />
    </>
  ),
  info: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v6M12 7h.01" />
    </>
  ),
  bookopen: (
    <>
      <path d="M12 7a7 7 0 00-9-2v14a7 7 0 019 2 7 7 0 019-2V5a7 7 0 00-9 2zM12 7v14" />
    </>
  ),
  more: (
    <>
      <circle cx="5" cy="12" r="1" />
      <circle cx="12" cy="12" r="1" />
      <circle cx="19" cy="12" r="1" />
    </>
  ),
  mail: (
    <>
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="m3 7 9 6 9-6" />
    </>
  ),
};
export default function Icon({
  name = "info",
  size = 20,
  strokeWidth = 1.8,
  className = "",
  ...rest
}) {
  return (
    <svg
      aria-hidden="true"
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      {...rest}
    >
      {paths[name] || paths.info}
    </svg>
  );
}
