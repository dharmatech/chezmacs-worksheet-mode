# Specification — MPL evaluation in chezmacs

**Status.** Design for the local **chezmacs-mpl** project. This is not
chezmacs upstream, a checkpoint, or an implementer assignment. A later
checkpoint-manager conversation slices **chezmacs-mpl 000**, `001`, …
under [`checkpoints/`](checkpoints/). The checkpoint manager will not
have [`charter.md`](charter.md); this file is the law.

The editor's checkout and command remain `e`
(`/home/dharmatech/src/e`). Prose in this project calls the editor
**chezmacs**. Paths, `config.e`, and the `.e` config extension keep
their on-disk names.

This specification is a **personal chezmacs extension**: a worksheet
file gets its own mutable Chez top level so idiomatic MPL `(+ x x)`
is computer algebra, while `M-x` keeps Chez `+`. It ships without
editing `/home/dharmatech/src/e/lib/**`.

## 1. Resolved choices

These close the charter's open questions. Do not reopen them.

| Question | Choice |
|---|---|
| File ending | `.mpl`. Detection is by that suffix. Not `.mpl.ss` (that suffix also matches scheme-mode's `.ss`). Not `.scm` / `.ss` / `.sls` / `.sps` / `.sc` / `.e`. |
| Mode name | `"mpl"`. Keymap context is therefore `'mpl`. `(mode:choose! buffer "mpl")` already works; this project does not wrap it. |
| Auto-`vars` | On every new worksheet environment, evaluate `(vars a b c d x y z pi t)` — the set `test.sls` uses at the start of MPL's suite. A file may still contain `(vars …)`; that keeps working. No unbound-identifier self-quote. |
| `C-x C-e` reporting | Duplicate a small evaluate-and-echo path in the extension. Do not call `eval:run!`. Do not patch `eval.sls`. Reuse public `head:`, `edit:`, `eval:copy-result`, and `sys:` APIs listed in §8. |
| Tests | Chez-script `tests/mpl-env.ss` (`scheme --script`, no `uv`, no TTY, no running chezmacs) for the environment layer. Sample `examples/worksheet.mpl`. Mode/key binding is a named hand check. |
| Libraries | Two layers only: `(mpl-env)` then `(mpl-mode)`. No third layer. |

Names `(mpl-env)` and `(mpl-mode)` are one-component library names
mapping to `lib/mpl-env.sls` and `lib/mpl-mode.sls`. Do **not** use
`(mpl env)` or `(mpl mode)`: those would resolve under
`/home/dharmatech/src/mpl/`.

## 2. Bar (acceptance)

The implementation is wrong unless all of these are true:

1. **A file, not a prefix.** A worksheet buffer can contain `(+ x x)`
   and evaluate it to `(* 2 x)`. The user does not write `mpl:+` or
   `all:+`.
2. **The editor is unharmed.** After the extension is loaded,
   `M-x (+ 1 2)` is still Chez arithmetic (`3`). Editor commands
   (`head:`, `eval:`, …) keep their current meaning. MPL's `+` is not
   imported into `(interaction-environment)`.
3. **The environment is the file's.** `C-x C-e` in a worksheet buffer
   evaluates in that buffer's mutable Chez environment, not in the
   editor top level. Two worksheet buffers do not share definitions.
   Two heads do not share a Chez environment (each head is its own
   process; environments are head-local).
4. **It is a Chez program, not an R6RS library.** The worksheet is a
   top-level script: optional leading `(import …)`, then definitions
   and expressions. A top-level `(library (foo) …)` is not special-cased
   and is not the worksheet shape.
5. **First consumer is tests plus one sample file**, as named in §10.
6. **The chezmacs piece is a mode-shaped extension**, loaded with
   `kernel:load-module!` of **`"mpl-mode"`**, not of MPL. It binds
   worksheet `C-x C-e` in context `'mpl` so the global editor binding
   is left alone in ordinary Scheme buffers.
7. **No chezmacs tree edit.** Anything this spec needs from chezmacs
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
lib/mpl-env.sls            layer 1: environment algebra
lib/mpl-mode.sls           layer 2: chezmacs module
tests/mpl-env.ss           Chez-script tests for layer 1
examples/worksheet.mpl     sample worksheet
eo/                        generated Chez object cache (not source)
```

Do not copy MPL, Surfage, or Dharmalab into this tree or into
chezmacs. Do not add `"mpl-mode"` to chezmacs's bundled
`kernel:load-modules!` list in `main.sls`. Do not vendor this
extension under `/home/dharmatech/src/e/lib/`.

`(mpl-env)` is an ordinary R6RS library. It does not export `init!`
and must not import any chezmacs library. `(mpl-mode)` is a chezmacs
module: it exports `init!`, is loaded from `config.e` via
`kernel:load-module!`, and imports `(mpl-env)` plus prefixed chezmacs
seams.

Use `(library …)`, not chezmacs `elibrary`. This tree is not under
chezmacs's elinter.

## 4. Paths and compilation

Hard-code these paths (this is a personal experiment on this host):

| Role | Path |
|---|---|
| Journal root | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl` |
| Extension library root | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl/lib` |
| Object cache | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo` |
| MPL / Surfage / Dharmalab root | `/home/dharmatech/src` |

`(library-directories)` must include `/home/dharmatech/src` so
`(mpl all)` maps to `/home/dharmatech/src/mpl/all.sls`, `(surfage …)`
to `/home/dharmatech/src/surfage/…`, and `(dharmalab …)` to
`/home/dharmatech/src/dharmalab/…`. Adding `/home/dharmatech/src/mpl`
as a root is wrong (`mpl/mpl/all.sls`).

Object files go in the journal `eo/` cache, including compiled MPL.
Do not compile into `/home/dharmatech/src`. Do not require chezmacs's
`eo/client` (MPL may already have been compiled there; this project
must still run its Chez-script tests without that cache).

`prepare-library-directories!` (layer 1) is idempotent:

1. `(compile-imported-libraries #t)`
2. Create `eo/` if it does not exist.
3. If `/home/dharmatech/src` is not already a `library-directories`
   source, prepend `(cons src eo)`.
4. If the journal `lib/` is not already a source, prepend
   `(cons lib eo)` so it is searched first.

Prepending `lib/` last makes it the first root, so
`kernel:load-module!` finds `mpl-mode.sls` here. `assoc` on the
source path is enough to decide whether a root is already present.

## 5. Layer 1 — `(mpl-env)`

**File.** `lib/mpl-env.sls`  
**Library name.** `(mpl-env)`  
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

(define env
  (copy-environment
    (apply environment import-specs)
    #t))

(eval default-vars-form env)
```

`import-specs` is a list of Chez import-spec datums, defaulting to
`((mpl rnrs-sans) (mpl all))`. `(mpl rnrs-sans)` is MPL's
RNRS-without-clashes. Together with `(mpl all)` it is the default
import set.

`(copy-environment … #t)` is mutable: `define` and `vars` persist in
that copy until it is discarded.

`(eval '(import …) env)` must not be how the environment is built. A
test may show that evaluating an `import` form in the copy raises.

`(mpl-env)` itself must not `(import (mpl all))` at library level, so
loading this library does not rebind `+` in the test script or in
chezmacs's interaction environment.

### 5.2 Default `vars`

`default-vars-form` is the datum `(vars a b c d x y z pi t)`.

`make-worksheet-environment` evaluates that form in the new copy so
a new empty worksheet can be just `(+ x x)`. After construction,
`(eval 'x env)` is the symbol `x`.

A name not in that set (for example `q`) remains unbound until the
worksheet evaluates `(vars q)` or `(define q …)`. Do not install an
unbound-identifier handler that self-quotes unknown symbols.

If the import-spec list does not provide `vars`, construction fails
by raising that error. A header that wants auto-`vars` must import
`(mpl all)` or another library that exports `vars`.

A later `(vars …)` form in the file is ordinary syntax in that
environment and keeps working.

### 5.3 Leading `import` is environment spec, not eval

A worksheet may begin with one or more `import` forms:

```scheme
(import (mpl rnrs-sans)
        (mpl all))

(vars x y)

(+ x x)
```

`parse-worksheet` reads datums from the start of a string with Chez
`read` (whitespace and comments skipped; Chez `#!r6rs` / shebang
directives follow Chez). Consecutive **leading** datums whose first
element is the symbol `import` are the environment spec: the
concatenation of each form's operands (the `cdr`) is the import-spec
list passed to `environment`. Those forms are not evaluated.

- Zero leading `import` forms: use `default-import-specs`.
- One or more leading `import` forms: use those specs **instead of**
  the default, not in addition to it. `(import)` with no operands is
  an empty spec list; construction then fails when auto-`vars` cannot
  run.
- An `import` that is not a leading prefix (a form after a
  definition or expression) is not environment spec. Evaluating it
  is an error.

`only` / `prefix` / `rename` / `except` import-specs are allowed
because `environment` accepts them. This project does not invent a
restricted import language.

Evaluating a region that is only `(+ x x)` still uses the buffer
environment, which was built from the **file** header (or from the
default if there is no header), not from the region.

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

`(mpl-env)` exports exactly:

| Export | Meaning |
|---|---|
| `src-root` | `"/home/dharmatech/src"` |
| `object-directory` | the journal `eo/` path in §4 |
| `prepare-library-directories!` | §4, idempotent |
| `default-import-specs` | `'((mpl rnrs-sans) (mpl all))` |
| `default-vars-form` | `'(vars a b c d x y z pi t)` |
| `read-forms` | `string → list` of datums |
| `parse-worksheet` | `string → (values import-specs remaining-forms)` |
| `make-worksheet-environment` | `import-specs →` mutable env with auto-`vars` |
| `eval-forms` | `forms env →` values of the last form |
| `eval-program` | `string env →` values of the last remaining form |

`parse-worksheet` applies the default import-spec rule in §5.3.
`remaining-forms` is the list after stripping leading `import`
datums (possibly empty).

Do not export a chezmacs buffer object, a weak table, or anything
that imports chezmacs.

## 6. Goldens

These were checked against `/home/dharmatech/src/mpl` with the
construction in §5.1. Layer 1 tests must include them as `equal?`
checks, not weaker substitutes.

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

## 7. Layer 2 — `(mpl-mode)`

**File.** `lib/mpl-mode.sls`  
**Library name.** `(mpl-mode)`  
**Exports.** `init!` and `run!`  
**Loaded as.** `(kernel:load-module! "mpl-mode")`

After the kernel prefixes the library, the command is
`mpl-mode:run!` at M-x. `init!` is invoked by the kernel through
`(import (only (mpl-mode) init!))` and is not used as a user command.

### 7.1 `init!` registrations

`init!` must:

1. Call `prepare-library-directories!` (config.e already added
   `lib/` so the module could load; this call still ensures `~/src`
   and `eo/`).
2. Register mode `"mpl"` with endings `'(".mpl")` and no `#!`
   interpreters. Do not steal scheme-mode's endings.
3. Reuse scheme-mode's presentation without copying
   `scheme-mode.sls`. After bundled modules have loaded, scheme-mode
   is in the registry:

   ```scheme
   (let ([scheme (mode:find "scheme")])
     (mode:register! "mpl" '(".mpl") '()
                     (and scheme (mode:styles scheme))
                     (and scheme (mode:render scheme))
                     (and scheme (mode:row-styles scheme)))
     (let ([indent (mode:indenter "scheme")]
           [format (mode:formatter "scheme")])
       (when indent (mode:register-indenter! "mpl" indent))
       (when format (mode:register-formatter! "mpl" format))))
   ```

   TAB indent and `edit:format-buffer!` then work as in Scheme.
   scheme-mode's format-on-save hook only formats buffers whose mode
   name is `"scheme"`; do not add a worksheet format-on-save hook.
4. `(keymap:bind-default! 'mpl "C-x C-e" run!)`. Not
   `keymap:bind!`. Not a global `C-x C-e`. `M-x` stays
   `eval:prompt!`.
5. `doc:register!` a short describe entry for `mpl-mode:run!`.

chezmacs already resolves keys in `mode:key-context` before the
global map (`lib/head/dispatch.sls`). While a `"mpl"` buffer is
current, context `'mpl` owns `C-x C-e`. Ordinary Scheme buffers keep
`eval:run!`.

### 7.2 Per-buffer environment, off the store

Each worksheet buffer owns a mutable Chez environment created by
`make-worksheet-environment`.

Do **not** store a Chez environment object in buffer facts. Facts may
be serialized; environment objects must not. Keep live environments
in head-local memory: a `weak-eq-hashtable` keyed by the buffer
object. Hold that table in a `kernel:persistent-cell` under the key
`'mpl-mode-environments` (that call returns a box; the hashtable is
the box's contents) so reloading `mpl-mode` does not drop worksheet
definitions. Values in the table are `(cons import-specs env)` (or
an equivalent pair of serializable specs plus the live env). The
specs are compared with `equal?`.

Recreation:

- First `run!` for a buffer creates the environment from the whole
  buffer's `parse-worksheet` import-specs (default if no header) and
  auto-`vars`.
- If the whole-buffer leading import-spec list has changed since
  that environment was built, discard it and create a new one.
  Definitions from the old copy are gone.
- Killing the buffer drops the association because the key is weak.
  Reopening the file is a new buffer and a new environment.
- Reloading `mpl-mode` keeps the persistent-cell table. Reloading
  does not, by itself, rebuild environments.

There is no sharing across buffers. There is no sharing across heads.

`M-x` always uses `(interaction-environment)`. Worksheet `C-x C-e`
never does.

### 7.3 What `run!` evaluates

Match chezmacs's current `C-x C-e` shape for the **span of text**:
`(edit:region-text (edit:current-region))` is the selected region
while the mark is active (`head:mark` is true), else the whole
current buffer.

Always parse **the whole buffer text** to obtain import-specs and to
ensure the buffer environment, even when the mark is active.

Then:

- **Mark inactive (whole buffer).** `eval-program` on that text in
  the buffer environment. Leading `import` forms are environment
  spec, not expressions.
- **Mark active (region).** `eval-forms` of `read-forms` of the
  region text in the buffer environment. Do not treat a region's
  leading `import` as environment spec. A region that is only
  `(import …)` is an error.

A region that is only `(+ x x)` uses the environment already built
from the file header (or the default).

`run!` acts on the current buffer. It does not need a mode-name
guard beyond the `'mpl` key binding; calling `mpl-mode:run!` from
M-x on a non-worksheet buffer is allowed to treat that buffer as a
worksheet (header, private env, auto-`vars`) and is not a required
test.

## 8. How `C-x C-e` reports

`eval:run!` logs, copies non-void results to the kill ring, captures
stdout/stderr, and is interruptible with `C-g`. Its helpers hardcode
`(interaction-environment)` and are not exported. This project
duplicates a small path with public APIs.

Required:

- Wrap evaluation in `head:call-with-interrupt`. On
  `head:interrupted?`, the echo text is `interrupted`.
- Wrap editor mutations from evaluated code in
  `edit:call-as-one-edit!` with label `"(mpl-mode:run!)"`.
- Reader and evaluation failures become `error: ` plus
  `(kernel:condition-text ex)`. The editor process does not crash.
- The last value is shown in the echo area with Chez
  `(format "~s" value)`. Multiple values are joined with `", "`.
  Zero values, or a single `#<void>`, are void: show `#<void>` and
  do not copy to the kill ring.
- The echo must contain the printed value. A whole-buffer eval of
  `(+ x x)` shows `(* 2 x)` (the characters of that `~s` print). Do
  not require the `eval: … =>` log template.
- Use `edit:set-message!` for that echo text. Do **not**
  `log:add!` an `'eval` record: M-x history is derived from `'eval`.
  Worksheet runs must not pollute M-x history.

Desirable and required because the APIs are public and cheap:

- If `(eval:copy-result)` is true and the result is non-void and not
  an error or interrupt, `edit:copy-to-kill-buffer!` the same printed
  string. Optional ghost ` [stored in kill ring]` via `echo:set-ghost!`
  is allowed, not required.
- Capture Scheme stdout/stderr with `sys:call-with-streamed-output`
  the same way `eval.sls` does, posting complete lines with
  `log:add!` to `'stdout` / `'stderr`. Do not invent a new log
  component.

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
;; MPL worksheets — journal 2026-09-21-chezmacs-mpl
(let ([src "/home/dharmatech/src"]
      [lib "/home/dharmatech/journal/2026-09-21-chezmacs-mpl/lib"]
      [eo  "/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo"])
  (unless (file-directory? eo) (mkdir eo))
  (compile-imported-libraries #t)
  (unless (assoc src (library-directories))
    (library-directories (cons (cons src eo) (library-directories))))
  (unless (assoc lib (library-directories))
    (library-directories (cons (cons lib eo) (library-directories))))
  (kernel:load-module! "mpl-mode"))
```

The `lib/` pair is consed after `src/` so `lib/` is searched first.
Do not `kernel:load-module!` `"all"`, `"mpl-env"`, or any MPL stem.
Do not `(import (mpl all))` in `config.e`.

## 10. Tests and verification

### 10.1 Chez-script (required, no chezmacs)

**File.** `tests/mpl-env.ss`  
**Run.** from the journal root:

```sh
scheme --script tests/mpl-env.ss
```

`uv` is wrong; this is Scheme. Exit `0` on success, nonzero on
failure.

The script may only `(import (chezscheme))` at the file top (the
same constraint as chezmacs's loader: a top-level import of
`(mpl-env)` would be resolved before `library-directories` is set).
It prepends `lib/` and `src/` with object directory `eo/`, then
`eval`s `(import (mpl-env))` into its interaction environment, then
calls `prepare-library-directories!`.

It must **not** import `(mpl all)` into the interaction environment.

Required checks:

1. All goldens in §6 in a worksheet environment, including
   `(eval '(+ 1 2) (interaction-environment))` ⇒ `3` **after** that
   private environment exists.
2. `(eval 'x env)` ⇒ `x` from auto-`vars`; `(eval 'q env)` raises
   (no self-quote of unknown symbols).
3. `(eval '(+ x x) env)` ⇒ `(* 2 x)` with no `mpl:` prefix.
4. Two environments from `make-worksheet-environment` do not share
   definitions: `(eval '(define k 1) e1)` then `(eval 'k e2)` raises.
5. `parse-worksheet` on `"(+ x x)"` yields `default-import-specs` and
   remaining `((+ x x))`.
6. `parse-worksheet` on a leading `(import (mpl rnrs-sans) (mpl all))`
   yields those specs (not a concatenation with the default) and
   remaining forms without the `import`.
7. `eval-program` of a string that starts with that import and then
   `(+ x x)` ⇒ `(* 2 x)` (the import was not evaluated as an
   expression).
8. `define` persists: evaluate `(define k 1)` then `k` in the same
   env ⇒ `1`.
9. `(eval '(import (mpl all)) env)` raises.
10. `(eval '(vars q) env)` then `(eval 'q env)` ⇒ `q`.

Do not launch chezmacs from this script. Do not require a TTY.

### 10.2 Sample worksheet

**File.** `examples/worksheet.mpl`

A Chez program a human can open in chezmacs. It may start with an
explicit default import header or omit it (both are valid). It
contains, as top-level expressions, the golden forms in §6 except
the interaction-environment line. Last expression is

```scheme
(derivative (alge "x^3 + 3*x^2 + 5") x)
```

so a whole-buffer `C-x C-e` has last value
`(+ (* 6 x) (* 3 (^ x 2)))`. Include `(+ x x)` so a region eval can
show `(* 2 x)`.

### 10.3 Hand check in chezmacs

After the snippet in §9 is in the installation's `config.e` and a
head has loaded it:

1. Open `examples/worksheet.mpl`. The buffer's mode is `"mpl"`
   (suffix detection). Highlighting looks like Scheme.
2. Activate a region containing only `(+ x x)`. `C-x C-e` echoes
   `(* 2 x)`. The editor does not crash.
3. `M-x (+ 1 2)` echoes `3`.
4. With the mark inactive, `C-x C-e` on the whole file echoes
   `(+ (* 6 x) (* 3 (^ x 2)))`.
5. In a `.sls` / `.ss` Scheme buffer, `C-x C-e` is still
   `eval:run!` (editor top level).

A second `.mpl` buffer not sharing `define`s with the first is
required behavior; proving it in the Chez-script with two
environments is enough. A second-buffer hand check is optional.

Do not block this specification on a new chezmacs TTY test harness.

## 11. Slice hint (for the checkpoint manager)

Two layers, two checkpoints. Do not add a third for future worksheet
insert.

1. **chezmacs-mpl 000 — env algebra.** `lib/mpl-env.sls` and
   `tests/mpl-env.ss`. Green when `scheme --script tests/mpl-env.ss`
   passes §10.1. No chezmacs module, no `config.e`, no `.mpl` mode.
2. **chezmacs-mpl 001 — chezmacs module.** `lib/mpl-mode.sls` and
   `examples/worksheet.mpl`, depending on 000. Green when §7–§9 are
   implemented and the §10.3 hand check is written for the human.
   Still no chezmacs tree edit.

The manager writes **one** of those files at a time under
`checkpoints/`, after human review of this spec.

## 12. Non-goals

- Inserting `; => (* 2 x)` or a result line under point (worksheet UI)
- A Maxima / Mathematica notebook UI
- Rebinding `M-x` in worksheet buffers
- Prefixing MPL identifiers
- Importing MPL into `(interaction-environment)`
- `kernel:load-module!` of `"all"` or any MPL stem
- Editing `/home/dharmatech/src/e` (default)
- Fingerprint / daemon / wire changes
- Hot-reload of `/home/dharmatech/src/mpl` when those files are saved
- A describe / edoc corpus for MPL (a describe entry for
  `mpl-mode:run!` is in scope; MPL's own names are not)
- Infix input except MPL's existing `(alge "…")`
- Sharing one env across heads or across buffers
- Evaluating inside `(library …)` forms as if they were a REPL
- Changing MPL, Surfage, or Dharmalab
- Making MPL a bundled chezmacs module
- Using MPL's `+` for chezmacs's own arithmetic
- Windows / non-Chez Scheme
- Auto format-on-save for `"mpl"` buffers
- Unbound-identifier self-quoting

A later seam in `eval.sls` is named in §8 and is not required.
