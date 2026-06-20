/* ============================================================
   Puck Lab — main.js
   ------------------------------------------------------------
   CONFIG: where order requests are sent.
   Paste your form-service endpoint below (e.g. a Formspree URL
   like "https://formspree.io/f/abcdwxyz"). It accepts the form
   POST — including the uploaded artwork file — and emails it to
   you. Until you set this, the site falls back to opening the
   visitor's email client (no file attachment in that mode).
   ============================================================ */
const CONFIG = {
  FORM_ENDPOINT: "",                       // <-- paste your Formspree (or similar) URL here
  SHOP_EMAIL: "christopher.neuwirth@gmail.com", // used for the email fallback
};

/* ---- Ready-made designs (your uploaded artwork) ---- */
const DESIGNS = [
  { id: "rink-gremlin",      name: "Certified Rink Gremlin",   file: "assets/designs/rink-gremlin.png" },
  { id: "biscuit-deployed",  name: "The Biscuit Deployed",     file: "assets/designs/biscuit-deployed.png" },
  { id: "penalty-box",       name: "Penalty Box Alumni",       file: "assets/designs/penalty-box-alumni.png" },
  { id: "5am-rink-club",     name: "5 AM Rink Club",           file: "assets/designs/5am-rink-club.png" },
  { id: "hockey-dad-crew",   name: "Hockey Dad Maintenance",   file: "assets/designs/hockey-dad-crew.png" },
  { id: "coachs-award",      name: "Coach's Award",            file: "assets/designs/coachs-award.png" },
  { id: "going-to-game",     name: "You're Going to the Game", file: "assets/designs/going-to-the-game.png" },
  { id: "black-ice",         name: "Black Ice",                file: "assets/designs/black-ice.png",     personalize: true },
  { id: "player-crest",      name: "Player Name Crest",        file: "assets/designs/player-crest.png",  personalize: true },
  { id: "first-goal",        name: "First Goal",               file: "assets/designs/first-goal.png",    personalize: true },
  { id: "season-tickets",    name: "Season Tickets",           file: "assets/designs/season-tickets.png" },
  { id: "snow-sprayer",      name: "Professional Snow Sprayer", file: "assets/designs/snow-sprayer.png" },
  { id: "neutral-zone",      name: "Zero Trust Neutral Zone",  file: "assets/designs/neutral-zone.png" },
  { id: "playmaker-award",   name: "Playmaker Award",          file: "assets/designs/playmaker-award.png" },
  { id: "beer-league",       name: "Future Beer League Legend", file: "assets/designs/beer-league-legend.png" },
  { id: "shutout-specialist",name: "Shutout Specialist",       file: "assets/designs/shutout-specialist.png" },
  { id: "tiny-human",        name: "Tiny Human, Large Opinions", file: "assets/designs/tiny-human.png" },
];

/* ---- State ---- */
const state = {
  mode: "gallery",
  designId: null,
  file: null,
};

const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];

/* ------------------------------------------------------------------ */
/*  Build gallery                                                     */
/* ------------------------------------------------------------------ */
function buildGallery() {
  const grid = $("#galleryGrid");
  grid.innerHTML = "";
  DESIGNS.forEach((d) => {
    const el = document.createElement("button");
    el.type = "button";
    el.className = "design";
    el.dataset.id = d.id;
    el.innerHTML = `
      <div class="thumb"><img src="${d.file}" alt="${d.name} puck design" loading="lazy" /></div>
      <div class="name">${d.name}</div>
      ${d.personalize ? '<span class="badge">Personalize</span>' : ""}
    `;
    el.addEventListener("click", () => selectDesign(d.id, true));
    grid.appendChild(el);
  });
}

function selectDesign(id, scroll = false) {
  state.designId = id;
  state.mode = "gallery";

  // reflect mode radio
  const radio = $('input[name="mode"][value="gallery"]');
  if (radio) radio.checked = true;
  syncModePanels();

  // highlight in gallery
  $$(".design").forEach((d) => d.classList.toggle("selected", d.dataset.id === id));

  // chosen box
  const d = DESIGNS.find((x) => x.id === id);
  const chosen = $("#chosenDesign");
  if (d) {
    chosen.innerHTML = `
      <img src="${d.file}" alt="" />
      <div>
        <div class="c-name">${d.name}</div>
        ${d.personalize ? '<span class="muted small">Add a name / number above to personalize</span>' : '<span class="muted small">Ready to order</span>'}
      </div>`;
  }

  updatePreview();
  if (scroll) $("#order").scrollIntoView({ behavior: "smooth" });
}

/* ------------------------------------------------------------------ */
/*  Mode switching                                                    */
/* ------------------------------------------------------------------ */
function syncModePanels() {
  $$(".mode-panel").forEach((p) => (p.hidden = p.dataset.mode !== state.mode));
}

$$('input[name="mode"]').forEach((r) =>
  r.addEventListener("change", (e) => {
    state.mode = e.target.value;
    syncModePanels();
    updatePreview();
  })
);

/* ------------------------------------------------------------------ */
/*  Upload                                                            */
/* ------------------------------------------------------------------ */
const MAX_BYTES = 10 * 1024 * 1024;
const fileInput = $("#fileInput");
const dropzone = $("#dropzone");

function handleFile(file) {
  if (!file) return;
  if (file.size > MAX_BYTES) {
    showError("That file is over 10 MB. Please upload a smaller image.");
    return;
  }
  hideError();
  state.file = file;
  $("#fileName").textContent = `Selected: ${file.name}`;
  updatePreview();
}

fileInput.addEventListener("change", (e) => handleFile(e.target.files[0]));

["dragenter", "dragover"].forEach((ev) =>
  dropzone.addEventListener(ev, (e) => {
    e.preventDefault();
    dropzone.classList.add("drag");
  })
);
["dragleave", "drop"].forEach((ev) =>
  dropzone.addEventListener(ev, (e) => {
    e.preventDefault();
    dropzone.classList.remove("drag");
  })
);
dropzone.addEventListener("drop", (e) => {
  const file = e.dataTransfer.files[0];
  if (file) {
    fileInput.files = e.dataTransfer.files;
    handleFile(file);
  }
});

/* ------------------------------------------------------------------ */
/*  Live preview                                                      */
/* ------------------------------------------------------------------ */
const previewImage = $("#previewImage");
const previewPlaceholder = $("#previewPlaceholder");
const previewText = $("#previewText");

function updatePreview() {
  let src = null;

  if (state.mode === "gallery" && state.designId) {
    const d = DESIGNS.find((x) => x.id === state.designId);
    src = d ? d.file : null;
  } else if (state.mode === "upload" && state.file) {
    if (state.file.type.startsWith("image/")) {
      src = URL.createObjectURL(state.file);
    }
  }

  if (src) {
    previewImage.src = src;
    previewImage.style.display = "block";
    previewPlaceholder.style.display = "none";
  } else {
    previewImage.style.display = "none";
    previewPlaceholder.style.display = "block";
    previewPlaceholder.innerHTML =
      state.mode === "idea"
        ? "We'll design<br/>this for you"
        : state.mode === "upload"
        ? "Upload art to<br/>preview it"
        : "Your design<br/>appears here";
  }

  // custom text overlay
  const txt = $("#customText").value.trim();
  previewText.textContent = txt;
}

$("#customText").addEventListener("input", updatePreview);

/* ------------------------------------------------------------------ */
/*  Quantity                                                          */
/* ------------------------------------------------------------------ */
const qtyInput = $("#qty");
$$(".qty-btn").forEach((b) =>
  b.addEventListener("click", () => {
    const step = parseInt(b.dataset.step, 10);
    const next = Math.max(1, (parseInt(qtyInput.value, 10) || 1) + step);
    qtyInput.value = next;
  })
);
qtyInput.addEventListener("change", () => {
  if (!qtyInput.value || parseInt(qtyInput.value, 10) < 1) qtyInput.value = 1;
});

/* ------------------------------------------------------------------ */
/*  Validation helpers                                                */
/* ------------------------------------------------------------------ */
const formError = $("#formError");
function showError(msg) {
  formError.textContent = msg;
  formError.hidden = false;
  formError.scrollIntoView({ behavior: "smooth", block: "center" });
}
function hideError() {
  formError.hidden = true;
}

function validate() {
  const name = $("#name").value.trim();
  const email = $("#email").value.trim();
  if (!name) return "Please enter your name.";
  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return "Please enter a valid email.";

  if (state.mode === "gallery" && !state.designId)
    return "Pick a design from the gallery first.";
  if (state.mode === "upload" && !state.file)
    return "Upload your artwork, or switch to another option.";
  if (state.mode === "idea" && !$("#ideaText").value.trim())
    return "Tell us a little about your idea.";
  return null;
}

/* ------------------------------------------------------------------ */
/*  Submit                                                            */
/* ------------------------------------------------------------------ */
const form = $("#orderForm");
const submitBtn = $("#submitBtn");

function buildSummary() {
  const lines = [];
  const modeLabel = { gallery: "Chose a design", upload: "Uploaded own art", idea: "Submitted an idea" }[state.mode];
  lines.push(`Design method: ${modeLabel}`);
  if (state.mode === "gallery") {
    const d = DESIGNS.find((x) => x.id === state.designId);
    lines.push(`Design: ${d ? d.name : "—"}`);
  }
  if (state.mode === "upload") lines.push(`Uploaded file: ${state.file ? state.file.name : "—"}`);
  if (state.mode === "idea") lines.push(`Idea: ${$("#ideaText").value.trim()}`);
  const txt = $("#customText").value.trim();
  if (txt) lines.push(`Text on puck: "${txt}"`);
  lines.push(`Quantity: ${qtyInput.value}`);
  const notes = $("#notes").value.trim();
  if (notes) lines.push(`Notes: ${notes}`);
  return lines.join("\n");
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const err = validate();
  if (err) return showError(err);
  hideError();

  const summary = buildSummary();
  const name = $("#name").value.trim();
  const email = $("#email").value.trim();

  submitBtn.disabled = true;
  submitBtn.textContent = "Sending…";

  // Preferred path: post to a form service (handles file uploads + emails you)
  if (CONFIG.FORM_ENDPOINT) {
    try {
      const fd = new FormData();
      fd.append("name", name);
      fd.append("email", email);
      fd.append("_subject", `New puck request from ${name}`);
      fd.append("order_summary", summary);
      if (state.mode === "upload" && state.file) fd.append("artwork", state.file);

      const res = await fetch(CONFIG.FORM_ENDPOINT, {
        method: "POST",
        body: fd,
        headers: { Accept: "application/json" },
      });
      if (!res.ok) throw new Error("Bad response");
      success();
    } catch (e2) {
      showError("Sorry — something went wrong sending your request. Please email us directly at " + CONFIG.SHOP_EMAIL + ".");
    } finally {
      resetBtn();
    }
    return;
  }

  // Fallback: open the visitor's email client with everything pre-filled.
  const body = encodeURIComponent(
    `Hi Puck Lab,\n\nI'd like to order a custom puck.\n\n${summary}\n\nName: ${name}\nEmail: ${email}\n` +
      (state.mode === "upload" ? "\n(Note: please reply and I'll attach my artwork file.)\n" : "")
  );
  const subject = encodeURIComponent(`Custom puck request from ${name}`);
  window.location.href = `mailto:${CONFIG.SHOP_EMAIL}?subject=${subject}&body=${body}`;
  success();
  resetBtn();
});

function resetBtn() {
  submitBtn.disabled = false;
  submitBtn.textContent = "Request my free proof";
}

/* ------------------------------------------------------------------ */
/*  Success modal                                                     */
/* ------------------------------------------------------------------ */
const modal = $("#successModal");
function success() {
  modal.hidden = false;
}
function closeModal() {
  modal.hidden = true;
}
$("#modalClose").addEventListener("click", closeModal);
$("#modalOk").addEventListener("click", closeModal);
modal.addEventListener("click", (e) => {
  if (e.target === modal) closeModal();
});

/* ------------------------------------------------------------------ */
/*  Nav toggle + misc                                                 */
/* ------------------------------------------------------------------ */
const navToggle = $(".nav-toggle");
const nav = $(".nav");
navToggle.addEventListener("click", () => {
  const open = nav.classList.toggle("open");
  navToggle.setAttribute("aria-expanded", String(open));
});
$$(".nav a").forEach((a) => a.addEventListener("click", () => nav.classList.remove("open")));

$("#year").textContent = new Date().getFullYear();

/* ------------------------------------------------------------------ */
/*  Init                                                              */
/* ------------------------------------------------------------------ */
buildGallery();
syncModePanels();
updatePreview();
// Seed the hero puck with a featured design
$("#heroPuckFace").style.backgroundImage = "url('assets/designs/biscuit-deployed.png')";
