# Implementations

Each folder is one design-and-slice project: `charter.md`, `spec.md`,
`checkpoints/`. Code for the running extension stays at the
repository root (`lib/`, `tests/`, `examples/`).

| Project | Path | Status |
|---|---|---|
| Worksheet | [`worksheet/`](worksheet/) | Implemented (000–001). Mode `"worksheet"`: a file's leading `(import …)` is its Chez top level. |
| Insert result | [`insert-result/`](insert-result/) | Spec written. `C-c C-c` is in the running extension. |

Pipeline, trees, and non-goals: [`../README.md`](../README.md).
