
Global Structure
===

------------------------
      - builder   → orchestrates pipeline
      - markdown  → data only
      - watcher   → triggers rebuild
      - templates → iolists only
      - assets    → filesystem only
      - sup       → lifecycle only

--------------
 🔥 1. SUPERVISOR — ONLY LIFE CYCLE (no logic)
---
Your supervisor should do nothing except start/stop processes.

Clean mental rule:

if it transforms data, it does NOT belong here

🔥 2. WATCHER — ONLY DETECTION
---

Watcher should ONLY:

detect file changes
notify builder

 ❌ NO markdown parsing
 ❌ NO rendering
 ❌ NO asset logic

🔥 3. BUILDER — THE ONLY “SMART” MODULE
---

This is your compiler driver

It is the ONLY place where:

markdown is read
posts are parsed
index is generated
templates are called
assets sync is triggered

🔥 4. MARKDOWN — PURE DATA LAYER (already improved earlier)
---

Should only expose:

    load_posts/0
    parse_post/1
    make_teaser/1
    sort/1

❌ no file writing
❌ no HTML
❌ no regex on HTML

🔥 5. TEMPLATES — PURE IOLIST GENERATOR
---

Already mostly done in your refactor.

Rule:

- templates never read filesystem
- templates never call builder
- templates never parse markdown

🔥 6. ASSETS — PURE SIDE EFFECT MODULE
---

Already good, just enforce:

 - file → file transformations only
 - no HTML awareness
 - no markdown awareness

 🧠 HOW EVERYTHING CONNECTS NOW
 ---

    watcher
      ↓ (event)
    builder
      ↓
    markdown (data)
      ↓
    templates (iolists)
      ↓
    assets (files)
      ↓
    compiled site
