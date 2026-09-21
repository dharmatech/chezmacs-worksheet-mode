# chezmacs-mpl 001 — chezmacs module

**Status.** Implemented and reviewed. `scheme --script
tests/worksheet-env.ss` still exits 0. Mode `"worksheet"`, sample
`examples/mpl.ws`, and the installation `config.e` snippet are in
place. The six-bullet live-head hand check passed. No chezmacs
`lib/**` edit. There is no 002.

Identity is `(chezmacs-mpl, 001)`, spoken **chezmacs-mpl 001**.

The implementer receives only this document. Every rule for this
slice is below. Do not write 002. There is no 002 in this project.
Do not edit `/home/dharmatech/src/e/lib/**`. Do not patch
`eval.sls`.

## Goal

Load a chezmacs module `"worksheet-mode"` from this journal's
`lib/`. It registers mode `"worksheet"` for `.ws` and `.mpl`, binds
`C-x C-e` in keymap context `'worksheet` to a private evaluate-and-echo
path, and evaluates that text in the buffer's mutable Chez environment
from **chezmacs-mpl 000**. `M-x` stays Chez `+` and `eval:prompt!`.

Green when:

1. From the journal root, `scheme --script tests/worksheet-env.ss`
   still exits `0` (000 must not regress).
2. `lib/worksheet-mode.sls` and `examples/mpl.ws` exist as specified
   below.
3. The installation `config.e` contains the snippet in **config.e**.
4. The **Hand check** has been performed in a live chezmacs head.

This is layer 2 only. Do not reopen env algebra, clash detection, or
auto-`vars`. Do not insert evaluation results into the buffer.

## Authority and starting point

- chezmacs-mpl 000 is implemented and reviewed:
  `lib/worksheet-env.sls`, `tests/worksheet-env.ss`. Import
  `(worksheet-env)`. Do not fork it. Do not edit it.
- Chez 10.4.1 (`scheme` / `scheme-script`). The editor checkout and
  command remain `e` (`/home/dharmatech/src/e`). Prose calls it
  **chezmacs**.
- `/home/dharmatech/src/mpl` is the sample library, with
  `/home/dharmatech/src/surfage` and `/home/dharmatech/src/dharmalab`
  beside it. Do not copy or change those trees.
- Git `5150522` specified `(mpl-mode)`, mode `"mpl"`, default
  `(mpl all)`, auto-`vars`. Do not implement that round.
- Public chezmacs seams (do not patch them; call them):
  - `/home/dharmatech/src/e/lib/core/kernel.sls` —
    `load-module!`, `persistent-cell`, `condition-text`,
    `init-module!` prefixing
  - `/home/dharmatech/src/e/lib/head/mode.sls` — `register!`,
    `find`, `styles`, `render`, `row-styles`, `indenter`,
    `formatter`, `register-indenter!`, `register-formatter!`,
    `key-context`
  - `/home/dharmatech/src/e/lib/head/keymap.sls` —
    `bind-default!` (not `bind!`)
  - `/home/dharmatech/src/e/lib/head/dispatch.sls` — mode
    context, then the global map
  - `/home/dharmatech/src/e/lib/head/edit.sls` —
    `buffer-text`, `current-region`, `region-text`,
    `call-as-one-edit!`, `set-message!`, `copy-to-kill-buffer!`,
    `message-source`
  - `/home/dharmatech/src/e/lib/head/head.sls` —
    `current-buffer`, `mark`, `call-with-interrupt`,
    `interrupted?`
  - `/home/dharmatech/src/e/lib/head/echo.sls` — `set-ghost!`
    (optional)
  - `/home/dharmatech/src/e/lib/apps/eval.sls` —
    `copy-result` only. **Do not call `eval:run!`.** Its
    `evaluation-outcome` (around line 1032) is the capture
    pattern to duplicate, not to import.
  - `/home/dharmatech/src/e/lib/sys/sys.sls` —
    `duplicate-standard-output-port`, `terminal-output-port`,
    `call-with-streamed-output`
  - `/home/dharmatech/src/e/lib/service/doc.sls` — `register!`
  - `/home/dharmatech/src/e/lib/service/log.sls` — `add!`
  - `/home/dharmatech/src/e/lib/modes/scheme-mode.sls` — reuse
    from the registry; do not copy this file
  - `/home/dharmatech/src/e/lib/apps/terminal.sls` — pattern for
    `kernel:persistent-cell` plus `make-weak-eq-hashtable`
  - `/home/dharmatech/src/e/config.template.e` — `config.e` is
    plain Scheme in the interaction environment, loaded any
    number of times

`(import …)` is still environment spec, not `eval`, as 000 already
implements. `run!` must use `parse-worksheet` / `eval-program` /
`eval-forms` / `make-worksheet-environment` from `(worksheet-env)`.

A later one-function seam in `eval.sls` that takes a caller-supplied
environment is **not** this slice. Duplicate the small path here.

## Exact file scope

**Create:**

- `lib/worksheet-mode.sls`
- `examples/mpl.ws`

**May update:**

- [`README.md`](../README.md) status lines only (001 implemented or
  not). Journal map: [`../../../../README.md`](../../../../README.md).
  Do not rewrite the pipeline, charter, or spec.
- `/home/dharmatech/src/e/config.e` — the installation's gitignored
  config, next to the loader. Append the snippet in **config.e**.
  If that file does not exist, create it (the snippet alone is
  enough, or copy `config.template.e` and append). Do not commit
  `config.e`. Do not edit `config.template.e`.

**Do not edit:**

- `lib/worksheet-env.sls`
- `tests/worksheet-env.ss`
- `spec.md`, `charter.md`
- `checkpoints/000-env-algebra.md`
- `/home/dharmatech/src/e/lib/**`
- `/home/dharmatech/src/e/main.sls`, `config.template.e`
- `/home/dharmatech/src/mpl`, `/home/dharmatech/src/surfage`,
  `/home/dharmatech/src/dharmalab`, or any other collection under
  `/home/dharmatech/src`

Do not vendor MPL, Surfage, or Dharmalab into this tree or into
chezmacs. Do not add `"worksheet-mode"` to chezmacs's bundled
`kernel:load-modules!` list. Do not compile into
`/home/dharmatech/src`. Objects go in this journal's `eo/`.

Use `(library …)`, not chezmacs `elibrary`. This tree is not under
chezmacs's elinter.

Do not add a second sample file. Do not add a Chez-script that
launches chezmacs. Do not add a TTY test harness.

## Library

**File.** `lib/worksheet-mode.sls`  
**Library name.** `(worksheet-mode)`  
**Exports.** `init!` and `run!` only  
**Loaded as.** `(kernel:load-module! "worksheet-mode")`

`kernel:module-library` for a stem not under chezmacs's `lib/` is
`(worksheet-mode)`, which resolves through `library-directories` to
this journal `lib/worksheet-mode.sls` once `config.e` prepends that
root.

The kernel prefixes the library in the interaction environment, so
the command is `worksheet-mode:run!` at M-x. `init!` is invoked by
the kernel through `(import (only (worksheet-mode) init!))` and is
not a user command.

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

`(apps eval)` is imported only for `eval:copy-result` (a parameter;
the exported name is `copy-result`). Do not call `eval:run!`. Do
not import `(mpl all)` or any other third-party collection at
library level. Loading this module must not rebind `+` in the
editor top level.

Do not use `(mpl-mode)`, `(mpl mode)`, `(mpl-env)`, or `(mpl env)`.

## `init!` registrations

`init!` must:

1. Call `prepare-library-directories!` (`config.e` already added
   `lib/` so the module could load; this call still ensures
   `/home/dharmatech/src` and this journal `eo/`).
2. Register mode `"worksheet"` with endings `'(".ws" ".mpl")` and no
   `#!` interpreters. Do not steal scheme-mode's endings
   (`.scm` `.ss` `.sls` `.sps` `.sc` `.e`). `.mpl` is the same mode
   as `.ws`: opening `foo.mpl` does not import MPL and does not run
   `vars`.
3. Reuse scheme-mode's presentation without copying
   `scheme-mode.sls`. After bundled modules have loaded, scheme-mode
   is in the registry. Use this exact shape:

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
   `worksheet-mode:run!` in the eight-field format other modules
   use (names, forms, returns, libraries, source, chapter, url,
   description). One entry is enough. Point source at `run!`.
   Chapter may be `"Worksheets"`. url is `#f`. The description
   should say that the region, else the whole buffer, is evaluated
   in that buffer's worksheet environment.

chezmacs already resolves keys in `mode:key-context` before the
global map (`lib/head/dispatch.sls`). Mode `"worksheet"` yields
context `'worksheet`. While that buffer is current, context
`'worksheet` owns `C-x C-e`. Ordinary Scheme buffers keep
`eval:run!`.

`(mode:choose! buffer "worksheet")` already works; this project
does not wrap it.

## Per-buffer environment, off the store

Each worksheet buffer owns a mutable Chez environment created by
`make-worksheet-environment`.

Do **not** store a Chez environment object in buffer facts. Facts may
be serialized; environment objects must not. Keep live environments
in head-local memory: a `weak-eq-hashtable` keyed by the buffer
object. Hold that table in a `kernel:persistent-cell` under the key
`'worksheet-mode-environments` (that call returns a box; the
hashtable is the box's contents) so reloading `worksheet-mode` does
not drop worksheet definitions.

Follow the `terminal.sls` pattern: unbox the cell at library load
(or equivalently in `init!`; the cell key is what survives reload).
Mutate the hashtable in place.

Values in the table are `(cons import-specs env)` (or an equivalent
pair of serializable specs plus the live env). The specs are
compared with `equal?`.

Recreation:

- First `run!` for a buffer creates the environment from the whole
  buffer's `parse-worksheet` import-specs (default `(rnrs)` if no
  header).
- If the whole-buffer leading import-spec list has changed since
  that environment was built, discard it and create a new one.
  Definitions from the old copy are gone. Construction errors
  (clash table from 000, invalid specs) become `error: ` echo
  text; the editor process does not crash.
- Killing the buffer drops the association because the key is weak.
  Reopening the file is a new buffer and a new environment.
- Reloading `worksheet-mode` keeps the persistent-cell table.
  Reloading does not, by itself, rebuild environments.

There is no sharing across buffers. There is no sharing across heads.

`M-x` always uses `(interaction-environment)`. Worksheet `C-x C-e`
never does.

## What `run!` evaluates

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
  `(import …)` is an error (`eval-forms` will raise; report it).

A region that is only `(+ x x)` uses the environment already built
from the file header (or from `(rnrs)`).

`run!` acts on the current buffer. It does not need a mode-name
guard beyond the `'worksheet` key binding; calling
`worksheet-mode:run!` from M-x on a non-worksheet buffer is allowed
to treat that buffer as a worksheet (header, private env) and is
not a required test.

`run!` returns unspecified / void so an M-x invocation of
`(worksheet-mode:run!)` does not grow a second result. The worksheet
echo comes from `edit:set-message!` inside `run!`.

## How `C-x C-e` reports

`eval:run!` logs, copies non-void results to the kill ring, captures
stdout/stderr, and is interruptible with `C-g`. Its helpers hardcode
`(interaction-environment)` and are not exported. Duplicate a small
path with public APIs.

Required:

- Wrap evaluation in `head:call-with-interrupt`. On
  `head:interrupted?`, the echo text is exactly `interrupted`.
- Wrap editor mutations from evaluated code in
  `edit:call-as-one-edit!` with label `"(worksheet-mode:run!)"`.
- Reader and evaluation failures become `error: ` plus
  `(kernel:condition-text ex)`. The editor process does not crash.
  Follow `eval.sls`: `guard` around `head:call-with-interrupt`,
  mapping `(head:interrupted? ex)` to `"interrupted"` and other
  conditions to `(format "error: ~a" (kernel:condition-text ex))`.
- The last value is shown in the echo area with Chez
  `(format "~s" value)`. Multiple values are joined with `", "`.
  Zero values, or a single `#<void>` (`eq?` to `(void)`), are void:
  show `#<void>` and do not copy to the kill ring.
- The echo must contain the printed value. A region eval of
  `(+ x x)` in the MPL sample shows `(* 2 x)` (the characters of
  that `~s` print). Do not require the `eval: … =>` log template.
- Use `edit:set-message!` for that echo text. Do **not**
  `log:add!` an `'eval` record: M-x history is derived from `'eval`.
  Worksheet runs must not pollute M-x history. Default
  `edit:set-message!` logs under `'e`; that is allowed. Echo-only
  (`(parameterize ([edit:message-source #f]) …)`) is also allowed.

`eval-forms` / `eval-program` return multiple values. Use
`call-with-values` / `let-values`. Do not treat a successful `eval`
whose only value is `#f` as void.

Desirable and required because the APIs are public and cheap:

- If `(eval:copy-result)` is true and the result is non-void and not
  an error or interrupt, `edit:copy-to-kill-buffer!` the same printed
  string. Optional ghost ` [stored in kill ring]` via
  `echo:set-ghost!` is allowed, not required.
- Capture Scheme stdout/stderr the same way `eval.sls`'s
  `evaluation-outcome` does, not with `sys:call-with-streamed-output`
  alone:
  - `sys:duplicate-standard-output-port` before capture, closed
    afterward (`dynamic-wind`)
  - `parameterize` `sys:terminal-output-port` to that port so
    `log:add!` still reaches the real terminal
  - `sys:call-with-streamed-output` posting complete lines with
    `log:add!` to `'stdout` / `'stderr` (a mutex around those
    `log:add!` calls, as in `eval.sls`)
  - Do not invent a new log component

Sketch of the capture wrapper (adapt, do not call `evaluate-text`):

```scheme
(let ([lock (make-mutex)]
      [terminal (sys:duplicate-standard-output-port)])
  (define (record! component line)
    (parameterize ([sys:terminal-output-port terminal])
      (with-mutex lock (log:add! component line))))
  (dynamic-wind
    void
    (lambda ()
      (parameterize ([sys:terminal-output-port terminal])
        (sys:call-with-streamed-output
          (lambda (line) (record! 'stdout line))
          (lambda (line) (record! 'stderr line))
          thunk)))
    (lambda () (close-port terminal))))
```

`thunk` is the guarded interruptible `edit:call-as-one-edit!` that
runs `eval-program` or `eval-forms` in the buffer environment.

Do not `log:add!` `'eval`. Do not call `edit:present-log-entries!`.

## config.e

`config.e` is the installation's, next to chezmacs's loader
(`/home/dharmatech/src/e/config.e`), and is evaluated in the
interaction environment. It must tolerate being loaded any number of
times. `kernel:load-module!` is already idempotent.

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

After editing `config.e`, a head must load it (restart `e`, or
`main:load-config!` if the head is already up and `library-directories`
will see `lib/` before the load-module). The hand check assumes a
head that has loaded this snippet.

## Sample worksheet

**File.** `examples/mpl.ws`

A Chez program a human can open in chezmacs. It **must** start with
the explicit MPL import (not omit it). No Unix `#!/usr/bin/env`
shebang: Chez `read` on a string port rejects that, and `C-x C-e`
reads the buffer with Chez `read`. `#!r6rs` is allowed; do not
require it. Use this exact sequence of forms:

```scheme
(import (mpl rnrs-sans)
        (mpl all))

(vars a b c d x y z pi t)

(+ x x)
(* x y x)
(+ x y x z 5 z)
(algebraic-expand (alge "(x+1)^2"))
(algebraic-expand (alge "(x+2)*(x+3)*(x+4)"))
(derivative (alge "sin(x)") x)
(derivative (alge "x^3 + 3*x^2 + 5") x)
```

Last expression is `(derivative (alge "x^3 + 3*x^2 + 5") x)`, so a
whole-buffer `C-x C-e` has last value
`(+ (* 6 x) (* 3 (^ x 2)))`. Include `(+ x x)` so a region eval can
show `(* 2 x)`.

`(vars …)` is worksheet code, not mode default. Do not add a second
sample that is empty or that relies on auto-`vars`. A default
`(rnrs)` case belongs in the 000 Chez-script, not in a second
example file.

## Tests

Do not add a new Chez-script for the mode. Do not launch chezmacs
from `tests/`. `uv` is wrong.

Regression (required): from the journal root

```sh
scheme --script tests/worksheet-env.ss
```

still exits `0`.

The environment layer remains 000's. This slice's proof is the hand
check.

## Hand check

After the snippet is in `/home/dharmatech/src/e/config.e` and a head
has loaded it:

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
required behavior; 000 already proved two `make-worksheet-environment`
results are isolated. A second-buffer hand check is optional.
Opening a `.mpl` file and seeing mode `"worksheet"` is optional; the
ending is registered, with no extra semantics.

Do not block this slice on a new chezmacs TTY test harness. Report
the six numbered bullets as done or not in the implementer handoff.

## Acceptance

Wrong unless all of these are true:

1. `scheme --script tests/worksheet-env.ss` still exits `0`.
2. A worksheet that begins with
   `(import (mpl rnrs-sans) (mpl all))`, then `(vars …)`, then
   `(+ x x)` evaluates a region of `(+ x x)` to `(* 2 x)` with no
   `mpl:` prefix. Whole-buffer last value is
   `(+ (* 6 x) (* 3 (^ x 2)))`.
3. After the extension is loaded, `M-x (+ 1 2)` is still `3`.
   Editor commands keep their meaning. Worksheet libraries are not
   imported into `(interaction-environment)`.
4. `C-x C-e` in a worksheet buffer uses that buffer's environment.
   Ordinary `.sls` / `.ss` buffers keep `eval:run!`.
5. No MPL unless the file asked. `.mpl` is only a second ending.
   No auto-`vars`. Default header is `(rnrs)` via 000.
6. Mode is `"worksheet"`, loaded with
   `kernel:load-module!` of `"worksheet-mode"`, not of MPL.
7. No chezmacs `lib/**` edit. `config.e` is installation config
   only.
8. Environments live in the weak table / persistent cell, not in
   buffer facts. Header change recreates. Buffer kill drops.

## Non-goals (this slice)

- Inserting `; => (* 2 x)` or a result line under point
- A Maxima / Mathematica notebook UI
- Rebinding `M-x` in worksheet buffers
- Prefixing identifiers (`mpl:+`)
- Importing worksheet libraries into `(interaction-environment)`
- `kernel:load-module!` of `"all"` or any MPL / third-party stem
- Mode name `"mpl"`, default import of MPL, auto-`vars`
- Editing `/home/dharmatech/src/e/lib/**`
- Fingerprint / daemon / wire changes
- Hot-reload of `/home/dharmatech/src/mpl` (or other `~/src`
  libraries) when those files are saved
- A describe / edoc corpus for MPL (the `worksheet-mode:run!`
  entry is in scope)
- Infix input except MPL `(alge "…")` in the sample
- Sharing one env across heads or across buffers
- Hijacking scheme-mode or `.sls` evaluation
- Evaluating inside `(library …)` forms as if they were a REPL
- Changing MPL, Surfage, or Dharmalab
- Making MPL a bundled chezmacs module
- Using MPL's `+` for chezmacs's own arithmetic
- Windows / non-Chez Scheme
- Auto format-on-save for `"worksheet"` buffers
- Unbound-identifier self-quoting
- A seam in `eval.sls`
- Reopening 000 (clash algorithm, parse rules, goldens as Chez-script)

chezmacs-mpl 000 stays as reviewed. This project has two checkpoints
and no third for future worksheet insert.
