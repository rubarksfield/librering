"use strict";

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];

const journeys = {
  onboarding: {
    title: "Pair a ring",
    purpose: "Start with the privacy promise, then pair only when the benefit and permission are clear.",
    evidence: "Permission rationale and bounded progress",
    constraint: "Unsupported firmware fails closed",
    screens: ["welcome", "privacy", "permission", "scan", "found", "sync", "calibration", "today"],
  },
  morning: {
    title: "Read the morning",
    purpose: "Answer what changed in five seconds, with scores subordinate to a plain-language conclusion.",
    evidence: "Three signals, three confidence labels",
    constraint: "No firmware HRV or sleep-stage claims",
    screens: ["today", "sleep", "recovery", "movement"],
  },
  evidence: {
    title: "Inspect evidence",
    purpose: "Separate result strength from data confidence and make missing evidence visible rather than punitive.",
    evidence: "Coverage, source, window, calculation ID",
    constraint: "No result below the coverage threshold",
    screens: ["evidence", "states", "no-result"],
  },
  swim: {
    title: "Log a swim",
    purpose: "Let structured activity count without pretending the R12 measured underwater details.",
    evidence: "You logged · pool · 38 minutes",
    constraint: "No laps, strokes, pace, SWOLF, or underwater HR",
    screens: ["log-menu", "swim-form", "swim-review", "swim-saved"],
  },
  trends: {
    title: "Check a trend",
    purpose: "Show personal direction and coverage over 30 days, including explicit gaps and a baseline corridor.",
    evidence: "25 of 30 reliable nights",
    constraint: "A gap is no value, never zero",
    screens: ["trends", "trend-detail", "trend-gap"],
  },
  device: {
    title: "Resolve a sync issue",
    purpose: "Preserve stored data, name the likely QRing ownership conflict carefully, and retry without duplicates.",
    evidence: "Last complete sync and preserved range",
    constraint: "No blame, force-close, deletion, or duplicate import",
    screens: ["device-issue", "device-checks", "device-sync", "device-success"],
  },
  export: {
    title: "Export your data",
    purpose: "Preview exact scope, format, row count, and checksum before saving a portable local export.",
    evidence: "Range, provenance columns, 2,184 rows",
    constraint: "No account or cloud upload required",
    screens: ["data-hub", "export-options", "export-preview", "export-complete"],
  },
  cycle: {
    title: "Review Cycle Context",
    purpose: "Make reproductive context optional, local, separately deletable, and explicit about non-inference.",
    evidence: "User-declared context only",
    constraint: "No inferred pregnancy, fertility, or clinical advice",
    screens: ["cycle-off", "cycle-privacy", "cycle-modes", "cycle-home", "pregnancy", "cycle-delete"],
  },
};

const state = {
  journey: "onboarding",
  step: 0,
  selectedCycleMode: "track",
  exportFormat: "csv",
  toast: "",
  flow: "jump",
};

const iconPaths = {
  today: '<path d="M4.5 12a7.5 7.5 0 1 0 15 0 7.5 7.5 0 0 0-15 0Z"/><path d="M12 8.2v4.3l2.8 1.7"/>',
  trends: '<path d="M4 17.5 9.2 12l3.2 3.2L20 7.5"/><path d="M14.5 7.5H20V13"/>',
  you: '<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z"/><path d="M4.8 20c.7-3.4 3.2-5.4 7.2-5.4s6.5 2 7.2 5.4"/>',
  back: '<path d="m14.5 5.5-6.5 6.5 6.5 6.5"/>',
  log: '<path d="M12 5v14M5 12h14"/>',
  ring: '<path d="M12 3.8 20.2 12 12 20.2 3.8 12 12 3.8Z"/><path d="M8.2 12h7.6"/>',
};

const icon = (name) => `
  <svg class="ui-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
    ${iconPaths[name] || '<circle cx="12" cy="12" r="1.5"/>'}
  </svg>`;

const brandGlyph = () => `
  <span class="brand-mark" aria-hidden="true">
    <svg class="brand-glyph" viewBox="0 0 48 48" focusable="false">
      <path class="glyph-arc glyph-arc--outer" d="M36.8 10.5A17 17 0 1 0 39 33" />
      <path class="glyph-arc glyph-arc--middle" d="M31.2 15.2A11.5 11.5 0 1 0 34.2 30" />
      <path class="glyph-arc glyph-arc--inner" d="M26.4 20A6 6 0 1 0 28 27" />
      <circle class="glyph-node" cx="38.5" cy="9.5" r="2.2" />
    </svg>
  </span>`;

const brandLockup = () => `
  <span class="brand-lockup">
    ${brandGlyph()}
    <span class="brand-copy">
      <span class="brand-word" aria-label="LibreRing"><em aria-hidden="true">Libre</em><strong aria-hidden="true">Ring</strong></span>
      <span class="brand-tagline">Signals, made legible.</span>
    </span>
  </span>`;

const statusBar = (right = "68%") => `
  <div class="statusbar">
    <b>7:42</b>
    <span>Demo data · ${right}</span>
  </div>`;

const header = (title, subtitle = "", back = true) => `
  <div class="screen-head">
    ${back ? `<button class="icon-button" type="button" data-action="back" aria-label="Go back">${icon("back")}</button>` : ""}
    <div style="flex:1">
      <h1>${title}</h1>
      ${subtitle ? `<p>${subtitle}</p>` : ""}
    </div>
    <span class="demo-badge">Demo</span>
  </div>`;

const bottomNav = (current = "today") => `
  <nav class="bottom-nav" aria-label="Primary navigation">
    <button type="button" data-action="nav-today" ${current === "today" ? 'aria-current="page"' : ""}><span>${icon("today")}</span>Today</button>
    <button type="button" data-action="nav-trends" ${current === "trends" ? 'aria-current="page"' : ""}><span>${icon("trends")}</span>Trends</button>
    <button type="button" data-action="nav-you" ${current === "you" ? 'aria-current="page"' : ""}><span>${icon("you")}</span>You</button>
  </nav>`;

const journeyMeter = () => {
  const journey = currentJourney();
  const current = state.step + 1;
  const total = journey.screens.length;
  const progress = `${Math.round((current / total) * 100)}%`;
  return `
    <div class="journey-meter" aria-label="Journey progress, step ${current} of ${total}">
      <span class="journey-meter-track" aria-hidden="true"><i style="--journey-progress:${progress}"></i></span>
      <small>${String(current).padStart(2, "0")} / ${String(total).padStart(2, "0")}</small>
    </div>`;
};

const wrap = (content, options = {}) => `
  <div class="screen-scroll">
    ${content}
  </div>
  ${options.nav ? bottomNav(options.nav) : journeyMeter()}
  ${state.toast ? `<div class="toast" role="status">${state.toast}</div>` : ""}`;

const sleepHeatLevels = [
  1, 1, 2, 2, 3, 2, 1, 2, 3, 4,
  3, 2, 2, 3, 4, 4, 3, 2, 1, 2,
  3, 4, 5, 4, 3, 2, 2, 3, 4, 5,
  5, 4, 3, 2, 1, 2, 3, 4, 4, 3,
  2, 1, 2, 3, 3, 2, 1, 1, 2, 2,
];

const miniBars = (values) => `
  <span class="mini-bars" aria-hidden="true">
    ${values.map((height, index) => `<i style="--bar:${height}%;--i:${index}"></i>`).join("")}
  </span>`;

const statsOverview = () => `
  <section class="stats-overview" aria-label="Sleep summary for the current week">
    <div class="period-switch" aria-label="Displayed range"><span>Month</span><b>Week</b></div>
    <div class="lead-stat"><strong>5<small>h</small>48<small>m</small></strong><span>Sleep last night</span></div>
    <div class="heatmap-wrap">
      <span class="heat-note heat-note--top">Recent median: 6h 36m</span>
      <div class="sleep-heatmap" aria-hidden="true">
        ${sleepHeatLevels.map((level, index) => `<i style="--level:${level};--i:${index}"></i>`).join("")}
      </div>
      <span class="heat-note heat-note--bottom">Last night: 5h 48m</span>
    </div>
    <p>A shorter night is the main reason today may feel less supported.</p>
  </section>
  <div class="stats-grid" aria-label="Daily domain summaries">
    <button class="metric-card sleep" type="button" data-open="sleep">
      <span class="metric-card-head"><b>Sleep</b><em>−9%</em></span>
      <small><i></i> High confidence</small>
      <strong>64</strong>
      ${miniBars([32, 48, 42, 66, 56, 72, 63, 82, 74, 60])}
    </button>
    <button class="metric-card recovery" type="button" data-open="recovery">
      <span class="metric-card-head"><b>Recovery</b><em>+4 bpm</em></span>
      <small><i></i> Moderate confidence</small>
      <strong>72</strong>
      <svg class="mini-line" viewBox="0 0 140 40" aria-hidden="true"><path d="M2 26 17 25 28 28 42 15 53 29 68 24 82 26 98 19 112 24 138 21" /></svg>
    </button>
    <button class="metric-card movement" type="button" data-open="movement">
      <span class="metric-card-head"><b>Movement</b><em>You logged</em></span>
      <small><i></i> Sustainable</small>
      <strong>38<small> min</small></strong>
      ${miniBars([38, 62, 44, 78, 52, 68, 41, 56, 82, 72])}
    </button>
    <button class="metric-card coverage" type="button" data-jump="evidence">
      <span class="metric-card-head"><b>Coverage</b><em>25 / 30</em></span>
      <small><i></i> Personal baseline</small>
      <strong>87<small>%</small></strong>
      <svg class="mini-line stepped" viewBox="0 0 140 40" aria-hidden="true"><path d="M2 30H26V20H51V26H76V12H102V18H138" /></svg>
    </button>
  </div>`;

const trendChart = () => `
  <svg class="chart" viewBox="0 0 320 150" role="img" aria-labelledby="trend-title trend-desc">
    <title id="trend-title">Thirty-day sleep duration trend</title>
    <desc id="trend-desc">A stable trace with five visible data gaps and a slightly shorter recent week.</desc>
    <line class="grid" x1="22" y1="28" x2="304" y2="28" />
    <line class="grid" x1="22" y1="76" x2="304" y2="76" />
    <line class="grid" x1="22" y1="124" x2="304" y2="124" />
    <rect class="corridor" x="22" y="48" width="282" height="48" rx="5" />
    <path class="line" d="M24 70 L34 62 L44 75 L54 68 M74 73 L84 60 L94 64 L104 57 L114 69 M134 74 L144 70 L154 67 L164 82 L174 75 L184 78 M204 73 L214 80 L224 84 L234 79 L244 91 M264 92 L274 87 L284 96 L294 90 L304 93" />
    <circle class="gap" cx="64" cy="71" r="4" />
    <circle class="gap" cx="124" cy="70" r="4" />
    <circle class="gap" cx="194" cy="76" r="4" />
    <circle class="gap" cx="254" cy="91" r="4" />
    <text x="22" y="143">20 Jul</text><text x="144" y="143">3 Aug</text><text x="273" y="143">18 Aug</text>
  </svg>`;

const screens = {
  welcome: () => wrap(`
    ${statusBar("Local only")}
    <div class="topline brand-topline">${brandLockup()}<span class="demo-badge">Research build</span></div>
    <section class="hero brand-hero">
      <span class="eyebrow">Your data · open by design</span>
      <h1><span>Understand the</span><em>signal.</em><span>Keep the data.</span></h1>
      <p>LibreRing turns supported COLMI R12 signals into a calm daily explanation. No account. No subscription. Your data stays on this device.</p>
    </section>
    <div class="plain-card">
      <h3>What this prototype does</h3>
      <p>Pairs a supported ring, preserves source and confidence, and explains personal trends. It is not a medical device.</p>
    </div>
    <div class="button-stack">
      <button class="primary" type="button" data-action="next">Continue</button>
      <button class="secondary" type="button" data-jump="morning">Try fictional demo</button>
    </div>`),

  privacy: () => wrap(`
    ${statusBar("No account")}
    ${header("Before we pair", "A plain-language privacy promise")}
    <section class="hero compact">
      <span class="eyebrow">Private by construction</span>
      <h1>The app works without an account or cloud.</h1>
      <p>Ring records and app-derived results stay in local storage unless you explicitly export them.</p>
    </section>
    <div class="timeline">
      <div class="time">On device</div><div class="event"><b>Ring records</b><span>Timestamped measurements and sync state.</span></div>
      <div class="time">App-derived</div><div class="event"><b>Personal baselines</b><span>Transparent rolling comparisons with confidence.</span></div>
      <div class="time">Your choice</div><div class="event"><b>Portable export</b><span>CSV or JSON after a scope preview.</span></div>
    </div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Pair my ring</button><button class="secondary" type="button" data-jump="morning">Stay in demo</button></div>`),

  permission: () => wrap(`
    ${statusBar("Bluetooth off")}
    ${header("Bluetooth access", "Requested only when you choose to pair")}
    <section class="hero compact">
      <span class="eyebrow">Why LibreRing asks</span>
      <h1>Find and sync your nearby ring.</h1>
      <p>Bluetooth is used for a direct local connection. LibreRing does not use it for location history, advertising, or background tracking of other devices.</p>
    </section>
    <div class="quality-card"><h3>If you say no</h3><p>The fictional demo and all previously imported local data remain available. You can grant access later in system settings.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Allow Bluetooth</button><button class="secondary" type="button" data-jump="morning">Not now — use demo</button></div>`),

  scan: () => wrap(`
    ${statusBar("Scanning")}
    ${header("Find your ring", "Keep it close and out of the charger")}
    <div class="scan-field" aria-label="Scanning for a nearby COLMI R12"><span class="scan-dot"></span></div>
    <div class="plain-card"><h3>Looking for supported devices</h3><p>One nearby candidate has a strong signal. Device identifiers stay hidden until you confirm it.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Show nearby ring</button><button class="secondary" type="button" data-action="stay">Scanning help</button></div>`),

  found: () => wrap(`
    ${statusBar("1 nearby")}
    ${header("Choose your ring", "Confirm one device at a time")}
    <button class="choice-card selected" type="button" data-action="next"><b>COLMI R12_4A7C</b><span>Very close · supported identity · tap to confirm</span></button>
    <div class="plain-card"><h3>Capability check</h3><p>Heart rate, blood oxygen estimates, steps, and sleep intervals are available. Firmware HRV, temperature, respiration, raw acceleration, and ring-recorded swim metrics are not.</p></div>
    <div class="quality-card good"><h3>Fail-closed rule</h3><p>If the identity or firmware is unsupported, LibreRing stays unpaired and offers a redacted diagnostic export.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Connect COLMI R12_4A7C</button></div>`),

  sync: () => wrap(`
    ${statusBar("Ring 74%")}
    ${header("First sync", "Importing six days without duplicates")}
    <section class="hero compact"><span class="eyebrow">Range 12–18 August</span><h1>Preserving each verified day.</h1><p>Completed ranges are committed once. If the connection pauses, the next attempt resumes from the missing range.</p></section>
    <div class="progress-track" aria-label="Sync 82 percent complete"><i style="--progress:82%"></i></div>
    <div class="definition-list"><div><dt>Verified</dt><dd>12–16 August</dd></div><div><dt>Importing</dt><dd>17 August</dd></div><div><dt>Waiting</dt><dd>18 August</dd></div></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Finish sync</button></div>`),

  calibration: () => wrap(`
    ${statusBar("Synced")}
    ${header("Personal baseline", "Learning before comparing")}
    <section class="hero compact"><span class="eyebrow">Calibration · day 1 of 14</span><h1>Useful now. More personal with history.</h1><p>Today shows reliable observations immediately. Personal score comparisons appear only when each domain has enough recent evidence.</p></section>
    <div class="card-list">
      <div class="signal-card sleep"><i class="accent"></i><div><b>Sleep</b><small>Duration is available now</small></div><strong>1/14</strong></div>
      <div class="signal-card recovery"><i class="accent"></i><div><b>Recovery</b><small>Overnight pulse baseline learning</small></div><strong>1/14</strong></div>
      <div class="signal-card movement"><i class="accent"></i><div><b>Movement</b><small>Rest and swim context included</small></div><strong>1/7</strong></div>
    </div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">See first useful day</button></div>`),

  today: () => wrap(`
    ${statusBar("R12 68%")}
    <div class="stats-titlebar"><button class="icon-button" type="button" data-action="stay" aria-label="Review earlier days">${icon("today")}</button><h1>Stats</h1><button class="icon-button" type="button" data-jump="swim" aria-label="Open logging menu">${icon("log")}</button></div>
    ${statsOverview()}`, {nav: "today"}),

  sleep: () => wrap(`
    ${statusBar()}
    ${header("Sleep", "Monday night · 87% interval coverage")}
    <div class="metric-hero"><div class="metric-number">64</div><div class="metric-label">Limited</div></div>
    <div class="button-row"><span class="confidence high">High confidence</span><span class="provenance">Ring estimate</span></div>
    <div class="quality-card"><h3>Main contributor</h3><p>Total sleep was 5h 48m — 48 minutes below your recent median. Timing was otherwise close to your usual range.</p></div>
    <div class="definition-list"><div><dt>In bed</dt><dd>00:18–06:32</dd></div><div><dt>Estimated asleep</dt><dd>5h 48m</dd></div><div><dt>Recent median</dt><dd>6h 36m</dd></div><div><dt>Firmware stages</dt><dd>Excluded from V1 scoring</dd></div></div>
    <button class="text-button" type="button" data-jump="evidence">Inspect calculation and coverage →</button>`, {nav: "today"}),

  recovery: () => wrap(`
    ${statusBar()}
    ${header("Recovery", "Compared with your own recent nights")}
    <div class="metric-hero"><div class="metric-number">72</div><div class="metric-label" style="color:var(--recovery)">Some recovery<br />may help</div></div>
    <div class="button-row"><span class="confidence moderate">Moderate confidence</span><span class="provenance">App-derived</span></div>
    <div class="quality-card"><h3>Why this changed</h3><p>Your overnight median pulse was 62 bpm, four above your recent median, after a shorter night.</p></div>
    <div class="definition-list"><div><dt>Overnight pulse</dt><dd>62 bpm median</dd></div><div><dt>Recent median</dt><dd>58 bpm</dd></div><div><dt>Expected window</dt><dd>87% captured</dd></div><div><dt>HRV</dt><dd>Not supplied by supported firmware</dd></div></div>
    <p class="review-note">This is a personal trend summary, not a diagnosis or instruction to train.</p>`, {nav: "today"}),

  movement: () => wrap(`
    ${statusBar()}
    ${header("Movement", "Activity context, not a closure goal")}
    <section class="hero compact"><span class="eyebrow">Sustainable · High confidence</span><h1>Your easy day is included, not penalised.</h1><p>Yesterday's pool swim counts as structured activity even though the ring did not measure it underwater.</p></section>
    <div class="plain-card"><h3>Pool swim · You logged</h3><p>38 minutes · Moderate effort · Monday 17 August</p></div>
    <div class="definition-list"><div><dt>Steps</dt><dd>4,860 · Ring estimate</dd></div><div><dt>Structured activity</dt><dd>38 min · You logged</dd></div><div><dt>Rest context</dt><dd>Easy day protected</dd></div></div>
    <button class="secondary" type="button" data-jump="swim">Review swim entry</button>`, {nav: "today"}),

  evidence: () => wrap(`
    ${statusBar()}
    ${header("Inspect evidence", "Sleep result · calculation 0.1.0-research")}
    <section class="hero compact"><span class="eyebrow">Result ≠ confidence</span><h1>64 Limited</h1><p>The result describes the observed night. Confidence describes whether enough expected evidence supported it.</p></section>
    <div class="definition-list"><div><dt>Source</dt><dd>COLMI R12 ring estimate</dd></div><div><dt>Expected window</dt><dd>23:45–07:00</dd></div><div><dt>Captured interval</dt><dd>87%</dd></div><div><dt>Personal baseline</dt><dd>Established · 25 nights</dd></div><div><dt>Excluded</dt><dd>Firmware stages and HRV</dd></div></div>
    <div class="quality-card good"><h3>Threshold passed</h3><p>At least 60% of the expected window was present and the main interval was internally consistent.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Compare alternate states</button></div>`),

  states: () => wrap(`
    ${statusBar("State matrix")}
    ${header("Alternate results", "Confidence is explicit in every state")}
    <div class="state-grid" aria-label="Scoring state examples">
      <div class="state-tile"><b>Strong + reliable</b><i style="--state:var(--recovery)"></i><span>Sleep 92 · Supportive · High confidence</span></div>
      <div class="state-tile"><b>Strong + uncertain</b><i style="--state:var(--warning)"></i><span>Sleep 86 · only 64% captured</span></div>
      <div class="state-tile"><b>Low + reliable</b><i style="--state:var(--sleep)"></i><span>Sleep 49 · 4h 55m · 96% captured</span></div>
      <div class="state-tile"><b>Low + uncertain</b><i style="--state:var(--error)"></i><span>Limited evidence precedes contributor detail</span></div>
      <div class="state-tile"><b>Travel</b><i style="--state:var(--movement)"></i><span>Timing context shown; baseline unchanged</span></div>
      <div class="state-tile"><b>Illness/rest</b><i style="--state:var(--recovery)"></i><span>No Movement score; rest is protected</span></div>
    </div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">See no-result state</button></div>`),

  "no-result": () => wrap(`
    ${statusBar("Partial night")}
    ${header("Sleep", "Tuesday night")}
    <section class="hero compact"><span class="eyebrow">No Sleep result</span><h1>Less than 60% of the expected window was captured.</h1><p>LibreRing will not turn a gap into a poor score. The available interval remains visible and can be re-synced.</p></section>
    <div class="quality-card error"><h3>Captured 02:12–05:58</h3><p>Charge the ring, check fit, and retry the missing range. Completed data is preserved.</p></div>
    <div class="definition-list"><div><dt>Available</dt><dd>3h 46m</dd></div><div><dt>Missing</dt><dd>Expected start and final hour</dd></div><div><dt>Displayed as</dt><dd>No result · not zero</dd></div></div>
    <div class="button-stack"><button class="primary" type="button" data-jump="device">Review sync recovery</button><button class="secondary" type="button" data-jump="morning">Back to Today</button></div>`),

  "log-menu": () => wrap(`
    ${statusBar()}
    ${header("Add context", "You control what is recorded")}
    <div class="choice-grid">
      <button class="choice-card" type="button" data-action="next"><b>Log a swim</b><span>Pool or open water · duration · effort · note</span></button>
      <button class="choice-card" type="button" data-action="stay"><b>Add a check-in</b><span>Energy, soreness, or a private journal note</span></button>
      <button class="choice-card" type="button" data-jump="cycle"><b>Cycle Context</b><span>Optional, local, and separately deletable</span></button>
    </div>
    <div class="plain-card"><h3>Provenance stays visible</h3><p>Manual entries are labelled “You logged” and never presented as ring measurements.</p></div>`, {nav: "today"}),

  "swim-form": () => wrap(`
    ${statusBar("You logged")}
    ${header("Log a swim", "Monday, 17 August")}
    <form class="form-grid" id="swim-form">
      <div class="field"><label for="water">Water</label><select id="water"><option>Pool</option><option>Open water</option></select></div>
      <div class="field"><label for="duration">Duration</label><input id="duration" type="text" value="38 minutes" inputmode="numeric" /></div>
      <div class="field"><span>Effort</span><div class="segmented"><button type="button">Easy</button><button type="button" aria-pressed="true">Moderate</button><button type="button">Hard</button></div></div>
      <div class="field"><label for="note">Private note · optional</label><textarea id="note">Technique session; shoulders fine.</textarea></div>
    </form>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Review swim</button><button class="secondary" type="button" data-action="back">Cancel</button></div>`),

  "swim-review": () => wrap(`
    ${statusBar("Review")}
    ${header("Review swim", "Nothing is measured beyond what you entered")}
    <section class="hero compact"><span class="eyebrow">Pool swim · You logged</span><h1>38 minutes<br />Moderate effort</h1><p>Technique session; shoulders fine.</p></section>
    <div class="quality-card"><h3>What the R12 did not measure</h3><p>Laps, strokes, pace, distance, SWOLF, and underwater heart rate are unavailable and will not be inferred.</p></div>
    <div class="definition-list"><div><dt>Counts as</dt><dd>Structured activity</dd></div><div><dt>Affects steps</dt><dd>No penalty for missing swim steps</dd></div><div><dt>Source</dt><dd>You logged</dd></div></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Save swim</button><button class="secondary" type="button" data-action="back">Edit</button></div>`),

  "swim-saved": () => wrap(`
    ${statusBar("Saved locally")}
    ${header("Swim saved", "Included in Movement context")}
    <section class="hero compact"><span class="eyebrow">Monday, 17 August</span><h1>This counts as structured activity.</h1><p>The R12 did not measure laps, strokes, pace, or underwater heart rate.</p></section>
    <div class="plain-card"><h3>Pool swim · 38 minutes</h3><p>Moderate effort · You logged · edit and delete available</p></div>
    <div class="button-stack"><button class="primary" type="button" data-jump="morning">Return to Today</button><button class="secondary" type="button" data-action="back">Review entry</button></div>`),

  trends: () => wrap(`
    ${statusBar("30 days")}
    <div class="topline"><div><span class="eyebrow">Personal direction</span><strong>Trends</strong></div><span class="demo-badge">Demo</span></div>
    <section class="hero compact"><span class="eyebrow">Past 30 days</span><h1>Mostly stable, with a recent shorter week.</h1><p>25 of 30 nights met the reliable coverage rule.</p></section>
    <button class="signal-card sleep" type="button" data-action="next"><i class="accent"></i><div><b>Sleep duration</b><small>6h 42m median · down 9m</small></div><strong>→</strong></button>
    <button class="signal-card recovery" type="button" data-action="stay"><i class="accent"></i><div><b>Overnight pulse</b><small>Mostly within personal range</small></div><strong>→</strong></button>
    <button class="signal-card movement" type="button" data-action="stay"><i class="accent"></i><div><b>Movement</b><small>Two swims · easy days protected</small></div><strong>→</strong></button>`, {nav: "trends"}),

  "trend-detail": () => wrap(`
    ${statusBar("25/30 reliable")}
    ${header("Sleep · 30 days", "Personal baseline established")}
    <div class="segmented"><button type="button">7d</button><button type="button" aria-pressed="true">30d</button><button type="button">90d</button></div>
    <div class="chart-card"><div class="chart-head"><b>Estimated sleep</b><span>Corridor 6h 25m–7h 18m</span></div>${trendChart()}</div>
    <div class="definition-list"><div><dt>Current median</dt><dd>6h 42m</dd></div><div><dt>Prior 30 days</dt><dd>6h 51m</dd></div><div><dt>Reliable nights</dt><dd>25 of 30</dd></div><div><dt>Visible gaps</dt><dd>5 · not treated as zero</dd></div></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Select a visible gap</button></div>`),

  "trend-gap": () => wrap(`
    ${statusBar("Gap selected")}
    ${header("Sleep · 30 days", "Monday, 10 August")}
    <div class="chart-card"><div class="chart-head"><b>Estimated sleep</b><span>Gap selected</span></div>${trendChart()}</div>
    <div class="quality-card"><h3>No value; not zero</h3><p>Only 41% of the expected window was captured. The baseline corridor and adjacent nights remain visible, but this night does not pull the trend down.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="back">Return to 30-day trend</button><button class="secondary" type="button" data-jump="device">Check missing data</button></div>`),

  "device-issue": () => wrap(`
    ${statusBar("Ring 44%")}
    ${header("Sync paused", "Stored data is preserved")}
    <section class="hero compact"><span class="eyebrow">Connection issue</span><h1>Another app may be connected.</h1><p>QRing can hold the ring's Bluetooth connection. Close it fully, then retry LibreRing.</p></section>
    <div class="quality-card"><h3>Last complete sync</h3><p>Yesterday 08:04 · 44% battery · six local days remain available.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Close QRing and retry</button><button class="secondary" type="button" data-open="device-checks">Other checks</button></div>`),

  "device-checks": () => wrap(`
    ${statusBar("Troubleshoot")}
    ${header("Other checks", "Try one bounded step at a time")}
    <div class="timeline"><div class="time">1</div><div class="event"><b>Close QRing</b><span>Remove it from the recent-apps switcher.</span></div><div class="time">2</div><div class="event"><b>Keep the ring close</b><span>Take it out of the charger and wear or hold it.</span></div><div class="time">3</div><div class="event"><b>Toggle Bluetooth only if needed</b><span>Stored records remain untouched.</span></div><div class="time">4</div><div class="event"><b>Retry the missing range</b><span>Verified days are skipped to prevent duplicates.</span></div></div>
    <div class="button-stack"><button class="primary" type="button" data-open="device-sync">Retry sync</button><button class="secondary" type="button" data-action="back">Back to issue</button></div>`),

  "device-sync": () => wrap(`
    ${statusBar("Connected")}
    ${header("Resuming sync", "Only the missing range")}
    <section class="hero compact"><span class="eyebrow">17–18 August</span><h1>Verified records are skipped.</h1><p>The last complete checkpoint was read before requesting the missing range.</p></section>
    <div class="progress-track" aria-label="Sync complete"><i style="--progress:100%"></i></div>
    <div class="definition-list"><div><dt>Preserved</dt><dd>12–16 August</dd></div><div><dt>Added</dt><dd>17–18 August</dd></div><div><dt>Duplicates</dt><dd>0</dd></div></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Confirm sync</button></div>`),

  "device-success": () => wrap(`
    ${statusBar("Synced 7:45")}
    ${header("Sync complete", "Readback verified")}
    <section class="hero compact"><span class="eyebrow">Six days available</span><h1>Synced without duplicates.</h1><p>The ring clock, imported range, and local record count agree.</p></section>
    <div class="quality-card good"><h3>2 new days · 0 duplicates</h3><p>All previously verified records were preserved. Battery is 44%.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-jump="morning">Return to Today</button><button class="secondary" type="button" data-action="back">View sync detail</button></div>`),

  "data-hub": () => wrap(`
    ${statusBar("Local data")}
    ${header("Your data", "Portable, inspectable, removable")}
    <div class="choice-grid"><button class="choice-card" type="button" data-action="next"><b>Export data</b><span>CSV or JSON · exact range and columns previewed</span></button><button class="choice-card" type="button" data-action="stay"><b>Health permissions</b><span>Choose read and write categories separately</span></button><button class="choice-card" type="button" data-action="stay"><b>Delete selected data</b><span>Preview exact scope before confirmation</span></button><button class="choice-card" type="button" data-jump="cycle"><b>Cycle Context data</b><span>Managed and deleted separately</span></button></div>
    <div class="plain-card"><h3>Local storage</h3><p>2,184 fictional demo rows · last integrity check 7:46</p></div>`, {nav: "you"}),

  "export-options": () => wrap(`
    ${statusBar("Export")}
    ${header("Choose export", "No cloud upload")}
    <div class="field"><span>Format</span><div class="segmented" role="group" aria-label="Export format"><button type="button" data-format="csv" aria-pressed="true">CSV</button><button type="button" data-format="json">JSON</button><button type="button" data-format="summary">Summary</button></div></div>
    <div class="form-grid"><div class="field"><label for="range">Date range</label><select id="range"><option>All local data · 12 Jul–18 Aug</option><option>Past 30 days</option><option>Custom range</option></select></div><label class="check-row"><input type="checkbox" checked /> Include provenance and confidence columns</label><label class="check-row"><input type="checkbox" checked /> Include manual journal and swim entries</label><label class="check-row"><input type="checkbox" /> Include Cycle Context data (separate consent)</label></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Preview export</button><button class="secondary" type="button" data-action="back">Cancel</button></div>`),

  "export-preview": () => wrap(`
    ${statusBar("Preview")}
    ${header("Review export", "Nothing has left the device")}
    <section class="hero compact"><span class="eyebrow">CSV · 2,184 rows</span><h1>12 July–18 August</h1><p>Ring estimates, app-derived results, confidence, provenance, and user-logged activity.</p></section>
    <div class="definition-list"><div><dt>Cycle Context</dt><dd>Excluded</dd></div><div><dt>Timezone</dt><dd>Europe/Lisbon + ISO timestamp</dd></div><div><dt>Missing values</dt><dd>Blank + reason column</dd></div><div><dt>Checksum</dt><dd>SHA-256 after save</dd></div></div>
    <div class="quality-card good"><h3>Portable and explicit</h3><p>Headers use stable names and units. A data dictionary and model version are included.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Save export</button><button class="secondary" type="button" data-action="back">Change scope</button></div>`),

  "export-complete": () => wrap(`
    ${statusBar("Saved locally")}
    ${header("Export ready", "Readback verified")}
    <section class="hero compact"><span class="eyebrow">librering-export-2026-08-18.zip</span><h1>2,184 rows saved.</h1><p>The file checksum and row count were calculated after writing the archive.</p></section>
    <div class="definition-list"><div><dt>Archive</dt><dd>184 KB</dd></div><div><dt>Rows</dt><dd>2,184</dd></div><div><dt>Checksum</dt><dd>9f12…a6c4</dd></div><div><dt>Cycle Context</dt><dd>Not included</dd></div></div>
    <div class="button-stack"><button class="primary" type="button" data-action="stay">Open share sheet</button><button class="secondary" type="button" data-open="data-hub">Done</button></div>`),

  "cycle-off": () => wrap(`
    ${statusBar("Off")}
    ${header("Cycle Context", "Optional and absent by default")}
    <section class="hero compact"><span class="eyebrow">Currently off</span><h1>Add context only if it is useful to you.</h1><p>LibreRing will not infer periods, fertility, pregnancy, or health conditions from ring data.</p></section>
    <div class="plain-card"><h3>Separate privacy boundary</h3><p>Reproductive entries are stored locally, hidden from notification previews, exportable only by explicit choice, and separately deletable.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Review privacy first</button><button class="secondary" type="button" data-jump="morning">Keep Cycle Context off</button></div>`),

  "cycle-privacy": () => wrap(`
    ${statusBar("Private")}
    ${header("Privacy before setup", "No inference or announcement")}
    <div class="timeline"><div class="time">Stored</div><div class="event"><b>Only on this device</b><span>Unless you include it in a separate export.</span></div><div class="time">Hidden</div><div class="event"><b>Notification previews off</b><span>Generic reminders only, if you opt in.</span></div><div class="time">Separate</div><div class="event"><b>Delete reproductive data alone</b><span>Sleep, recovery, movement, and ring records remain.</span></div><div class="time">Never</div><div class="event"><b>No pregnancy or fertility inference</b><span>User-declared context is not a clinical status.</span></div></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">I understand — choose mode</button><button class="secondary" type="button" data-action="back">Not now</button></div>`),

  "cycle-modes": () => wrap(`
    ${statusBar("Choose mode")}
    ${header("What would help?", "You can change this later")}
    <div class="choice-grid"><button class="choice-card selected" type="button" data-cycle-mode="track"><b>Track my cycle</b><span>User-entered periods and symptoms with low-confidence calendar estimates.</span></button><button class="choice-card" type="button" data-cycle-mode="pregnancy"><b>Follow a declared pregnancy</b><span>Trend-only Recovery without pre-pregnancy score comparison.</span></button><button class="choice-card" type="button" data-cycle-mode="both"><b>Both contexts</b><span>Each entry keeps its source, edit history, and separate deletion boundary.</span></button></div>
    <div class="quality-card"><h3>Not a fertility tool</h3><p>Calendar estimates never become fertile status, contraception advice, or a clinical prediction.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Enable selected mode</button></div>`),

  "cycle-home": () => wrap(`
    ${statusBar("You entered")}
    ${header("Cycle Context", "Track my cycle · local only")}
    <section class="hero compact"><span class="eyebrow">Calendar estimate · Low confidence</span><h1>Next period may be around 29 August.</h1><p>Based only on the dates you entered. It is not a fertility or health prediction.</p></section>
    <div class="plain-card"><h3>Last period · You entered</h3><p>31 July–4 August · editable and separately deletable</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Review pregnancy mode</button><button class="secondary" type="button" data-action="stay">Log period or symptom</button></div>`),

  pregnancy: () => wrap(`
    ${statusBar("User-declared")}
    ${header("Pregnancy context", "Declared by you · not inferred")}
    <section class="hero compact"><span class="eyebrow">Trend-only Recovery</span><h1>Your overnight pulse has been broadly stable this week.</h1><p>LibreRing does not compare this with a pre-pregnancy Recovery score or interpret it clinically.</p></section>
    <div class="chart-card"><div class="chart-head"><b>Overnight pulse</b><span>Personal trend · 7 nights</span></div><svg class="chart" viewBox="0 0 320 100" role="img" aria-label="Stable seven-night pulse trend"><rect class="corridor" x="18" y="28" width="284" height="40" rx="5"/><path class="line" style="stroke:var(--recovery)" d="M20 55 L66 50 L112 58 L158 52 L204 54 L250 49 L300 53"/></svg></div>
    <div class="quality-card"><h3>Clinical limitation</h3><p>Contact an appropriate clinician for symptoms, concern, or medical decisions. Ring estimates do not diagnose pregnancy complications.</p></div>
    <div class="button-stack"><button class="primary" type="button" data-action="next">Review separate deletion</button><button class="secondary" type="button" data-action="back">Back to cycle context</button></div>`),

  "cycle-delete": () => wrap(`
    ${statusBar("Preview only")}
    ${header("Delete Cycle Context", "Other LibreRing data stays")}
    <section class="hero compact"><span class="eyebrow">Exact scope</span><h1>Delete 14 reproductive entries?</h1><p>This removes period dates, symptom notes, declared pregnancy context, and their derived calendar estimates.</p></section>
    <div class="definition-list"><div><dt>Delete</dt><dd>14 Cycle Context entries</dd></div><div><dt>Keep</dt><dd>Sleep, Recovery, Movement</dd></div><div><dt>Keep</dt><dd>Ring records and exports</dd></div><div><dt>Undo</dt><dd>Not available after confirmation</dd></div></div>
    <div class="button-stack"><button class="danger-button" type="button" data-action="stay">Continue to typed confirmation</button><button class="secondary" type="button" data-action="back">Cancel safely</button></div>`),
};

function currentJourney() { return journeys[state.journey]; }
function currentScreenName() { return currentJourney().screens[state.step]; }

function setHash() {
  const nextHash = `#/${state.journey}/${state.step + 1}`;
  if (location.hash !== nextHash) history.replaceState(null, "", nextHash);
}

function render({ focus = false } = {}) {
  const journey = currentJourney();
  const screenName = currentScreenName();
  const screen = $("#screen");
  screen.dataset.journey = state.journey;
  screen.dataset.view = screenName;
  screen.dataset.flow = state.flow;
  screen.innerHTML = (screens[screenName] || screens.today)();

  $$("[data-jump]").forEach((button) => {
    button.setAttribute("aria-current", button.dataset.jump === state.journey ? "true" : "false");
  });
  $("#review-title").textContent = journey.title;
  $("#review-purpose").textContent = journey.purpose;
  $("#review-progress").textContent = `Step ${state.step + 1} of ${journey.screens.length}`;
  $("#review-evidence").textContent = journey.evidence;
  $("#review-constraint").textContent = journey.constraint;
  document.title = `${journey.title} · LibreRing V1`;
  setHash();
  if (focus) screen.focus({ preventScroll: true });
}

function jump(journey, screenName = null) {
  if (!journeys[journey]) return;
  state.journey = journey;
  state.step = screenName && journeys[journey].screens.includes(screenName)
    ? journeys[journey].screens.indexOf(screenName)
    : 0;
  state.toast = "";
  state.flow = "jump";
  render({ focus: true });
}

function openScreen(screenName) {
  for (const [journeyName, journey] of Object.entries(journeys)) {
    const index = journey.screens.indexOf(screenName);
    if (index >= 0) {
      state.journey = journeyName;
      state.step = index;
      state.toast = "";
      state.flow = "forward";
      render({ focus: true });
      return;
    }
  }
}

function next() {
  const journey = currentJourney();
  if (state.step < journey.screens.length - 1) {
    state.step += 1;
    state.flow = "forward";
  } else {
    state.toast = "Journey complete · choose another review task";
    state.flow = "settle";
  }
  render({ focus: true });
}

function back() {
  state.toast = "";
  if (state.step > 0) {
    state.step -= 1;
    state.flow = "back";
  } else if (state.journey !== "morning") {
    return jump("morning");
  } else {
    state.flow = "settle";
  }
  render({ focus: true });
}

document.addEventListener("click", (event) => {
  const target = event.target.closest("button, a");
  if (!target) return;

  if (target.dataset.jump) return jump(target.dataset.jump);
  if (target.dataset.open) return openScreen(target.dataset.open);
  if (target.dataset.cycleMode) {
    state.selectedCycleMode = target.dataset.cycleMode;
    $$("[data-cycle-mode]").forEach((button) => button.classList.toggle("selected", button === target));
    return;
  }
  if (target.dataset.format) {
    state.exportFormat = target.dataset.format;
    $$("[data-format]").forEach((button) => button.setAttribute("aria-pressed", String(button === target)));
    return;
  }

  switch (target.dataset.action) {
    case "next": next(); break;
    case "back": back(); break;
    case "nav-today": jump("morning"); break;
    case "nav-trends": jump("trends"); break;
    case "nav-you": jump("export"); break;
    case "stay":
      state.toast = target.textContent.includes("share")
        ? "Prototype only · no system share sheet was opened"
        : "State acknowledged · no data changed";
      state.flow = "settle";
      render();
      break;
    default: break;
  }
});

$("#theme-toggle").addEventListener("click", () => {
  const root = document.documentElement;
  const nextTheme = root.dataset.theme === "dark" ? "light" : "dark";
  root.dataset.theme = nextTheme;
  $("#theme-toggle").innerHTML = `<span aria-hidden="true">◐</span> Use ${nextTheme === "dark" ? "light" : "dark"} theme`;
});

$("#text-toggle").addEventListener("click", () => {
  const root = document.documentElement;
  const nextSize = root.dataset.textSize === "large" ? "standard" : "large";
  root.dataset.textSize = nextSize;
  $("#text-toggle").innerHTML = `<span aria-hidden="true">Aa</span> Use ${nextSize === "large" ? "standard" : "large"} text`;
});

document.addEventListener("keydown", (event) => {
  if (["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName)) return;
  if (event.key === "ArrowRight") next();
  if (event.key === "ArrowLeft") back();
});

function restoreFromHash() {
  const [, journeyName, stepText] = location.hash.split("/");
  const parsedStep = Number(stepText) - 1;
  if (journeys[journeyName]) {
    state.journey = journeyName;
    state.step = Number.isInteger(parsedStep)
      ? Math.min(Math.max(parsedStep, 0), journeys[journeyName].screens.length - 1)
      : 0;
  }
}

window.addEventListener("hashchange", () => { restoreFromHash(); state.flow = "jump"; render(); });
restoreFromHash();
render();
