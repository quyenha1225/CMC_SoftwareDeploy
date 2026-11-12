import React from 'react';
import Icon from '../components/common/Icon.jsx';

export default function OverviewOrbit({ center = 'building' }) {
  return (
    <div className="overview-orbit" aria-hidden="true">
      <div className="overview-orbit-ring" />
      <div className="overview-orbit-ring overview-orbit-ring-inner" />
      <div className="overview-orbit-center"><Icon name={center} size={58} /></div>
      <div className="overview-orbit-track">
        {['graduation', 'bookopen', 'checkcircle'].map((icon, index) => (
          <div className="overview-orbit-slot" key={icon} style={{ '--angle': `${index * 120 + 25}deg` }}>
            <span className={`overview-orbit-chip overview-orbit-chip-${index}`}><Icon name={icon} size={26} /></span>
          </div>
        ))}
      </div>
    </div>
  );
}
