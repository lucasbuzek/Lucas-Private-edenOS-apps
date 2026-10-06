import React from "react";

export const HERMES_STATES = ["IDLE","QUEUED","ACTIVE","WAITING","BLOCKED","QA","COMPLETE","FAILED","RECOVERING"];

export default function HermesSignal({state="IDLE", worker="HERMES", size=34, label=true, onClick, className=""}) {
  const normalized = HERMES_STATES.includes(state) ? state : "IDLE";
  const active = normalized === "ACTIVE" || normalized === "RECOVERING";
  return <button
    type="button"
    className={`hermesSignal signal-${normalized.toLowerCase()} ${active?"signal-live":""} ${className}`}
    onClick={onClick}
    aria-label={`HERMES ${normalized}${worker && worker!=="HERMES" ? ` — ${worker}`:""}`}
    aria-live={active?"polite":"off"}
  >
    <svg width={size} height={size} viewBox="0 0 64 64" role="img" aria-hidden="true">
      <defs><clipPath id="hermes-wing-clip"><path d="M13 35c9-17 22-25 40-24-5 6-10 10-16 13 7-1 12 0 16 2-7 7-14 11-23 12 5 2 9 5 12 9-12 1-21-3-27-9z"/></clipPath></defs>
      <path className="signal-outline" d="M13 35c9-17 22-25 40-24-5 6-10 10-16 13 7-1 12 0 16 2-7 7-14 11-23 12 5 2 9 5 12 9-12 1-21-3-27-9z"/>
      <g clipPath="url(#hermes-wing-clip)">
        <rect className="signal-red" x="8" y="8" width="50" height="14"/>
        <rect className="signal-gold" x="8" y="22" width="50" height="14"/>
        <rect className="signal-green" x="8" y="36" width="50" height="18"/>
      </g>
      <path className="signal-paper" d="M18 31h18v21H18z"/>
      <path className="signal-check" d="m22 42 4 4 7-9"/>
    </svg>
    {label && <span className="signalText"><b>HERMES</b><small>{worker!=="HERMES"?`${worker} · `:""}{normalized}</small></span>}
  </button>;
}
