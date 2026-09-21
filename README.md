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

This directory is the project. Do not vendor MPL into chezmacs's
`lib/` for this experiment. Do not treat this as chezmacs upstream
work until a later review.

## Pipeline

```text
this conversation (high-level discussion)
        └─ charter.md
                │
                ▼
        designer conversation  →  spec.md  →  stop
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
| Designer | [`charter.md`](charter.md) |
| Checkpoint manager | [`spec.md`](spec.md) (once it matches this charter) |
| Implementer | the one approved checkpoint file |

If you have been told to read `charter.md`, that file is the whole
assignment.

## Trees

| Tree | Path |
|---|---|
| This project | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl` |
| Editor (chezmacs) | `/home/dharmatech/src/e` |
| MPL (sample library) | `/home/dharmatech/src/mpl` |
| Other R6RS collections | `/home/dharmatech/src/surfage`, `/home/dharmatech/src/dharmalab`, and anything else under `/home/dharmatech/src` |

## Status

- High-level discussion: done (Grok session; charter revised from
  an MPL-only mode to a general worksheet)
- `spec.md`: rewritten against the current charter (mode
  `"worksheet"`, not MPL-only). Law for slices.
- Checkpoints: **chezmacs-mpl 000** implemented and reviewed
  ([`checkpoints/000-env-algebra.md`](checkpoints/000-env-algebra.md)).
  **chezmacs-mpl 001** implemented and reviewed
  ([`checkpoints/001-worksheet-mode.md`](checkpoints/001-worksheet-mode.md)).
  There is no 002.
- Implementation: 000 env algebra (`lib/worksheet-env.sls`,
  `tests/worksheet-env.ss`); 001 chezmacs module
  (`lib/worksheet-mode.sls`, `examples/mpl.ws`, installation
  `config.e` snippet)

## Not in this project

- Inserting evaluation results into the buffer (worksheet UI)
- Importing libraries into chezmacs's global interaction environment
- Prefixing library names at the worksheet (`mpl:+` and the like)
- Loading `(mpl all)` with `kernel:load-module!`
- An MPL-only mode, auto-`vars`, or MPL as the default import set
- Patching chezmacs's kernel, fingerprint, or daemon
- Vendoring MPL, Surfage, or Dharmalab into chezmacs's `lib/`
