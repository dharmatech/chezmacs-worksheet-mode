# Charter — MPL evaluation in chezmacs

**Status.** Handoff from the high-level discussion in Grok (journal
`2026-09-21-chezmacs-mpl`) into a **design conversation**. Not
chezmacs upstream. Not a checkpoint. Not an implementer assignment.
Specification will live beside this file as [`spec.md`](spec.md).
Parent map: [`README.md`](README.md).

The editor's checkout and command are still `e`
(`/home/dharmatech/src/e`). This project calls the editor
**chezmacs**. Paths, `config.e`, and the `.e` config extension keep
their on-disk names.

**Your job.** Turn this charter into a specification for a **personal
chezmacs extension** that gives a worksheet file its own Scheme top
level, so idiomatic MPL `(+ x x)` evaluates as computer algebra,
while the editor's `M-x` keeps Chez `+`. Then **stop**. Do not write
checkpoints. Do not implement. Do not specify inserting results into
the buffer, a CAS UI, or changes to chezmacs's kernel.

If you have been told to read this file, this is the whole assignment.

---

## 1. How this conversation works

1. Read this charter, [`README.md`](README.md), and the authority in
   §5. Inspect those trees. Do not rely on the Grok transcript; this
   file is the assignment.
2. Record the locked decisions in §4. Resolve the open questions in
   §4.8–§4.12.
3. Write `spec.md` in this folder. A later checkpoint-manager
   conversation slices **chezmacs-mpl 000**, `001`, … under
   `checkpoints/` in this same directory.
4. Stop. The human reviews it. Do not write those checkpoint files.

The checkpoint manager and implementers will not have this charter.
Put every rule they need in the specification.

Keep the spec **small enough to slice**. A full CAS IDE, result
insertion into the buffer, hot-reload of MPL sources, a new describe
corpus for MPL, and a patch series against chezmacs's daemon are
defects in this document.

## 2. Predecessors (do not start without these)

| What | Ready when |
|---|---|
| chezmacs | `/home/dharmatech/src/e` builds and runs (Chez 10.4.1 is installed as `scheme` / `scheme-script`) |
| MPL | `/home/dharmatech/src/mpl` with `surfage` and `dharmalab` beside it under `/home/dharmatech/src` |
| Proven Chez construction | §4.3. A designer who re-derives a different environment story is wrong |

No chezmacs source change is a predecessor. The extension must load
as third-party code. If a later seam in `eval.sls` would be nicer,
name it as a **follow-on**, not as this spec's required patch.

## 3. Bar (acceptance)

The specification is wrong unless all of these are true:

1. **A file, not a prefix.** A worksheet buffer can contain
   `(+ x x)` and evaluate it to `(* 2 x)`. The user does not write
   `mpl:+` or `all:+`.
2. **The editor is unharmed.** After the extension is loaded,
   `M-x (+ 1 2)` is still Chez arithmetic (`3`). Editor commands
   (`head:`, `eval:`, …) keep their current meaning. MPL's `+` is
   not imported into `(interaction-environment)`.
3. **The environment is the file's.** `C-x C-e` in a worksheet
   buffer evaluates in that buffer's mutable Chez environment, not
   in the editor top level. A second worksheet does not share
   definitions with the first unless the spec names a deliberate
   sharing rule (the expected rule is: no sharing).
4. **It is a Chez program, not an R6RS library.** The worksheet
   looks like a top-level script: optional leading `(import …)`,
   then definitions and expressions. `(library (foo) …)` is not
   the worksheet shape.
5. **First consumer is tests plus one sample file.** There is a
   Chez-script test (no TTY, no running chezmacs) that builds the
   private environment and checks at least:
   - `(+ x x)` → `(* 2 x)`
   - `(algebraic-expand (alge "(x+1)^2"))` → `(+ 1 (* 2 x) (^ x 2))`
   - `(derivative (alge "sin(x)") x)` → `(cos x)`
   - `(+ 1 2)` in `(interaction-environment)` is still `3` after
     the private env exists
   And there is a sample `*.mpl` (or the extension the spec
   chooses) in this journal directory a human can open in
   chezmacs.
6. **The chezmacs piece is a mode-shaped extension**, loaded with
   `kernel:load-module!` of **the extension**, not of MPL. It
   binds worksheet `C-x C-e` in that mode's keymap context so the
   global editor binding is left alone in ordinary Scheme buffers.
7. Anything the spec needs from chezmacs (`eval` logging, `C-g`,
   echo area) is either reused without patching chezmacs, or
   duplicated in the extension, or named as an optional later seam.
   This spec must ship without editing
   `/home/dharmatech/src/e/lib/**` unless the human later promotes
   a seam. Default: **do not edit the chezmacs tree**.

## 4. Locked decisions (record these; do not reopen 4.1–4.7)

### 4.1 The problem is one interaction environment

chezmacs evaluates `M-x` and `C-x C-e` in
`(interaction-environment)`. That is correct for editor commands.
It is wrong for a computer algebra worksheet.

MPL's `(mpl all)` exports bare `+`, `-`, `*`, `/`, `^`, `sqrt`,
`alge`, `vars`, `algebraic-expand`, `derivative`, and related
names. That is the experience we want **in the file**. Importing
`(mpl all)` into the editor top level would give that experience
everywhere, including `M-x`. Do not do that.

`kernel:load-module!` is the wrong loader for MPL: it prefixes the
library by file stem (`all:+`) and expects `init!`. MPL is a
third-party R6RS collection, not a chezmacs module.

### 4.2 Per-buffer environment, mode for keys

Each worksheet buffer owns a mutable Chez environment.

`M-x` always uses the editor interaction environment.

`C-x C-e` in a worksheet buffer uses that buffer's environment.
In a normal Scheme buffer it keeps today's meaning.

A new mode is the hook. chezmacs already resolves keys in the
current mode context before the global map (`mode:key-context`,
then `keymap` context named after the mode). The worksheet mode
owns `C-x C-e`. Highlighting, indent, and format should be
Scheme's; do not invent a new syntax highlighter. Reuse
scheme-mode's styler, indenter, and formatter if they are
reachable from the registry; if they are not, say how the
worksheet still looks like Scheme without copying
`scheme-mode.sls`.

Do not steal `.ss` / `.sls` from scheme-mode. Use a distinct
ending (see §4.8).

### 4.3 How the environment is built (proven)

Chez will not `eval` an `(import …)` form into a copied
environment. `import` is syntax only at a program, library, or
the interaction environment. A designer who specifies "eval the
import form in the buffer env" is wrong.

The proven construction:

```scheme
(library-directories
  (cons (cons "/home/dharmatech/src"
              "<object-cache>")
        (library-directories)))

(define env
  (copy-environment
    (apply environment '((mpl rnrs-sans) (mpl all)))
    #t))

(eval '(vars a b c x y z) env)
(eval '(+ x x) env)   ; => (* 2 x)
```

`(mpl rnrs-sans)` is MPL's RNRS-without-clashes. Together with
`(mpl all)` it is the default import set.

Object files may go in chezmacs's `eo/client` (MPL was already
compiled there on 2026-09-21) or in a cache under this journal
directory. Pick one in the spec and keep compilation out of
`~/src` itself.

`library-directories` must include `/home/dharmatech/src` so
`(mpl all)` maps to `~/src/mpl/all.sls`, `(surfage …)` to
`~/src/surfage/…`, `(dharmalab …)` to `~/src/dharmalab/…`. Adding
`~/src/mpl` as a root is wrong (`mpl/mpl/all.sls`).

### 4.4 Leading import forms are environment spec, not eval

A worksheet may begin with

```scheme
(import (mpl rnrs-sans)
        (mpl all))

(vars x y)

(+ x x)
```

The spec must treat leading `import` forms as the list of
import-specs passed to `environment`, then evaluate the remaining
top-level forms in the mutable copy. Evaluating a region that is
only `(+ x x)` still uses that environment (built from the file
header, or from the mode default if there is no header).

Default when the file has no `import`: `((mpl rnrs-sans) (mpl all))`.

`define` and `vars` persist in that copy for the life of the
buffer environment. Recreating the environment drops them. Name
when recreation happens (import-header change is the expected
trigger; killing the buffer is another).

### 4.5 Runtime handles stay off the store

Do not store a Chez environment object in buffer facts that the
base might serialize. Keep environments in head-local memory
keyed by buffer (a weak table is the expected shape). Facts may
record serializable hints (mode name, chosen import list as
datums) if useful; the live env is not a fact.

### 4.6 Where code lives

All new code for this experiment lives under

`/home/dharmatech/journal/2026-09-21-chezmacs-mpl/`

Suggested layout the spec may refine:

```text
charter.md                 this file
spec.md                    designer output
checkpoints/               later
README.md                  map
lib/                       chezmacs extension library source
tests/                     Chez-script tests
examples/                  sample worksheet(s)
```

The extension is a chezmacs module: a `.sls` with `init!`, loaded
from the user's `config.e` via `kernel:load-module!` after this
journal directory (or `lib/` inside it) is on
`library-directories`. The spec must give the exact `config.e`
snippet, including adding `~/src` for MPL.

Do not copy MPL sources into this tree or into the chezmacs tree.

Do not add the extension to chezmacs's bundled
`kernel:load-modules!` list in `main.sls`.

### 4.7 Out of this layer

- Inserting `; => (* 2 x)` or a result line under point
  (worksheet UI). Same environment; later project.
- Rebinding `M-x` in worksheet buffers
- Prefixing MPL identifiers
- Importing MPL into `(interaction-environment)`
- `kernel:load-module!` of `"all"` or any MPL stem
- Editing the chezmacs tree under `/home/dharmatech/src/e`
  (default)
- Fingerprint / daemon / wire changes
- Hot-reload of `~/src/mpl` when those files are saved
- A describe/edoc corpus for MPL
- Infix input except MPL's existing `(alge "…")`
- Sharing one env across heads or across buffers

### 4.8 File ending and mode name (resolve this)

Pick a mode name and a distinct file ending that will not steal
scheme-mode's `.scm` / `.ss` / `.sls` / `.e`.

Candidates discussed: `.mpl`, `.mpl.ss`. Pick one. Detection is
by ending. A human may still `(mode:choose! … "mpl")` on another
buffer if the spec wants that command; it is not required.

### 4.9 Free variables / `vars` (resolve this)

`(+ x x)` is unbound unless `x` is bound to `'x`. MPL's tests
call `(vars a b c d x y z pi t)`.

Lock auto-initialization of a `vars` set when a buffer environment
is created, so a new empty worksheet can be just `(+ x x)`. Name
the exact set. The file may still contain `(vars …)`; that must
keep working.

Do not invent an unbound-identifier handler that self-quotes every
unknown symbol unless you can show it is smaller than auto-`vars`
and does not swallow real errors.

### 4.10 How `C-x C-e` reports (resolve this)

Today `eval:run!` logs, copies non-void results to the kill ring,
captures stdout/stderr, and is interruptible with `C-g`.

Specify what the worksheet command reuses. Allowed:

- Call into existing `eval:` helpers if they can take an
  environment without changing chezmacs (they currently cannot;
  they hardcode `(interaction-environment)`).
- Duplicate a small evaluate-and-echo path in the extension.
- Name a **follow-on** one-function seam in `lib/apps/eval.sls`
  (`eval` this text in this environment) that this experiment
  does **not** require.

Minimum bar: the last value shows in the echo area; errors show
as errors; the editor does not crash; `C-g` should interrupt if
that can be done with public `head:` / `eval:` APIs. Kill-ring
copy and log records are desirable if cheap, not a reason to
patch chezmacs.

Evaluating the **region** if the mark is active, else the whole
buffer, should match chezmacs's current `C-x C-e` shape, except
`import` forms in a whole-buffer eval are environment spec
(§4.4), not expressions.

### 4.11 Tests and verification (resolve this)

Name:

- the Chez-script test file(s) and how they are run
  (`scheme --script …` or `uv` is wrong; this is Scheme)
- the sample worksheet path
- any hand check in chezmacs (open file, `C-x C-e`, echo shows
  `(* 2 x)`; `M-x (+ 1 2)` shows `3`)

The environment layer must be testable without launching
chezmacs. The mode/key binding may be a named hand check if an
automated chezmacs test would require the interactive harness; do
not block the spec on writing a new chezmacs TTY test suite.

### 4.12 Extension library shape (resolve this)

Specify the library name, file path, exports, and `init!`
registrations (mode, keymap, any `doc:register!`).

Keep a split the checkpoint manager can slice:

1. **Env algebra** (library-directories, `environment` /
   `copy-environment`, parse leading imports, eval forms, auto
   `vars`) — Chez tests only.
2. **chezmacs module** (mode, `C-x C-e`, config snippet, sample
   file) — depends on 1.

If you need more than those two layers, say why. Do not add a
third layer for "future worksheet insert."

## 5. Authority

Inspect these; they are law for chezmacs's seams and MPL's API.
This charter wins if they conflict with "make it feel more
complete."

- [`README.md`](README.md) — this project
- `/home/dharmatech/src/e/README.md`
- `/home/dharmatech/src/e/manual/EVAL.md` — `M-x`, `C-x C-e`,
  interaction environment
- `/home/dharmatech/src/e/manual/MODULES.md` — extension shape,
  `kernel:load-module!`, prefixes, hot reload
- `/home/dharmatech/src/e/manual/KEY_BINDING.md` — mode context
  before global map
- `/home/dharmatech/src/e/lib/apps/eval.sls` — hardcoded
  `(interaction-environment)`
- `/home/dharmatech/src/e/lib/core/kernel.sls` — `load-module!`,
  `init-module!` prefixing
- `/home/dharmatech/src/e/lib/head/mode.sls` — `key-context`,
  `register!`, detection by ending
- `/home/dharmatech/src/e/lib/head/dispatch.sls` — mode context
  then global
- `/home/dharmatech/src/e/config.template.e` — how users load
  extra modules
- `/home/dharmatech/src/mpl/README`, `all.sls`, `rnrs-sans.sls`,
  `misc.sls` (`vars`), `test.sls` (examples)
- Chez User's Guide: `environment`, `copy-environment`, `eval`,
  `library-directories`, `import` (program / library / REPL only)

The chezmacs tree's `AGENTS.md` applies only if someone later
commits into that tree. This experiment does not.

## 6. Non-goals

- Worksheet "eval and insert result below point"
- A Maxima/Mathematica notebook UI
- Changing MPL, Surfage, or Dharmalab
- Making MPL a bundled chezmacs module
- Using MPL's `+` for chezmacs's own arithmetic
- Evaluating inside `(library …)` forms as if they were a REPL
- Multi-head shared REPL state
- Windows / non-Chez Scheme

## 7. Goldens the spec must keep

These were run against the trees above. The spec's tests should
include them, not replace them with weaker checks.

```text
(+ x x)                                              => (* 2 x)
(* x y x)                                            => (* (^ x 2) y)
(+ x y x z 5 z)                                      => (+ 5 (* 2 x) y (* 2 z))
(algebraic-expand (alge "(x+1)^2"))                  => (+ 1 (* 2 x) (^ x 2))
(algebraic-expand (alge "(x+2)*(x+3)*(x+4)"))        => (+ 24 (* 26 x) (* 9 (^ x 2)) (^ x 3))
(derivative (alge "sin(x)") x)                       => (cos x)
(derivative (alge "x^3 + 3*x^2 + 5") x)              => (+ (* 6 x) (* 3 (^ x 2)))
(+ 1 2) in the editor interaction environment        => 3
```

`alge` takes an infix string and is part of `(mpl all)`. Symbolic
`sin` / `cos` need not be bound as procedures in the worksheet;
`(alge "sin(x)")` builds the expression `derivative` understands.
