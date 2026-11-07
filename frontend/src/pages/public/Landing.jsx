import React from "react";
import AppFooter from "../../components/landing/SiteFooter.jsx";
import LandingHero from "../../components/landing/LandingHero.jsx";
import PublicHeader from "../../components/landing/PublicHeader.jsx";
import RegulationsSection from "../../components/landing/RegulationsSection.jsx";
import StudentServices from "../../components/landing/StudentServices.jsx";
import TrainingSection from "../../components/landing/TrainingSection.jsx";
import UsageGuide from "../../components/landing/UsageGuide.jsx";
import "../../styles/public-site.css";
import "./Landing.css";

export default function Landing({ onLogin }) {
  return (
    <div className="public-site" id="top">
      <PublicHeader onLogin={onLogin} />
      <main>
        <LandingHero onLogin={onLogin} />
        <TrainingSection onLogin={onLogin} />
        <StudentServices onLogin={onLogin} />
        <RegulationsSection onLogin={onLogin} />
        <UsageGuide onLogin={onLogin} />
      </main>
      <AppFooter />
    </div>
  );
}
