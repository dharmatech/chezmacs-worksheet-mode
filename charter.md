# Charter — Scheme worksheets in chezmacs

**Status.** Handoff from the high-level discussion in Grok (journal
`2026-09-21-chezmacs-mpl`) into a **design conversation**. Not
chezmacs upstream. Not a checkpoint. Not an implementer assignment.
Specification will live beside this file as [`spec.md`](spec.md).
Parent map: [`README.md`](README.md).

The editor's checkout and command are still `e`
(`/home/dharmatech/src/e`). This project calls the editor
**chezmacs**. Paths, `config.e`, and the `.e` config extension keep
their on-disk names.

This charter **replaces** the earlier MPL-only assignment. Git
`5150522` kept that round (`spec.md` with mode `"mpl"`, ending
`.mpl`, default `(mpl all)`, auto-`vars`) for reference. The
designer **rewrites** `spec.md` in full against this file. Do not
patch the stale spec as a delta. Do not keep `(mpl-env)`,
`(mpl-mode)`, mode `"mpl"`, MPL default imports, or auto-`vars`.

**Your job.** Turn this charter into a specification for a
**personal chezmacs extension**: a worksheet file is a Scheme
program with its own mutable top level, built from its leading
`(import …)` forms. `C-x C-e` in that buffer uses that environment.
`M-x` keeps Chez `+` and the editor API. MPL is the first sample
library, not the mode. Then **stop**. Do not write checkpoints. Do
not implement. Do not specify inserting results into the buffer, a
CAS UI, or changes to chezmacs's kernel.

If you have been told to read this file, this is the whole assignment.

---

## 1. How this conversation works

1. Read this charter, [`README.md`](README.md), and the authority in
   §5. Inspect those trees. Do not rely on the Grok transcript; this
   file is the assignment. Treat the committed `spec.md` as
   historical, not law.
2. Record the locked decisions in §4. Resolve the open questions in
   §4.8–§4.11.
3. Write `spec.md` in this folder (overwrite). A later
   checkpoint-manager conversation slices **chezmacs-mpl 000**,
   `001`, … under `checkpoints/` in this same directory. The project
   identity stays `chezmacs-mpl` because MPL is still the first
   customer; the **mode** is not MPL.
4. Stop. The human reviews it. Do not write those checkpoint files.

The checkpoint manager and implementers will not have this charter.
Put every rule they need in the specification.

Keep the spec **small enough to slice**. A full CAS IDE, result
insertion into the buffer, hot-reload of libraries under `~/src`, a
describe corpus, stealing scheme-mode's endings, and a patch series
against chezmacs's daemon are defects in this document.

## 2. Predecessors (do not start without these)

| What | Ready when |
|---|---|
| chezmacs | `/home/dharmatech/src/e` builds and runs (Chez 10.4.1 is installed as `scheme` / `scheme-script`) |
| MPL (sample) | `/home/dharmatech/src/mpl` with `surfage` and `dharmalab` beside it under `/home/dharmatech/src` |
| Proven Chez construction | §4.3. A designer who re-derives a different environment story is wrong |

No chezmacs source change is a predecessor. The extension must load
as third-party code. If a later seam in `eval.sls` would be nicer,
name it as a **follow-on**, not as this spec's required patch.

## 3. Bar (acceptance)

The specification is wrong unless all of these are true:

1. **The file's imports are the namespace.** A worksheet that begins
   with `(import (mpl rnrs-sans) (mpl all))`, then `(vars x y z)`,
   then `(+ x x)` evaluates `(+ x x)` to `(* 2 x)`. The user does
   not write `mpl:+` or `all:+`. The same mode, with a different
   `import`, is a different library.
2. **The editor is unharmed.** After the extension is loaded,
   `M-x (+ 1 2)` is still Chez arithmetic (`3`). Editor commands
   (`head:`, `eval:`, …) keep their current meaning. Worksheet
   libraries are not imported into `(interaction-environment)`.
3. **The environment is the file's.** `C-x C-e` in a worksheet
   buffer evaluates in that buffer's mutable Chez environment, not
   in the editor top level. A second worksheet does not share
   definitions with the first unless the spec names a deliberate
   sharing rule (the expected rule is: no sharing).
4. **It is a Chez program, not an R6RS library.** The worksheet
   looks like a top-level script: optional leading `(import …)`,
   then definitions and expressions. `(library (foo) …)` is not
   the worksheet shape. `(import (chezscheme))` is allowed; the
   implementation is Chez. "R6RS" names the file shape, not a
   ban on Chez libraries.
5. **No MPL unless the file asked.** A worksheet with no `import`
   uses default `(rnrs)`. In that environment `(+ 1 2)` is `3`,
   `x` is unbound, and `vars` / `alge` are not defined. Auto-`vars`
   must not run.
6. **First consumer is tests plus one MPL sample file.** There is a
   Chez-script test (no TTY, no running chezmacs) that builds
   private environments and checks at least:
   - default `(rnrs)`: `(+ 1 2)` → `3`; `x` unbound
   - MPL imports plus `(vars …)` then the goldens in §7
   - `(+ 1 2)` in `(interaction-environment)` is still `3` after
     those private envs exist
   And there is a sample worksheet in this journal directory a
   human can open in chezmacs, containing the MPL `import`,
   `(vars …)`, and `(+ x x)` (not an empty file that magically
   knows MPL).
7. **The chezmacs piece is a mode-shaped extension**, loaded with
   `kernel:load-module!` of **the extension** (`"worksheet-mode"`),
   not of MPL. It binds worksheet `C-x C-e` in that mode's keymap
   context so the global editor binding is left alone in ordinary
   Scheme buffers (including chezmacs's own `.sls` sources).
8. Anything the spec needs from chezmacs (`eval` logging, `C-g`,
   echo area) is either reused without patching chezmacs, or
   duplicated in the extension, or named as an optional later seam.
   This spec must ship without editing
   `/home/dharmatech/src/e/lib/**` unless the human later promotes
   a seam. Default: **do not edit the chezmacs tree**.

## 4. Locked decisions (record these; do not reopen 4.1–4.7)

### 4.1 The problem is one interaction environment

chezmacs evaluates `M-x` and `C-x C-e` in
`(interaction-environment)`. That is correct for editor commands
and for editing chezmacs itself. It is wrong for a self-contained
program whose `import` is its namespace.

Importing `(mpl all)` — or any other library that rebinds `+` —
into the editor top level would change `M-x`. Do not do that.

`kernel:load-module!` is the wrong loader for MPL or any such
library: it prefixes by file stem (`all:+`) and expects `init!`.
Those collections are third-party R6RS libraries, not chezmacs
modules. The only `kernel:load-module!` in this project is the
worksheet extension.

### 4.2 Per-buffer environment; worksheet mode for keys

Each worksheet buffer owns a mutable Chez environment.

`M-x` always uses the editor interaction environment.

`C-x C-e` in a worksheet buffer uses that buffer's environment.
In a scheme-mode buffer it keeps today's meaning (editor top
level).

The mode is **`"worksheet"`**. Keymap context is therefore
`'worksheet`. This is not scheme-mode and not an MPL mode.
scheme-mode remains for chezmacs sources (`.sls`, `.ss`,
`config.e`, …). A worksheet is a different **evaluation rule**,
not a different syntax.

Highlighting, indent, and format should be Scheme's; do not invent
a new syntax highlighter. Reuse scheme-mode's styler, indenter,
and formatter if they are reachable from the registry; if they are
not, say how the worksheet still looks like Scheme without copying
`scheme-mode.sls`.

Do not steal scheme-mode's endings (`.scm` `.ss` `.sls` `.sps`
`.sc` `.e`). Use a distinct ending (see §4.8).

### 4.3 How the environment is built (proven)

Chez will not `eval` an `(import …)` form into a copied
environment. `import` is syntax only at a program, library, or
the interaction environment. A designer who specifies "eval the
import form in the buffer env" is wrong.

The construction is:

```scheme
(library-directories
  (cons (cons "/home/dharmatech/src"
              "<object-cache>")
        (library-directories)))

(define env
  (copy-environment
    (apply environment import-specs)
    #t))
```

`import-specs` comes from the file's leading `import` forms, or
from the default `'((rnrs))` when there is no header.

MPL goldens use an explicit spec and an explicit `vars` form
**evaluated as worksheet code**, not as environment construction:

```scheme
(define mpl-env
  (copy-environment
    (apply environment '((mpl rnrs-sans) (mpl all)))
    #t))
(eval '(vars a b c d x y z pi t) mpl-env)
(eval '(+ x x) mpl-env)   ; => (* 2 x)
```

`(mpl-env)` / auto-`vars` / default MPL imports are forbidden.

`(copy-environment … #t)` is mutable: `define` and any macros the
imported libraries export (including MPL `vars` when imported)
persist until the environment is discarded.

The worksheet library itself must not `(import (mpl all))` at
library level, so loading the extension does not rebind `+` in
tests or in chezmacs's interaction environment.

Object files may go in chezmacs's `eo/client` or in a cache under
this journal directory. Pick one in the spec and keep compilation
out of `~/src` itself. (The journal `eo/` directory from the
first spec round may be reused.)

`library-directories` must include `/home/dharmatech/src` so
`(mpl all)` maps to `~/src/mpl/all.sls`, `(surfage …)` to
`~/src/surfage/…`, `(dharmalab …)` to `~/src/dharmalab/…`, and any
other collection dropped in `~/src` the same way. Adding
`~/src/mpl` as a root is wrong (`mpl/mpl/all.sls`). This path is
"where this machine keeps R6RS libraries," not an MPL special
case.

Import-spec modifiers `only` / `except` / `prefix` / `rename` are
allowed because Chez `environment` accepts them.

Chez `(environment spec …)` **silently merges** overlapping names.
A worksheet must not. Conflicting **variable** exports must raise
at construction, not hand the user MPL `+` under an `(rnrs)`
header. That is why MPL ships `(mpl rnrs-sans)`.

The check is this algorithm, not a hard-coded list of `+` `-` `*`
`/` `sqrt`, and not "whatever Chez `environment` already does":

1. For each import spec, realize `(environment spec)` (that is
   where `only` / `except` / `prefix` / `rename` apply). Invalid
   specs fail with whatever Chez raises there.
2. The set of names to consider is the union of Chez
   `environment-symbols` of those per-spec environments. Do not
   invent another enumeration; the set of identifiers is otherwise
   infinite.
3. A name **clashes** when it is a **variable** in more than one
   of those environments — `eval` of the name succeeds in each —
   and the values are not `eq?`. Then construction raises.
4. A single spec never clashes with itself. Two specs that
   re-export the same object (`eq?`) are not a conflict (for
   example `(rnrs)` listed twice). Syntax-only overlaps, where
   `eval` of the name raises, are not extra errors. A name that is
   both syntax and a variable (Chez `+` is) is a variable for this
   rule.

Do **not** weaken this rule so that `(rnrs)` together with
`(chezscheme)` succeeds. On this Chez those libraries have
dozens of shared names that are not `eq?`, and a library-level
`(import (rnrs) (chezscheme))` already raises. A Chez worksheet
is `(import (chezscheme))` **alone**. `(import (rnrs))` alone is
the default. Both together is a construction error. The spec
must say so and test it. A single `(import (chezscheme))` must
succeed (charter-allowed; no self-clash).

Required clash outcomes (live trees on this host):

| Import specs | Construction |
|---|---|
| `((rnrs) (mpl all))` | raise (`+` `-` `*` `/` `sqrt` at least) |
| `((mpl rnrs-sans) (mpl all))` | succeed |
| `((rnrs) (rnrs))` | succeed |
| `((rnrs) (prefix (mpl all) mpl:))` | succeed |
| `((chezscheme))` | succeed |
| `((rnrs) (chezscheme))` | raise |

`(+ 1 2)` is not a clash test: MPL `+` on numbers is still `3`.

### 4.4 Leading import forms are environment spec, not eval

A worksheet may begin with

```scheme
(import (mpl rnrs-sans)
        (mpl all))

(vars x y)

(+ x x)
```

or, with no header, just Scheme:

```scheme
(+ 1 2)
```

The spec must treat **leading** `import` forms as the list of
import-specs passed to `environment`, then evaluate the remaining
top-level forms in the mutable copy.

- Zero leading `import` forms: use `'((rnrs))`.
- One or more leading `import` forms: use those specs **instead
  of** the default, not in addition to it.
- An `import` that is not a leading prefix is not environment
  spec; evaluating it is an error.

Evaluating a region that is only `(+ x x)` still uses the buffer
environment, which was built from the **file** header (or from
`(rnrs)` if there is no header), not from the region.

`define` persists in that copy for the life of the buffer
environment. Recreating the environment drops definitions. Name
when recreation happens (import-header change is the expected
trigger; killing the buffer is another).

**No auto-`vars`.** If the file needs MPL free variables, it
writes `(vars x y z)` itself. Construction must succeed for
`((rnrs))` without `vars` existing. Do not install an
unbound-identifier handler that self-quotes unknown symbols.

### 4.5 Runtime handles stay off the store

Do not store a Chez environment object in buffer facts that the
base might serialize. Keep environments in head-local memory
keyed by buffer (a weak table is the expected shape). Facts may
record serializable hints (mode name, chosen import list as
datums) if useful; the live env is not a fact.

### 4.6 Where code lives

All new code for this experiment lives under

`/home/dharmatech/journal/2026-09-21-chezmacs-mpl/`

Locked library names (one-component, files under `lib/`):

| Library | File | Role |
|---|---|---|
| `(worksheet-env)` | `lib/worksheet-env.sls` | Env algebra. No `init!`. Imports `(chezscheme)` only. No chezmacs libraries. |
| `(worksheet-mode)` | `lib/worksheet-mode.sls` | chezmacs module. Exports `init!`. Loaded as `"worksheet-mode"`. |

Do **not** use `(mpl-env)`, `(mpl-mode)`, `(mpl env)`, or
`(mpl mode)`: the last two would resolve under `~/src/mpl/`.

Suggested layout the spec may refine:

```text
charter.md                 this file
spec.md                    designer output (rewrite)
checkpoints/               later
README.md                  map
lib/worksheet-env.sls
lib/worksheet-mode.sls
tests/                     Chez-script tests
examples/                  sample worksheet(s)
eo/                        object cache (generated)
```

`(worksheet-mode)` is loaded from the user's `config.e` via
`kernel:load-module!` after this journal `lib/` is on
`library-directories`. The spec must give the exact `config.e`
snippet, including adding `~/src` so third-party collections
resolve.

Do not copy MPL, Surfage, or Dharmalab into this tree or into the
chezmacs tree.

Do not add the extension to chezmacs's bundled
`kernel:load-modules!` list in `main.sls`.

Use `(library …)`, not chezmacs `elibrary`. This tree is not
under chezmacs's elinter.

### 4.7 Out of this layer

- Inserting `; => (* 2 x)` or a result line under point
  (worksheet UI). Same environment; later project.
- Rebinding `M-x` in worksheet buffers
- Prefixing identifiers (`mpl:+`)
- Importing worksheet libraries into `(interaction-environment)`
- `kernel:load-module!` of `"all"` or any MPL / third-party stem
- Mode name `"mpl"`, default import of MPL, auto-`vars`
- Editing the chezmacs tree under `/home/dharmatech/src/e`
  (default)
- Fingerprint / daemon / wire changes
- Hot-reload of `~/src/mpl` (or other `~/src` libraries) when
  those files are saved
- A describe/edoc corpus for MPL or other libraries
- Infix input except what a library already provides (MPL
  `(alge "…")` in the sample)
- Sharing one env across heads or across buffers
- Hijacking scheme-mode or `.sls` evaluation

### 4.8 File ending (resolve this)

Mode name is locked (`"worksheet"`). Pick a distinct file ending
that will not steal scheme-mode's `.scm` / `.ss` / `.sls` / `.sps`
/ `.sc` / `.e`.

Candidates: `.ws`, `.r6rs`. Optionally also register `.mpl` as an
**additional** ending of the same worksheet mode. `.mpl` must not
imply MPL default imports or auto-`vars`; those files still need
`(import (mpl …))` in the text.

Detection is by ending. `(mode:choose! buffer "worksheet")` already
works if the spec does not wrap it.

Do not take `.sps` even though it means "R6RS program" in some
trees: scheme-mode already claims it.

### 4.9 How `C-x C-e` reports (resolve this)

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

### 4.10 Tests and verification (resolve this)

Name:

- the Chez-script test file(s) and how they are run
  (`scheme --script …` or `uv` is wrong; this is Scheme)
- the sample worksheet path (and ending, matching §4.8)
- any hand check in chezmacs (open the MPL sample, `C-x C-e`,
  echo shows `(* 2 x)`; `M-x (+ 1 2)` shows `3`)

The environment layer must be testable without launching
chezmacs. Include:

- the default-`(rnrs)` case and the MPL goldens in §7
- every row of the clash table in §4.3
- two leading `import` forms concatenated, e.g. `(import (mpl
  rnrs-sans))` then `(import (mpl all))`, then MPL code
- a non-leading `(import …)` (a `define` or expression, then
  `import`) as an error from `eval-program`
- a hand check that definitions in a worksheet disappear after
  the import header changes (charter §4.4 recreation). A
  Chez-script cannot see the weak table; one named hand-check
  bullet is enough, plus buffer kill

The mode/key binding may be a named hand check if an automated
chezmacs test would require the interactive harness; do not block
the spec on writing a new chezmacs TTY test suite.

### 4.11 Extension surface (resolve this)

Specify `(worksheet-env)` and `(worksheet-mode)` exports and
`init!` registrations (mode, keymap, any `doc:register!`).

Keep exactly two layers the checkpoint manager can slice:

1. **`(worksheet-env)`** — `library-directories`, `environment` /
   `copy-environment`, parse leading imports, eval remaining
   forms. No auto-`vars`. Chez tests only.
2. **`(worksheet-mode)`** — mode `"worksheet"`, `C-x C-e`,
   config snippet, sample file. Depends on 1.

If you need more than those two layers, say why. Do not add a
third layer for "future worksheet insert."

## 5. Authority

Inspect these; they are law for chezmacs's seams and, for the
sample, MPL's API. This charter wins if they conflict with "make
it feel more complete" or with the stale `spec.md`.

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
  `misc.sls` (`vars`), `test.sls` (examples) — **sample
  library**, not the mode
- Chez User's Guide: `environment`, `copy-environment`, `eval`,
  `library-directories`, `import` (program / library / REPL only)

The chezmacs tree's `AGENTS.md` applies only if someone later
commits into that tree. This experiment does not.

## 6. Non-goals

- Worksheet "eval and insert result below point"
- A Maxima/Mathematica notebook UI
- An MPL-specific mode
- Changing MPL, Surfage, or Dharmalab
- Making MPL a bundled chezmacs module
- Using MPL's `+` for chezmacs's own arithmetic
- Evaluating inside `(library …)` forms as if they were a REPL
- Multi-head shared REPL state
- Windows / non-Chez Scheme

## 7. Goldens the spec must keep

These were run against `/home/dharmatech/src/mpl` with an
environment built from `'((mpl rnrs-sans) (mpl all))` and
`(vars a b c d x y z pi t)` evaluated **in that environment**.
Layer 1 tests must include them as `equal?` checks after that
setup, not as the mode default, and not as weaker substitutes.

```text
(+ x x)                                              => (* 2 x)
(* x y x)                                            => (* (^ x 2) y)
(+ x y x z 5 z)                                      => (+ 5 (* 2 x) y (* 2 z))
(algebraic-expand (alge "(x+1)^2"))                  => (+ 1 (* 2 x) (^ x 2))
(algebraic-expand (alge "(x+2)*(x+3)*(x+4)"))        => (+ 24 (* 26 x) (* 9 (^ x 2)) (^ x 3))
(derivative (alge "sin(x)") x)                       => (cos x)
(derivative (alge "x^3 + 3*x^2 + 5") x)              => (+ (* 6 x) (* 3 (^ x 2)))
(+ 1 2) in a default (rnrs) worksheet env            => 3
(+ 1 2) in the editor interaction environment        => 3
```

`alge` takes an infix string and is part of `(mpl all)`. Symbolic
`sin` / `cos` need not be bound as procedures in the worksheet;
`(alge "sin(x)")` builds the expression `derivative` understands.
They are unavailable until the file imports MPL.
