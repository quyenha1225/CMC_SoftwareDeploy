import React, { useEffect, useRef } from "react";
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
  const landingRef = useRef(null);
  useEffect(() => {
    if (!window.IntersectionObserver || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const elements = landingRef.current.querySelectorAll(".section-heading, .program-card, .student-service-card, .regulation-list article, .guide-grid article");
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(({ target, isIntersecting }) => {
        if (!isIntersecting) return;
        target.dataset.reveal = "visible";
        observer.unobserve(target);
      });
    }, { threshold: 0.12 });
    elements.forEach((element, index) => {
      element.style.setProperty("--reveal-delay", `${(index % 3) * 75}ms`);
      element.dataset.reveal = "pending";
      observer.observe(element);
    });
    return () => {
      observer.disconnect();
      elements.forEach(element => delete element.dataset.reveal);
    };
  }, []);
  return (
    <div className="public-site" id="top" ref={landingRef}>
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
