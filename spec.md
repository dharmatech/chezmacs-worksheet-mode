# Specification — Scheme worksheets in chezmacs

**Status.** Design for the local **chezmacs-mpl** project. This is not
chezmacs upstream, a checkpoint, or an implementer assignment. A later
checkpoint-manager conversation slices **chezmacs-mpl 000**, `001`, …
under [`checkpoints/`](checkpoints/). The checkpoint manager will not
have [`charter.md`](charter.md); this file is the law.

This file **replaces** the MPL-only specification kept at git
`5150522`. Do not implement that round: no `(mpl-env)`, no
`(mpl-mode)`, no mode `"mpl"`, no default `(mpl all)`, no auto-`vars`.

The editor's checkout and command remain `e`
(`/home/dharmatech/src/e`). Prose in this project calls the editor
**chezmacs**. Paths, `config.e`, and the `.e` config extension keep
their on-disk names. The project identity stays `chezmacs-mpl` because
MPL is the first sample library. The **mode** is not MPL.

This specification is a **personal chezmacs extension**: a worksheet
file is a Scheme program whose leading `(import …)` forms are its
namespace. `C-x C-e` in that buffer uses a private mutable Chez top
level built from those forms. `M-x` keeps Chez `+` and the editor API.
It ships without editing `/home/dharmatech/src/e/lib/**`.

## 1. Resolved choices

These close the charter's open questions. Do not reopen them.

| Question | Choice |
|---|---|
| File ending | `".ws"` is the canonical ending. Also register `".mpl"` as a second ending of the **same** mode. Neither ending implies MPL imports or `vars`. Not `.r6rs` (Chez libraries such as `(chezscheme)` are allowed; that suffix overclaims). Not `.sps` / `.scm` / `.ss` / `.sls` / `.sc` / `.e` (scheme-mode already claims them). |
| Mode name | Locked by the charter: `"worksheet"`. Keymap context is therefore `'worksheet`. `(mode:choose! buffer "worksheet")` already works; this project does not wrap it. |
| `C-x C-e` reporting | Duplicate a small evaluate-and-echo path in the extension. Do not call `eval:run!`. Do not patch `eval.sls`. Reuse the public APIs in §8. |
| Tests | Chez-script `tests/worksheet-env.ss` (`scheme --script`, no `uv`, no TTY, no running chezmacs) for the environment layer. Sample `examples/mpl.ws`. Mode/key binding is a named hand check. |
| Libraries | Two layers only: `(worksheet-env)` then `(worksheet-mode)`. No third layer. |

Names `(worksheet-env)` and `(worksheet-mode)` are one-component
library names mapping to `lib/worksheet-env.sls` and
`lib/worksheet-mode.sls`. Do **not** use `(mpl-env)`, `(mpl-mode)`,
`(mpl env)`, or `(mpl mode)`: the last two would resolve under
`/home/dharmatech/src/mpl/`.

## 2. Bar (acceptance)

The implementation is wrong unless all of these are true:

1. **The file's imports are the namespace.** A worksheet that begins
   with `(import (mpl rnrs-sans) (mpl all))`, then `(vars x y z)`,
   then `(+ x x)` evaluates `(+ x x)` to `(* 2 x)`. The user does not
   write `mpl:+` or `all:+`. The same mode, with a different `import`,
   is a different library.
2. **The editor is unharmed.** After the extension is loaded,
   `M-x (+ 1 2)` is still Chez arithmetic (`3`). Editor commands
   (`head:`, `eval:`, …) keep their current meaning. Worksheet
   libraries are not imported into `(interaction-environment)`.
3. **The environment is the file's.** `C-x C-e` in a worksheet buffer
   evaluates in that buffer's mutable Chez environment, not in the
   editor top level. Two worksheet buffers do not share definitions.
   Two heads do not share a Chez environment (each head is its own
   process; environments are head-local).
4. **It is a Chez program, not an R6RS library.** The worksheet is a
   top-level script: optional leading `(import …)`, then definitions
   and expressions. A top-level `(library (foo) …)` is not special-cased
   and is not the worksheet shape. `(import (chezscheme))` is allowed;
   the implementation is Chez. "R6RS" names the file shape, not a ban
   on Chez libraries.
5. **No MPL unless the file asked.** A worksheet with no `import` uses
   default `(rnrs)`. In that environment `(+ 1 2)` is `3`, `x` is
   unbound, and `vars` / `alge` are not defined. Auto-`vars` must not
   run. Do not install an unbound-identifier handler that self-quotes
   unknown symbols.
6. **First consumer is tests plus one MPL sample file**, as named in
   §10. The sample contains the MPL `import`, a `(vars …)` form, and
   `(+ x x)`. It is not an empty file that magically knows MPL.
7. **The chezmacs piece is a mode-shaped extension**, loaded with
   `kernel:load-module!` of **`"worksheet-mode"`**, not of MPL. It
   binds worksheet `C-x C-e` in context `'worksheet` so the global
   editor binding is left alone in ordinary Scheme buffers (including
   chezmacs's own `.sls` sources).
8. **No chezmacs tree edit.** Anything this spec needs from chezmacs
   is reused without patching, duplicated in the extension, or named
   as an optional later seam. Default: do not edit
   `/home/dharmatech/src/e`.

## 3. Project boundary

All new source lives under
`/home/dharmatech/journal/2026-09-21-chezmacs-mpl/`:

```text
charter.md                 already written
spec.md                    this file
checkpoints/               later, not this specification
README.md                  map (not amended by this spec)
lib/worksheet-env.sls      layer 1: environment algebra
lib/worksheet-mode.sls     layer 2: chezmacs module
tests/worksheet-env.ss     Chez-script tests for layer 1
examples/mpl.ws            sample MPL worksheet
eo/                        generated Chez object cache (not source)
```

Do not copy MPL, Surfage, or Dharmalab into this tree or into
chezmacs. Do not add `"worksheet-mode"` to chezmacs's bundled
`kernel:load-modules!` list in `main.sls`. Do not vendor this
extension under `/home/dharmatech/src/e/lib/`.

`(worksheet-env)` is an ordinary R6RS library. It does not export
`init!` and must not import any chezmacs library. `(worksheet-mode)`
is a chezmacs module: it exports `init!` and `run!`, is loaded from
`config.e` via `kernel:load-module!`, and imports `(worksheet-env)`
plus the prefixed chezmacs seams in §7.

Use `(library …)`, not chezmacs `elibrary`. This tree is not under
chezmacs's elinter.

## 4. Paths and compilation

Hard-code these paths (this is a personal experiment on this host):

| Role | Path |
|---|---|
| Journal root | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl` |
| Extension library root | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl/lib` |
| Object cache | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo` |
| Third-party R6RS root | `/home/dharmatech/src` |

`(library-directories)` must include `/home/dharmatech/src` so
`(mpl all)` maps to `/home/dharmatech/src/mpl/all.sls`, `(surfage …)`
to `/home/dharmatech/src/surfage/…`, `(dharmalab …)` to
`/home/dharmatech/src/dharmalab/…`, and any other collection dropped
in `/home/dharmatech/src` the same way. Adding
`/home/dharmatech/src/mpl` as a root is wrong (`mpl/mpl/all.sls`).
This path is where this machine keeps R6RS libraries, not an MPL
special case.

Object files go in the journal `eo/` cache, including compiled MPL.
The `eo/` directory left from the first spec round may be reused.
Do not compile into `/home/dharmatech/src`. Do not require chezmacs's
`eo/client` (libraries may already have been compiled there; this
project must still run its Chez-script tests without that cache).

`prepare-library-directories!` (layer 1) is idempotent:

1. `(compile-imported-libraries #t)`
2. Create `eo/` if it does not exist.
3. If `/home/dharmatech/src` is not already a `library-directories`
   source, prepend `(cons src eo)`.
4. If the journal `lib/` is not already a source, prepend
   `(cons lib eo)` so it is searched first.

Prepending `lib/` last makes it the first root, so
`kernel:load-module!` finds `worksheet-mode.sls` here. `assoc` on the
source path is enough to decide whether a root is already present.

## 5. Layer 1 — `(worksheet-env)`

**File.** `lib/worksheet-env.sls`  
**Library name.** `(worksheet-env)`  
**Imports.** `(chezscheme)` only.

This layer is testable with `scheme --script` and no chezmacs.

### 5.1 Proven environment construction

Chez will not `eval` an `(import …)` form into a copied environment.
`import` is syntax only at a program, library, or the interaction
environment. Building a worksheet environment by evaluating `import`
in that environment is wrong.

The construction is:

```scheme
(prepare-library-directories!)

(assert-no-variable-clashes! import-specs)   ; §5.2; not an export

(define env
  (copy-environment
    (apply environment import-specs)
    #t))
```

`import-specs` is a list of Chez import-spec datums. The default,
when the file has no leading `import`, is `'((rnrs))`.

`(copy-environment … #t)` is mutable: `define` and any macros the
imported libraries export (including MPL `vars` when imported)
persist in that copy until it is discarded.

`(eval '(import …) env)` must not be how the environment is built. A
test may show that evaluating an `import` form in the copy raises.

`(worksheet-env)` itself must not `(import (mpl all))` or any other
third-party collection at library level, so loading this library
does not rebind `+` in the test script or in chezmacs's interaction
environment.

There is **no auto-`vars`**. Construction must succeed for
`((rnrs))` without `vars` existing. If a file needs MPL free
variables, it writes `(vars …)` itself as worksheet code.

### 5.2 Conflicting exports

Chez `(environment spec …)` silently merges overlapping names.
A worksheet must not. Conflicting **variable** exports must raise
at construction, not hand the user MPL `+` under an `(rnrs)`
header. That is why MPL ships `(mpl rnrs-sans)`.

`make-worksheet-environment` runs this algorithm **before**
`(apply environment import-specs)`. It is not a hard-coded list of
`+` `-` `*` `/` `sqrt`, and it is not "whatever Chez `environment`
already does":

1. For each import spec, realize `(environment spec)` (that is
   where `only` / `except` / `prefix` / `rename` apply). Invalid
   specs fail with whatever Chez raises there.
2. The set of names to consider is the union of Chez
   `environment-symbols` of those per-spec environments. Do not
   invent another enumeration; the set of identifiers is otherwise
   infinite. `(worksheet-env)` already imports `(chezscheme)`, so
   `environment-symbols` is in scope.
3. A name **clashes** when `eval` of it succeeds in more than one
   of those environments and the values are not `eq?`. Then
   construction raises.
4. A single spec never clashes with itself. Two specs that
   re-export the same object (`eq?`) are not a conflict (for
   example `(rnrs)` listed twice). Syntax-only overlaps, where
   `eval` of the name raises, are not extra errors. A name that is
   both syntax and a variable (Chez `+` is) is a variable for this
   rule.

Do **not** weaken this rule so that `(rnrs)` together with
`(chezscheme)` succeeds. On this Chez those libraries have dozens
of shared names that are not `eq?`, and a library-level
`(import (rnrs) (chezscheme))` already raises. A Chez worksheet is
`(import (chezscheme))` **alone**. `(import (rnrs))` alone is the
default. Both together is a construction error. A single
`(import (chezscheme))` succeeds (no self-clash).

Required outcomes:

| Import specs | Construction |
|---|---|
| `((rnrs) (mpl all))` | raise (`+` `-` `*` `/` `sqrt` at least) |
| `((mpl rnrs-sans) (mpl all))` | succeed |
| `((rnrs) (rnrs))` | succeed |
| `((rnrs) (prefix (mpl all) mpl:))` | succeed |
| `((chezscheme))` | succeed |
| `((rnrs) (chezscheme))` | raise |

`(+ 1 2)` is not a clash test: MPL `+` on numbers is still `3`.

An empty spec list (`(import)` with no operands) is not a clash:
`(apply environment '())` is the empty environment. Construction
succeeds; almost every evaluation in that environment then fails.

### 5.3 Leading `import` is environment spec, not eval

A worksheet may begin with one or more `import` forms:

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

`parse-worksheet` reads datums from the start of a string with Chez
`read` (whitespace and comments skipped; Chez `#!r6rs` / shebang
directives follow Chez). Consecutive **leading** datums that are
pairs whose `car` is the symbol `import` are the environment spec:
the concatenation of each form's operands (the `cdr`) is the
import-spec list passed to `environment`. Those forms are not
evaluated.

- Zero leading `import` forms: use `default-import-specs`
  (`'((rnrs))`).
- One or more leading `import` forms: use those specs **instead of**
  the default, not in addition to it. `(import)` with no operands is
  an empty spec list (§5.2).
- An `import` that is not a leading prefix (a form after a
  definition or expression) is not environment spec. Evaluating it
  is an error.

`only` / `prefix` / `rename` / `except` import-specs are allowed
because `environment` accepts them. This project does not invent a
restricted import language.

Evaluating a region that is only `(+ x x)` still uses the buffer
environment, which was built from the **file** header (or from
`(rnrs)` if there is no header), not from the region.

### 5.4 Evaluating forms

`read-forms` reads every datum from a string until eof.

`eval-forms` evaluates those datums in order in the given environment
with Chez `eval`. It does **not** strip `import`. The values of the
last datum are the result. An empty list of forms returns zero
values. Definitions and effects from earlier datums remain in the
environment.

`eval-program` parses a whole-buffer string, drops leading `import`
forms, and `eval-forms` the rest in the given environment. It does
not rebuild the environment; the caller passes the environment that
already matches the header.

### 5.5 Normative exports

`(worksheet-env)` exports exactly:

| Export | Meaning |
|---|---|
| `src-root` | `"/home/dharmatech/src"` |
| `object-directory` | the journal `eo/` path in §4 |
| `prepare-library-directories!` | §4, idempotent |
| `default-import-specs` | `'((rnrs))` |
| `read-forms` | `string → list` of datums |
| `parse-worksheet` | `string → (values import-specs remaining-forms)` |
| `make-worksheet-environment` | `import-specs →` mutable env; clash check; no `vars` |
| `eval-forms` | `forms env →` values of the last form |
| `eval-program` | `string env →` values of the last remaining form |

`parse-worksheet` applies the default import-spec rule in §5.3.
`remaining-forms` is the list after stripping leading `import`
datums (possibly empty).

Do not export a chezmacs buffer object, a weak table, a clash-check
helper, or anything that imports chezmacs.

## 6. Goldens

These were checked against `/home/dharmatech/src/mpl` with an
environment built from `'((mpl rnrs-sans) (mpl all))` and
`(vars a b c d x y z pi t)` evaluated **in that environment**, not
as mode default. Layer 1 tests must include them as `equal?`
checks after that setup, not weaker substitutes.

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

## 7. Layer 2 — `(worksheet-mode)`

**File.** `lib/worksheet-mode.sls`  
**Library name.** `(worksheet-mode)`  
**Exports.** `init!` and `run!`  
**Loaded as.** `(kernel:load-module! "worksheet-mode")`

After the kernel prefixes the library, the command is
`worksheet-mode:run!` at M-x. `init!` is invoked by the kernel
through `(import (only (worksheet-mode) init!))` and is not used as
a user command.

Imports, besides `(chezscheme)` and `(worksheet-env)`:

```scheme
(prefix (core kernel) kernel:)
(prefix (head edit) edit:)
(prefix (head echo) echo:)
(prefix (head head) head:)
(prefix (head keymap) keymap:)
(prefix (head mode) mode:)
(prefix (apps eval) eval:)
(prefix (service doc) doc:)
(prefix (service log) log:)
(prefix (sys sys) sys:)
```

`(apps eval)` is imported only for `eval:copy-result`. Do not call
`eval:run!`.

### 7.1 `init!` registrations

`init!` must:

1. Call `prepare-library-directories!` (config.e already added
   `lib/` so the module could load; this call still ensures `~/src`
   and `eo/`).
2. Register mode `"worksheet"` with endings `'(".ws" ".mpl")` and no
   `#!` interpreters. Do not steal scheme-mode's endings. `.mpl` is
   the same mode as `.ws`: opening `foo.mpl` does not import MPL.
3. Reuse scheme-mode's presentation without copying
   `scheme-mode.sls`. After bundled modules have loaded, scheme-mode
   is in the registry:

   ```scheme
   (let ([scheme (mode:find "scheme")])
     (mode:register! "worksheet" '(".ws" ".mpl") '()
                     (and scheme (mode:styles scheme))
                     (and scheme (mode:render scheme))
                     (and scheme (mode:row-styles scheme)))
     (let ([indent (mode:indenter "scheme")]
           [format (mode:formatter "scheme")])
       (when indent (mode:register-indenter! "worksheet" indent))
       (when format (mode:register-formatter! "worksheet" format))))
   ```

   TAB indent and `edit:format-buffer!` then work as in Scheme.
   scheme-mode's format-on-save hook only formats buffers whose mode
   name is `"scheme"`; do not add a worksheet format-on-save hook.
4. `(keymap:bind-default! 'worksheet "C-x C-e" run!)`. Not
   `keymap:bind!`. Not a global `C-x C-e`. `M-x` stays
   `eval:prompt!`.
5. `doc:register!` a short describe entry for
   `worksheet-mode:run!`.

chezmacs already resolves keys in `mode:key-context` before the
global map (`lib/head/dispatch.sls`). While a `"worksheet"` buffer
is current, context `'worksheet` owns `C-x C-e`. Ordinary Scheme
buffers keep `eval:run!`.

### 7.2 Per-buffer environment, off the store

Each worksheet buffer owns a mutable Chez environment created by
`make-worksheet-environment`.

Do **not** store a Chez environment object in buffer facts. Facts may
be serialized; environment objects must not. Keep live environments
in head-local memory: a `weak-eq-hashtable` keyed by the buffer
object. Hold that table in a `kernel:persistent-cell` under the key
`'worksheet-mode-environments` (that call returns a box; the
hashtable is the box's contents) so reloading `worksheet-mode` does
not drop worksheet definitions. Values in the table are
`(cons import-specs env)` (or an equivalent pair of serializable
specs plus the live env). The specs are compared with `equal?`.

Recreation:

- First `run!` for a buffer creates the environment from the whole
  buffer's `parse-worksheet` import-specs (default `(rnrs)` if no
  header).
- If the whole-buffer leading import-spec list has changed since
  that environment was built, discard it and create a new one.
  Definitions from the old copy are gone.
- Killing the buffer drops the association because the key is weak.
  Reopening the file is a new buffer and a new environment.
- Reloading `worksheet-mode` keeps the persistent-cell table.
  Reloading does not, by itself, rebuild environments.

There is no sharing across buffers. There is no sharing across heads.

`M-x` always uses `(interaction-environment)`. Worksheet `C-x C-e`
never does.

### 7.3 What `run!` evaluates

Match chezmacs's current `C-x C-e` shape for the **span of text**:
the selected region while the mark is active (`head:mark` is true),
else the whole current buffer. That span is
`(edit:region-text (edit:current-region))` — when the mark is
inactive, `edit:current-region` is already the whole buffer.

Always parse **the whole buffer text** to obtain import-specs and to
ensure the buffer environment, even when the mark is active. The
whole-buffer string is `(edit:buffer-text (head:current-buffer))`,
not the selection.

Then:

- **Mark inactive (whole buffer).** `eval-program` on that text in
  the buffer environment. Leading `import` forms are environment
  spec, not expressions.
- **Mark active (region).** `eval-forms` of `read-forms` of the
  region text in the buffer environment. Do not treat a region's
  leading `import` as environment spec. A region that is only
  `(import …)` is an error.

A region that is only `(+ x x)` uses the environment already built
from the file header (or from `(rnrs)`).

`run!` acts on the current buffer. It does not need a mode-name
guard beyond the `'worksheet` key binding; calling
`worksheet-mode:run!` from M-x on a non-worksheet buffer is allowed
to treat that buffer as a worksheet (header, private env) and is
not a required test.

## 8. How `C-x C-e` reports

`eval:run!` logs, copies non-void results to the kill ring, captures
stdout/stderr, and is interruptible with `C-g`. Its helpers hardcode
`(interaction-environment)` and are not exported. This project
duplicates a small path with public APIs.

Required:

- Wrap evaluation in `head:call-with-interrupt`. On
  `head:interrupted?`, the echo text is `interrupted`.
- Wrap editor mutations from evaluated code in
  `edit:call-as-one-edit!` with label `"(worksheet-mode:run!)"`.
- Reader and evaluation failures become `error: ` plus
  `(kernel:condition-text ex)`. The editor process does not crash.
- The last value is shown in the echo area with Chez
  `(format "~s" value)`. Multiple values are joined with `", "`.
  Zero values, or a single `#<void>`, are void: show `#<void>` and
  do not copy to the kill ring.
- The echo must contain the printed value. A region eval of
  `(+ x x)` in the MPL sample shows `(* 2 x)` (the characters of
  that `~s` print). Do not require the `eval: … =>` log template.
- Use `edit:set-message!` for that echo text. Do **not**
  `log:add!` an `'eval` record: M-x history is derived from `'eval`.
  Worksheet runs must not pollute M-x history. Default
  `edit:set-message!` logs under `'e`; that is allowed. Echo-only
  (`(parameterize ([edit:message-source #f]) …)`) is also allowed.

Desirable and required because the APIs are public and cheap:

- If `(eval:copy-result)` is true and the result is non-void and not
  an error or interrupt, `edit:copy-to-kill-buffer!` the same printed
  string. Optional ghost ` [stored in kill ring]` via `echo:set-ghost!`
  is allowed, not required.
- Capture Scheme stdout/stderr the same way `eval.sls`'s
  `evaluation-outcome` does, not with `sys:call-with-streamed-output`
  alone:
  - `sys:duplicate-standard-output-port` before capture, closed
    afterward
  - `parameterize` `sys:terminal-output-port` to that port so
    `log:add!` still reaches the real terminal
  - `sys:call-with-streamed-output` posting complete lines with
    `log:add!` to `'stdout` / `'stderr` (a mutex around those
    `log:add!` calls, as in `eval.sls`)
  - Do not invent a new log component

**Follow-on (not this specification).** A one-function seam in
`/home/dharmatech/src/e/lib/apps/eval.sls` that evaluates a string in
a caller-supplied environment, with the existing interrupt, capture,
kill-ring, and echo behavior. This experiment must ship without that
patch. When such a seam exists, a later project may delete the
duplicate path. Do not wait for it.

## 9. `config.e` snippet

`config.e` is the installation's, next to chezmacs's loader, and is
evaluated in the interaction environment. It must tolerate being
loaded any number of times. `kernel:load-module!` is already
idempotent.

Exact snippet (comments allowed around it):

```scheme
;; worksheets — journal 2026-09-21-chezmacs-mpl
(let ([src "/home/dharmatech/src"]
      [lib "/home/dharmatech/journal/2026-09-21-chezmacs-mpl/lib"]
      [eo  "/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo"])
  (unless (file-directory? eo) (mkdir eo))
  (compile-imported-libraries #t)
  (unless (assoc src (library-directories))
    (library-directories (cons (cons src eo) (library-directories))))
  (unless (assoc lib (library-directories))
    (library-directories (cons (cons lib eo) (library-directories))))
  (kernel:load-module! "worksheet-mode"))
```

The `lib/` pair is consed after `src/` so `lib/` is searched first.
Do not `kernel:load-module!` `"all"`, `"worksheet-env"`, or any MPL
stem. Do not `(import (mpl all))` in `config.e`.

## 10. Tests and verification

### 10.1 Chez-script (required, no chezmacs)

**File.** `tests/worksheet-env.ss`  
**Run.** from the journal root:

```sh
scheme --script tests/worksheet-env.ss
```

`uv` is wrong; this is Scheme. Exit `0` on success, nonzero on
failure.

The script may only `(import (chezscheme))` at the file top (the
same constraint as chezmacs's loader: a top-level import of
`(worksheet-env)` would be resolved before `library-directories` is
set). It must create `eo/` if needed, set
`(compile-imported-libraries #t)`, and prepend `lib/` and `src/`
with object directory `eo/` **before** importing `(worksheet-env)` —
`prepare-library-directories!` also mkdir's, but it runs after that
import. Then `eval` `(import (worksheet-env))` into its interaction
environment, then call `prepare-library-directories!`.

It must **not** import `(mpl all)` into the interaction environment.

Required checks:

1. Default `(rnrs)` environment from `make-worksheet-environment` of
   `default-import-specs`: `(eval '(+ 1 2) env)` ⇒ `3`; `(eval 'x
   env)` raises; `(eval 'vars env)` raises; `(eval 'alge env)`
   raises.
2. All MPL goldens in §6 in an environment built from
   `'((mpl rnrs-sans) (mpl all))` after `(eval '(vars a b c d x y z
   pi t) env)` in that environment, including
   `(eval '(+ 1 2) (interaction-environment))` ⇒ `3` **after** those
   private environments exist.
3. `(eval '(+ x x) env)` ⇒ `(* 2 x)` with no `mpl:` prefix, only
   after that `vars` form. A fresh MPL environment without `vars`
   still has `x` unbound.
4. Two environments from `make-worksheet-environment` do not share
   definitions: `(eval '(define k 1) e1)` then `(eval 'k e2)` raises.
5. `parse-worksheet` on `"(+ 1 2)"` yields `default-import-specs`
   and remaining `((+ 1 2))`.
6. `parse-worksheet` on a leading
   `(import (mpl rnrs-sans) (mpl all))` yields those specs (not a
   concatenation with the default) and remaining forms without the
   `import`.
7. `eval-program` of a string that starts with that import, then
   `(vars x y)`, then `(+ x x)` ⇒ `(* 2 x)` (the import was not
   evaluated as an expression).
8. `define` persists: in a default `(rnrs)` env, evaluate
   `(define k 1)` then `k` ⇒ `1`.
9. `(eval '(import (rnrs)) env)` raises.
10. Clash table from §5.2, via `make-worksheet-environment` (not
    `(+ 1 2)` as a proxy, and not a hard-coded name list in the
    implementation):
    - `'((rnrs) (mpl all))` raises
    - `'((mpl rnrs-sans) (mpl all))` succeeds
    - `'((rnrs) (rnrs))` succeeds
    - `'((rnrs) (prefix (mpl all) mpl:))` succeeds
    - `'((chezscheme))` succeeds
    - `'((rnrs) (chezscheme))` raises
11. Two leading `import` forms concatenate: `parse-worksheet` of a
    string that begins with `(import (mpl rnrs-sans))` then
    `(import (mpl all))` yields those two specs (not a concatenation
    with the default) and remaining forms without either `import`.
    `eval-program` of that string plus `(vars x y)` then `(+ x x)`
    ⇒ `(* 2 x)`.
12. A non-leading `(import …)` is an error: `eval-program` of a
    string whose first datum is a `define` or other expression and
    whose later datum is `(import (rnrs))` raises (the `import` is
    not environment spec).

Do not launch chezmacs from this script. Do not require a TTY.

### 10.2 Sample worksheet

**File.** `examples/mpl.ws`

A Chez program a human can open in chezmacs. It **must** start with
the explicit MPL import (not omit it). It contains `(vars a b c d x
y z pi t)` as worksheet code, then the golden forms in §6 except the
two `(+ 1 2)` lines. Last expression is

```scheme
(derivative (alge "x^3 + 3*x^2 + 5") x)
```

so a whole-buffer `C-x C-e` has last value
`(+ (* 6 x) (* 3 (^ x 2)))`. Include `(+ x x)` so a region eval can
show `(* 2 x)`.

Shape:

```scheme
(import (mpl rnrs-sans)
        (mpl all))

(vars a b c d x y z pi t)

(+ x x)
;; … remaining goldens …
(derivative (alge "x^3 + 3*x^2 + 5") x)
```

Do not add a second sample that is empty or that relies on
auto-`vars`. A default-`(rnrs)` case belongs in the Chez-script, not
in a second example file.

### 10.3 Hand check in chezmacs

After the snippet in §9 is in the installation's `config.e` and a
head has loaded it:

1. Open `examples/mpl.ws`. The buffer's mode is `"worksheet"`
   (suffix detection). Highlighting looks like Scheme.
2. Activate a region containing only `(+ x x)`. `C-x C-e` echoes
   `(* 2 x)`. The editor does not crash.
3. `M-x (+ 1 2)` echoes `3`.
4. With the mark inactive, `C-x C-e` on the whole file echoes
   `(+ (* 6 x) (* 3 (^ x 2)))`.
5. In a `.sls` / `.ss` Scheme buffer, `C-x C-e` is still
   `eval:run!` (editor top level).
6. Header recreation: in `examples/mpl.ws`, evaluate a `(define …)`
   so it persists on a later region `C-x C-e`; change the leading
   import header (for example to `(import (rnrs))`); `C-x C-e`
   again. The definition is gone (unbound / error). Killing the
   buffer also drops the environment; reopening the file is a new
   environment. A Chez-script cannot see the weak table; this
   bullet is the check.

A second worksheet buffer not sharing `define`s with the first is
required behavior; proving it in the Chez-script with two
environments is enough. A second-buffer hand check is optional.
Opening a `.mpl` file and seeing mode `"worksheet"` is optional; the
ending is registered, with no extra semantics.

Do not block this specification on a new chezmacs TTY test harness.

## 11. Slice hint (for the checkpoint manager)

Two layers, two checkpoints. Do not add a third for future worksheet
insert.

1. **chezmacs-mpl 000 — env algebra.** `lib/worksheet-env.sls` and
   `tests/worksheet-env.ss`. Green when
   `scheme --script tests/worksheet-env.ss` passes §10.1. No
   chezmacs module, no `config.e`, no worksheet mode.
2. **chezmacs-mpl 001 — chezmacs module.** `lib/worksheet-mode.sls`
   and `examples/mpl.ws`, depending on 000. Green when §7–§9 are
   implemented and the §10.3 hand check is written for the human.
   Still no chezmacs tree edit.

The manager writes **one** of those files at a time under
`checkpoints/`, after human review of this spec.

## 12. Non-goals

- Inserting `; => (* 2 x)` or a result line under point (worksheet UI)
- A Maxima / Mathematica notebook UI
- Rebinding `M-x` in worksheet buffers
- Prefixing identifiers (`mpl:+`)
- Importing worksheet libraries into `(interaction-environment)`
- `kernel:load-module!` of `"all"` or any MPL / third-party stem
- Mode name `"mpl"`, default import of MPL, auto-`vars`
- Editing `/home/dharmatech/src/e` (default)
- Fingerprint / daemon / wire changes
- Hot-reload of `/home/dharmatech/src/mpl` (or other `~/src`
  libraries) when those files are saved
- A describe / edoc corpus for MPL or other libraries (a describe
  entry for `worksheet-mode:run!` is in scope)
- Infix input except what a library already provides (MPL
  `(alge "…")` in the sample)
- Sharing one env across heads or across buffers
- Hijacking scheme-mode or `.sls` evaluation
- Evaluating inside `(library …)` forms as if they were a REPL
- Changing MPL, Surfage, or Dharmalab
- Making MPL a bundled chezmacs module
- Using MPL's `+` for chezmacs's own arithmetic
- Windows / non-Chez Scheme
- Auto format-on-save for `"worksheet"` buffers
- Unbound-identifier self-quoting

A later seam in `eval.sls` is named in §8 and is not required.
