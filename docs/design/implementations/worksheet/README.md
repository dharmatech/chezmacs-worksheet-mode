# Worksheet

chezmacs mode `"worksheet"`: a Scheme program whose leading
`(import …)` forms are its namespace. `C-x C-e` evaluates in that
buffer's private top level. `M-x` stays the editor. MPL is the
sample library, not the mode.

| Artifact | Path |
|---|---|
| Charter | [`charter.md`](charter.md) |
| Spec | [`spec.md`](spec.md) |
| Checkpoints | [`checkpoints/000-env-algebra.md`](checkpoints/000-env-algebra.md), [`checkpoints/001-worksheet-mode.md`](checkpoints/001-worksheet-mode.md) |

Code (repository root): `lib/worksheet-env.sls`, `lib/worksheet-mode.sls`,
`tests/worksheet-env.ss`, `examples/mpl.ws`.

**Status.** 000 and 001 implemented and reviewed. There is no 002
in this project. Inserting `; =>` results under point is
[`../insert-result/`](../insert-result/), not a continuation of
this series.

Design map: [`../../README.md`](../../README.md).
