# chezmacs worksheets (MPL as first customer)

Experiment: a chezmacs **worksheet** is a Scheme program with its own
top level, taken from the file's leading `(import …)` forms.
`C-x C-e` in that buffer uses that environment. `M-x` stays the
editor, with Chez `+`.

[MPL](https://github.com/dharmatech/mpl) is the first customer, not
the mode. An MPL worksheet imports MPL in the file, then writes
idiomatic `(+ x x)` with no `mpl:` prefix.

The editor's checkout and command are still `e`
([github.com/paveluv/e](https://github.com/paveluv/e),
`/home/dharmatech/src/e`). This project calls the editor **chezmacs**.

This directory is the journal. Running extension code is at the root
(`lib/`, `tests/`, `examples/`). Design documents live under
[`docs/design/implementations/`](docs/design/implementations/). Do not
vendor MPL into chezmacs's `lib/`. Do not treat this as chezmacs
upstream work until a later review.

## Pipeline

```text
this conversation (high-level discussion)
        └─ docs/design/implementations/<project>/charter.md
                │
                ▼
        designer conversation  →  spec.md in that folder  →  stop
                │
                ▼
        checkpoint-manager conversation  →  one checkpoint  →  stop
                │
                ▼
        implementer conversation  →  that checkpoint  →  stop
```

Human review between stages. Do not write the rest of a checkpoint
series in advance.

| Role | Read first |
|---|---|
| Designer | that project's `charter.md` |
| Checkpoint manager | that project's `spec.md` (once it matches its charter) |
| Implementer | the one approved checkpoint file |

If you have been told to read a `charter.md`, that file is the whole
assignment.

## Trees

| Tree | Path |
|---|---|
| This journal | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl` |
| Editor (chezmacs) | `/home/dharmatech/src/e` |
| MPL (sample library) | `/home/dharmatech/src/mpl` |
| Other R6RS collections | `/home/dharmatech/src/surfage`, `/home/dharmatech/src/dharmalab`, and anything else under `/home/dharmatech/src` |

## Implementations

| Project | Path | Status |
|---|---|---|
| Worksheet | [`docs/design/implementations/worksheet/`](docs/design/implementations/worksheet/) | Done (chezmacs-mpl 000–001). No 002 in that series. |
| Insert result | [`docs/design/implementations/insert-result/`](docs/design/implementations/insert-result/) | Charter written. Spec not started. |

Code: `lib/worksheet-env.sls`, `lib/worksheet-mode.sls`,
`tests/worksheet-env.ss`, `examples/mpl.ws`.

## Not in the worksheet project

- Inserting evaluation results into the buffer (worksheet UI)
- Importing libraries into chezmacs's global interaction environment
- Prefixing library names at the worksheet (`mpl:+` and the like)
- Loading `(mpl all)` with `kernel:load-module!`
- An MPL-only mode, auto-`vars`, or MPL as the default import set
- Patching chezmacs's kernel, fingerprint, or daemon
- Vendoring MPL, Surfage, or Dharmalab into chezmacs's `lib/`
