import React from "react";
import { createRoot } from "react-dom/client";
import App from "./v6/AppV6.jsx";
import WelcomeAnimation from "./v6/WelcomeAnimation.jsx";
import "./index.css";

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <WelcomeAnimation><App /></WelcomeAnimation>
  </React.StrictMode>,
);
