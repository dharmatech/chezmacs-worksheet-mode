# chezmacs + MPL worksheets

Experiment: evaluate idiomatic [MPL](https://github.com/dharmatech/mpl)
computer-algebra expressions inside chezmacs without prefixing names
and without rebinding `+` in the editor's own `M-x` top level.

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
| Checkpoint manager | [`spec.md`](spec.md) (once it exists) |
| Implementer | the one approved checkpoint file |

If you have been told to read `charter.md`, that file is the whole
assignment.

## Trees

| Tree | Path |
|---|---|
| This project | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl` |
| Editor (chezmacs) | `/home/dharmatech/src/e` |
| MPL | `/home/dharmatech/src/mpl` |
| MPL dependencies | `/home/dharmatech/src/surfage`, `/home/dharmatech/src/dharmalab` |

## Status

- High-level discussion: done (Grok session that wrote the charter)
- `spec.md`: written (designer conversation; law for later slices)
- Checkpoints: none
- Implementation: none

## Not in this project

- Inserting evaluation results into the buffer (worksheet UI)
- Importing MPL into chezmacs's global interaction environment
- Prefixing MPL names (`mpl:+` and the like)
- Loading `(mpl all)` with `kernel:load-module!`
- Patching chezmacs's kernel, fingerprint, or daemon
- Vendoring MPL, Surfage, or Dharmalab into chezmacs's `lib/`
