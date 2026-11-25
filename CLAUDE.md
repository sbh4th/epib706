# EPIB 706: Doctoral Seminar (McGill)

Sam Harper's PhD seminar syllabus, written in Quarto and published as a GitHub Pages site from `docs/` (https://samharper.org/epib706). Sam works on it from two machines (home and work), so pull before starting and push when done.

## How the site is built

- `_quarto.yml` is a website project with `output-dir: docs`. It renders **only** `epib706.qmd`.
- `epib706.qmd` is the **live, stable-URL syllabus**. It renders to `docs/epib706.html` and `docs/epib706.pdf`, and `docs/index.html` redirects to `epib706.html`.
- Year-specific files (`epib706-2024.qmd`, `epib706-2026.qmd`, `epib706-2027.qmd`) are archives or drafts. They are **not** rendered to the site.
- Each file has two output formats: HTML (theme materia) and Typst PDF, using `typst-template.typ`, `typst-show.typ`, the C059 font from `fonts/`, and `chicago-syllabus.csl`.
- The bibliography is `EPIB706.bib`, a Zotero/Better BibTeX export. Re-exports can rename citation keys. For example, `downes2020` became `downes2020a` and `lesko2020` became `lesko2020a`. After re-exporting, check that every `@key` in the .qmd files still exists, or the Typst PDF build fails.
- Class dates come from an R chunk: `w1c1` is the first Tuesday, `w1c2` the first Thursday, and `classdate(w1c1, week)`. Week 9 is the winter-break placeholder.
- `docs/`, `site_libs/`, `*_cache/` and `*.typ` are generated. On a merge conflict in generated files, settle the `.qmd`/`_quarto.yml` side first and then take one side's output or re-render. Don't hand-merge them.

## Status (as of Nov 2026): Winter 2027 term

- `epib706-2027.qmd` is the working draft for Winter 2027. It has the same units and readings as 2026, including the Feb 2026 swap of Lu 2025 for Lesko 2020 (`lesko2020a`) in Unit 9.
  - Class meets Tue/Thu 1435h–1555h in 2001 McGill College, Room 1140. It starts Tue 2027-01-05, and the last class is Thu 2027-04-08.
  - Essay outline is due 2027-03-16 and the final essay 2027-04-15.
- The live site still shows the 2026 syllabus (Sam's decision, Nov 2026). When publishing for January, copy the 2027 content into `epib706.qmd`. Then set the PDF `output-file` and the "PDF version" link to `epib706.pdf`, not a year-stamped name, and re-render.
- Still to update in the 2027 draft:
  - Winter break week: it is assumed to be Mar 2/4, 2027. Check this against McGill's 2027 calendar.
  - New MyCourses course ID: `840723` is the 2026 shell. It appears in the info table and in the Discussions link.
  - New Google sign-up sheet link, and the "24 sessions and 16 students" sentence.
- Known bug on the live site: `epib706.qmd` links to `/epib706-2026.pdf`, but the published PDF is `docs/epib706.pdf`.

## Candidate 2025–26 readings (explored Nov 2026, none added yet)

These were found via scite, and every DOI was verified. None are in `EPIB706.bib` yet.

- **Unit 2 (estimands):** Moreno-Betancur et al. 2026, "The Ideal Trial", Epidemiology, 10.1097/ede.0000000000001933.
- **Unit 3/5 (policy as an exposure):** Schnake-Mahl & Diez Roux 2025, AJE, 10.1093/aje/kwae468.
- **Unit 4 (race):**
  - Loux & Wankum 2026, "Does race have confounders?", JECH, 10.1136/jech-2026-226475, with the reply by Reynolds & Labrecque, 10.1136/jech-2026-226803. This is a strong debate pair.
  - Horsfall et al. 2025, race-based correction in clinical algorithms, Clin Epidemiol, 10.2147/clep.s527000. A possible update for Vyas 2020.
- **Unit 5 (target trials):** Hernán & Dickerman 2026, "Where do target trials come from?", Epidemiology, 10.1097/ede.0000000000001951. A counterpoint to Pearce & Vandenbroucke.
- **Unit 6 (representativeness):**
  - Montgomery et al. 2026, generalizability of All of Us prevalence estimates, AJE, 10.1093/aje/kwag010.
  - Daodu et al. 2026, "Exclusive research is bad science", IJE, 10.1093/ije/dyaf219.
- **Unit 7 (inference):**
  - Hunter et al. 2026, p-value and CI use in epi journals, Glob Epidemiol, 10.1016/j.gloepi.2026.100247.
  - Gartner et al. 2025, "Reflecting on power" (Indigenous health), AJE, 10.1093/aje/kwaf097.
- **Unit 9 (individual effects):** Keele et al. 2026, heterogeneous effects of GLP-1 receptor agonists, AJE, 10.1093/aje/kwag261.
- **Unit 12 (reliability):**
  - Hemani et al. 2025, the growth of Mendelian randomization studies and paper mills, EJE, 10.1007/s10654-025-01317-7.
  - Tenan et al. 2025, jet lag causal and replication analysis, AJE, 10.1093/aje/kwaf120.
- **Unit 13 (AI):**
  - Bann, Lowther & Wright 2026, "Why can't epidemiology be automated (yet)?", IJE, 10.1093/ije/dyaf210. A strong companion to Sen Gupta.
  - Matthay, Neill et al. 2025, AI in causal epidemiology, Curr Epidemiol Rep, 10.1007/s40471-025-00359-5.
- **No good candidates yet** for Unit 1 (the discipline), Unit 8 (bias analysis), Unit 10 (communication) or Unit 11 (triangulation and meta-analysis). A wider search covering JECH, EJE and the Annals of Epidemiology would help.

## Conventions

- Keep Sam's voice in the "Why:" rationales: first person, conversational and candid.
- Render a test copy in a scratch folder before touching `docs/`. `quarto render file.qmd --output-dir` fails inside a project.
