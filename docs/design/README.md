# Design

How this extension is specified and sliced. Running code stays at the
repository root (`lib/`, `tests/`, `examples/`). Folders under
[`implementations/`](implementations/) are the design-and-slice
projects.

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
| This project | `/home/dharmatech/src/chezmacs-worksheet-mode` |
| Editor (e / chezmacs) | `/home/dharmatech/src/e` |
| MPL (sample library) | `/home/dharmatech/src/mpl` |
| Other R6RS collections | `/home/dharmatech/src/surfage`, `/home/dharmatech/src/dharmalab`, and anything else under `/home/dharmatech/src` |

## Implementations

| Project | Path | Status |
|---|---|---|
| Worksheet | [`implementations/worksheet/`](implementations/worksheet/) | Done (000–001). No 002 in that series. |
| Insert result | [`implementations/insert-result/`](implementations/insert-result/) | Spec written. `C-c C-c` is in the running extension. |

Code: `lib/worksheet-env.sls`, `lib/worksheet-mode.sls`,
`tests/worksheet-env.ss`, `tests/insert-result.ss`,
`examples/mpl.ws`.

## Not in the original worksheet series

- Importing libraries into the editor's global interaction environment
- Prefixing library names at the worksheet (`mpl:+` and the like)
- Loading `(mpl all)` with `kernel:load-module!`
- An MPL-only mode, auto-`vars`, or MPL as the default import set
- Patching e's kernel, fingerprint, or daemon
- Vendoring MPL, Surfage, or Dharmalab into e's `lib/`

Inserting `; =>` evaluation results is
[`implementations/insert-result/`](implementations/insert-result/).
