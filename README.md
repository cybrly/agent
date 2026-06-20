# Puck Lab — Custom Hockey Puck Shop

A static website for selling custom-designed hockey pucks. Visitors can:

- **Pick a ready-made design** from the gallery (your uploaded artwork)
- **Upload their own** logo / photo / artwork
- **Submit an idea** for you to design and proof

…with a live puck preview, optional custom text, and **no minimum order quantity**.

## Structure

```
index.html            Single-page site (hero, how-it-works, gallery, builder, FAQ)
css/styles.css        Styling (dark, brand-orange theme, fully responsive)
js/main.js            Gallery, builder, live preview, order submission
assets/favicon.svg    Logo / favicon
assets/designs/*.png  Ready-made puck designs shown in the gallery
```

## Running it

It's a plain static site — no build step. Just open `index.html`, or serve the folder:

```bash
python3 -m http.server 8000
# then visit http://localhost:8000
```

## Receiving orders (important)

Order requests are sent from the builder form. Configure how in **`js/main.js`** at the top:

```js
const CONFIG = {
  FORM_ENDPOINT: "",                            // paste your form-service URL here
  SHOP_EMAIL: "christopher.neuwirth@gmail.com", // used for the email fallback
};
```

- **Recommended:** create a free form endpoint (e.g. [Formspree](https://formspree.io)),
  paste its URL into `FORM_ENDPOINT`. The form then POSTs the order — **including the
  uploaded artwork file** — and emails it to you.
- **Fallback (no setup):** leave `FORM_ENDPOINT` empty. The form opens the visitor's
  email client pre-filled with their order details. Note: uploaded files can't be
  auto-attached in this mode, so the email asks them to attach it on reply.

## Managing the design gallery

Add or remove designs by editing the `DESIGNS` array in `js/main.js` and dropping the
image into `assets/designs/`. Set `personalize: true` on a design that's a template
(name/number/date) so it shows a "Personalize" badge and prompts for custom text.

## Notes

- Designs are circular artwork on transparent backgrounds, rendered onto a puck mockup.
- All copy assumes regulation 3"×1" rubber hockey pucks; tweak in `index.html` as needed.
