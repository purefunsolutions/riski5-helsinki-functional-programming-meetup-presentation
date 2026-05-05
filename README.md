<!--
SPDX-FileCopyrightText: 2026 Mika Tammi
SPDX-License-Identifier: CC-BY-4.0
-->

# riski5 — Helsinki Functional Programming meetup presentation

Slide deck for the **2026-05-05 Helsinki Functional Programming meetup**
talk on building [riski5][riski5] — a RISC-V soft core in
[Clash][clash] (Haskell), running on a 22-year-old Altera DE2 FPGA, with
Linux 6.18.22 booting on real silicon.

The deck is **plain HTML5** (Pandoc DZSlides), arrow-key navigable, and
deployed via GitHub Pages from `master/docs/`.

[riski5]: https://github.com/purefunsolutions/riski5
[clash]: https://clash-lang.org/

## Live deck

→ <https://purefunsolutions.github.io/riski5-helsinki-functional-programming-meetup-presentation/>

(Once GitHub Pages is enabled — see *Deploying* below.)

Keyboard navigation:

| Key            | Action                  |
|----------------|-------------------------|
| `→` / `↓` / `Space` | next slide         |
| `←` / `↑`      | previous slide          |
| `Home`         | first slide             |
| `End`          | last slide              |

## Local preview

```sh
nix develop                 # ghc, cabal, hakyll, pandoc, graphviz, …
cabal run site -- watch     # http://localhost:8000, live-reload
```

To build once into `docs/` (the deployed artifact):

```sh
cabal run site -- build
```

To wipe `_cache/` + `docs/`:

```sh
cabal run site -- clean
```

## Editing the deck

- Slides are a single Markdown file: [`SLIDES.md`](./SLIDES.md)
- `## Heading` is one slide (because `--slide-level=2`)
- `# Heading` introduces a section cluster (becomes a title slide)
- Diagrams: edit [`assets/diagrams/*.dot`](./assets/diagrams/) and
  Hakyll re-renders to SVG via the `dot` CLI on save (when running
  under `cabal run site -- watch`)
- Custom CSS in [`assets/css/overrides.css`](./assets/css/overrides.css)
  (lambda-corner branding, font tweaks)

## Deploying to GitHub Pages

1. Push `master` to GitHub
2. Repo → Settings → Pages → Source: **Deploy from a branch**
3. Branch: **`master`**, folder: **`/docs`**
4. Wait ~60 s, deck is live at the URL above

The built artifact (`docs/`) is committed alongside source — no CI
required. Rebuild locally before each push.

## Format / lint

```sh
nix fmt                     # alejandra + fourmolu + prettier + deadnix + statix
nix flake check             # REUSE compliance + treefmt --ci
```

## Licensing

Dual-licensed:

- **Code** (`site.hs`, `flake.nix`, `nix/*`, `cabal.project`,
  `presentation.cabal`, `fourmolu.yaml`) — **MIT**
- **Content** (`SLIDES.md`, `assets/css/*`, `assets/diagrams/*`,
  `assets/images/*`, `README.md`, `CLAUDE.md`) — **CC-BY-4.0**

Per-file SPDX headers are enforced via `nix flake check` (REUSE 6.x).

The Pure Fun Solutions lambda logo (`assets/images/lambda-logo.png`) is
copied from <https://github.com/purefunsolutions/purefun-front>.

## Sibling repos

- [`alterade2-flake`](https://github.com/purefunsolutions/alterade2-flake) —
  Quartus II 13.0sp1 + USB-Blaster on NixOS
- [`verilambda`](https://github.com/purefunsolutions/verilambda) —
  Haskell-Verilator bindings, type-preserving
- [`riski5`](https://github.com/purefunsolutions/riski5) — the RISC-V core
  itself
