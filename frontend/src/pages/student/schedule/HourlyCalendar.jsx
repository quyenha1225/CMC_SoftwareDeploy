import React from "react";
import Icon from "../../../components/common/Icon.jsx";
import { getCourse, WEEKDAYS } from "../../../data/portalData.js";
import "./HourlyCalendar.css";

const START = 7 * 60;
const END = 19 * 60;
const minutes = time => {
  const [hours, mins] = time.split(":").map(Number);
  return hours * 60 + mins;
};

// Assign a separate lane to simultaneous classes, within each overlapping group.
function positionClasses(sections) {
  const events = sections.map(section => ({ section, start: Math.max(START, minutes(section.start)), end: Math.min(END, minutes(section.end)) }))
    .filter(event => event.start < event.end).sort((a, b) => a.start - b.start || a.end - b.end);
  let group = [], groupEnd = START, lanes = [];
  const result = [];
  const flush = () => group.forEach(event => result.push({ ...event, columns: lanes.length }));
  events.forEach(event => {
    if (group.length && event.start >= groupEnd) { flush(); group = []; lanes = []; }
    let lane = lanes.findIndex(end => end <= event.start);
    if (lane < 0) lane = lanes.length;
    lanes[lane] = event.end;
    group.push({ ...event, lane });
    groupEnd = group.length === 1 ? event.end : Math.max(groupEnd, event.end);
  });
  flush();
  return result;
}

export default function HourlyCalendar({ state, dates, classesFor, onSelect }) {
  return <div className="hourly-scroll" aria-label="Lịch học theo giờ từ 07:00 đến 19:00">
    <div className="hourly-calendar">
      <div className="hourly-heading hourly-corner">Giờ học</div>
      {dates.map(date => <div className="hourly-heading" key={date.toISOString()}>
        <span>{WEEKDAYS[(date.getDay() + 6) % 7]}</span>
        <b>{date.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" })}</b>
      </div>)}
      <div className="hourly-axis">
        {Array.from({ length: 13 }, (_, index) => <span key={index} style={{ top: `${index / 12 * 100}%` }}>{String(index + 7).padStart(2, "0")}:00</span>)}
      </div>
      {dates.map(date => <div className="hourly-day" key={date.toISOString()}>
        {positionClasses(classesFor(date, "00:00", "24:00")).map(({ section, start, end, lane, columns }) => <button
          type="button" key={section.id} className="hourly-event" aria-haspopup="dialog"
          aria-label={`${getCourse(section.courseId, state)?.name}, ${section.start} đến ${section.end}, phòng ${section.room}`}
          style={{ "--tile": section.color || "#287860", top: `${(start - START) / (END - START) * 100}%`, height: `calc(${(end - start) / (END - START) * 100}% - 4px)`, left: `calc(${lane / columns * 100}% + 4px)`, width: `calc(${100 / columns}% - 8px)` }}
          onClick={() => onSelect(section)}>
          <strong>{getCourse(section.courseId, state)?.name}</strong>
          <span className="hourly-code">{section.code}</span>
          <span><Icon name="clock" size={13} />{section.start}–{section.end}</span>
          <span><Icon name="building" size={13} />{section.room}</span>
        </button>)}
      </div>)}
    </div>
  </div>;
}
