# chezmacs-mpl 000 — Env algebra

**Status.** Implemented and reviewed. `scheme --script
tests/worksheet-env.ss` from the journal root exits 0; all twelve
checks pass. Clash detection is `environment-symbols` + `eval` +
`eq?`, not a hard-coded name list. Layer 1 only: no
`worksheet-mode`, no `examples/`, no `config.e`, no chezmacs tree
edit.

Identity is `(chezmacs-mpl, 000)`, spoken **chezmacs-mpl 000**.

The implementer receives only this document. Every rule for this
slice is below. Do not implement 001. Do not open
`lib/worksheet-mode.sls`, `examples/mpl.ws`, or `config.e`. Do not
edit `/home/dharmatech/src/e`.

## Goal

Add `(worksheet-env)`: a Chez-only library that builds a private
mutable top level from a list of import-specs, parses leading
`(import …)` forms as that spec (not as expressions), and evaluates
the remaining datums in that environment.

Green when, from
`/home/dharmatech/journal/2026-09-21-chezmacs-mpl`:

```sh
scheme --script tests/worksheet-env.ss
```

exits `0` and the checks in **Tests** all pass. `uv` is wrong; this
is Scheme. No TTY. Do not launch chezmacs.

This is layer 1 only. It is not a chezmacs module. It has no `init!`.
It does not register a mode, bind `C-x C-e`, or write a sample
worksheet.

## Authority and starting point

- [`spec.md`](../spec.md) is the design this slice was cut from.
  This checkpoint is the implementer assignment; copy the rules
  here, do not send the implementer back to the spec for behavior.
- Chez 10.4.1 (`scheme` / `scheme-script`) owns `environment`,
  `copy-environment`, `eval`, `read`, `environment-symbols`,
  `library-directories`, and `compile-imported-libraries`.
- `/home/dharmatech/src/mpl` is a **sample library** used by tests.
  `/home/dharmatech/src/surfage` and `/home/dharmatech/src/dharmalab`
  sit beside it. Do not copy those trees. Do not change them.
- Git `5150522` specified an MPL-only `(mpl-env)` with auto-`vars`.
  Do not implement that round.

`(import …)` is syntax only at a program, library, or the
interaction environment. Chez will not `eval` an `(import …)` form
into a copied environment. Building a worksheet environment by
evaluating `import` there is wrong.

## Exact file scope

**Create:**

- `lib/worksheet-env.sls`
- `tests/worksheet-env.ss`

**May update:**

- [`README.md`](../README.md) status lines only (000 implemented or
  not). Do not rewrite the pipeline, charter, or spec.

**Do not edit:**

- `spec.md`, `charter.md`
- `lib/worksheet-mode.sls` (must not exist after 000)
- `examples/` (must not exist after 000)
- `/home/dharmatech/src/e` (any path)
- `/home/dharmatech/src/mpl`, `/home/dharmatech/src/surfage`,
  `/home/dharmatech/src/dharmalab`, or any other collection under
  `/home/dharmatech/src`
- chezmacs `config.e`, `config.template.e`, or `main.sls`

Do not vendor MPL, Surfage, or Dharmalab into this tree. Do not
compile into `/home/dharmatech/src`. Object files go in this
journal's `eo/` (already present from an earlier round; reuse it).
Do not require chezmacs's `eo/client`.

Use `(library …)`, not chezmacs `elibrary`. This tree is not under
chezmacs's elinter.

## Paths and compilation

Hard-code these paths (personal experiment on this host):

| Role | Path |
|---|---|
| Journal root | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl` |
| Extension library root | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl/lib` |
| Object cache | `/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo` |
| Third-party R6RS root | `/home/dharmatech/src` |

`(library-directories)` must include `/home/dharmatech/src` so
`(mpl all)` maps to `/home/dharmatech/src/mpl/all.sls`,
`(surfage …)` to `/home/dharmatech/src/surfage/…`, `(dharmalab …)`
to `/home/dharmatech/src/dharmalab/…`, and any other collection
dropped in `/home/dharmatech/src` the same way. Adding
`/home/dharmatech/src/mpl` as a root is wrong (`mpl/mpl/all.sls`).
This path is where this machine keeps R6RS libraries, not an MPL
special case.

`prepare-library-directories!` is idempotent:

1. `(compile-imported-libraries #t)`
2. Create `eo/` if it does not exist.
3. If `/home/dharmatech/src` is not already a `library-directories`
   source, prepend `(cons src eo)`.
4. If the journal `lib/` is not already a source, prepend
   `(cons lib eo)` so it is searched first.

Prepending `lib/` last makes it the first root. `assoc` on the
source path is enough to decide whether a root is already present.

The test script must perform the same `lib/` + `src/` prepend
**before** it can import `(worksheet-env)`, because a top-level
`(import (worksheet-env))` would be resolved too early. See
**Tests**.

## Library

**File.** `lib/worksheet-env.sls`  
**Library name.** `(worksheet-env)`  
**Imports.** `(chezscheme)` only.

Do **not** use `(mpl-env)`, `(mpl env)`, `(mpl-mode)`, or
`(mpl mode)`. The last two would resolve under
`/home/dharmatech/src/mpl/`.

`(worksheet-env)` itself must not `(import (mpl all))` or any other
third-party collection at library level. Loading this library must
not rebind `+` in the test script or in chezmacs's later interaction
environment.

Do not export `init!`. Do not import any chezmacs library.

### Exports

Export **exactly**:

| Export | Meaning |
|---|---|
| `src-root` | `"/home/dharmatech/src"` |
| `object-directory` | `"/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo"` |
| `prepare-library-directories!` | idempotent path setup above |
| `default-import-specs` | `'((rnrs))` |
| `read-forms` | `string → list` of datums |
| `parse-worksheet` | `string → (values import-specs remaining-forms)` |
| `make-worksheet-environment` | `import-specs →` mutable env; clash check; no `vars` |
| `eval-forms` | `forms env →` values of the last form |
| `eval-program` | `string env →` values of the last remaining form |

Do not export a chezmacs buffer object, a weak table, a clash-check
helper, or anything that imports chezmacs.

`parse-worksheet` applies the default import-spec rule below.
`remaining-forms` is the list after stripping leading `import`
datums (possibly empty).

## Environment construction

Chez `(environment spec …)` silently merges overlapping names. A
worksheet must not. Construction is:

```scheme
(prepare-library-directories!)

(assert-no-variable-clashes! import-specs)   ; private; not an export

(define env
  (copy-environment
    (apply environment import-specs)
    #t))
```

`import-specs` is a list of Chez import-spec datums. The default,
when the file has no leading `import`, is `'((rnrs))` —
`default-import-specs`. `make-worksheet-environment` receives the
list the caller already chose; it does not re-parse a file.

`(copy-environment … #t)` is mutable: `define` and any macros the
imported libraries export (including MPL `vars` when imported)
persist in that copy until it is discarded.

`(eval '(import …) env)` must not be how the environment is built.
Evaluating an `import` form in the copy raises (Chez treats it as a
procedure call; `import` is not syntax there).

There is **no auto-`vars`**. Construction must succeed for
`((rnrs))` without `vars` existing. If a file needs MPL free
variables, it writes `(vars …)` itself as worksheet code. Do not
install an unbound-identifier handler that self-quotes unknown
symbols.

An empty spec list (`'()`) is not a clash:
`(apply environment '())` is the empty environment. Construction
succeeds; almost every evaluation in that environment then fails.
`(import)` with no operands is that empty list, not the default.

## Conflicting exports

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

`eval` of a syntax-only name raises; treat that as "not a variable
in this spec." `eval` of `+` succeeds and returns a procedure.
Do not treat a successful `eval` whose value is `#f` as failure.

Do **not** weaken this rule so that `(rnrs)` together with
`(chezscheme)` succeeds. On this Chez those libraries have dozens
of shared names that are not `eq?`, and a library-level
`(import (rnrs) (chezscheme))` already raises. A Chez worksheet is
`(import (chezscheme))` **alone**. `(import (rnrs))` alone is the
default. Both together is a construction error. A single
`(import (chezscheme))` succeeds (no self-clash).

Required outcomes via `make-worksheet-environment` (not `(+ 1 2)`
as a proxy):

| Import specs | Construction |
|---|---|
| `((rnrs) (mpl all))` | raise (`+` `-` `*` `/` `sqrt` at least) |
| `((mpl rnrs-sans) (mpl all))` | succeed |
| `((rnrs) (rnrs))` | succeed |
| `((rnrs) (prefix (mpl all) mpl:))` | succeed |
| `((chezscheme))` | succeed |
| `((rnrs) (chezscheme))` | raise |

`(+ 1 2)` is not a clash test: MPL `+` on numbers is still `3`.

The exception type and message are not API. Tests only require that
construction raises, not a particular condition or name list in the
message. The implementation must still discover clashes from
`environment-symbols` + `eval` + `eq?`, not from a baked-in set of
identifiers.

## Leading `import` is environment spec, not eval

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
directives follow Chez). Use a string input port. Do not write a
second reader.

Consecutive **leading** datums that are pairs whose `car` is the
symbol `import` are the environment spec: the concatenation of each
form's operands (the `cdr`) is the import-spec list passed to
`environment`. Those forms are not evaluated.

- Zero leading `import` forms: use `default-import-specs`
  (`'((rnrs))`).
- One or more leading `import` forms: use those specs **instead of**
  the default, not in addition to it. `(import)` with no operands is
  an empty spec list.
- An `import` that is not a leading prefix (a form after a
  definition or expression) is not environment spec. Evaluating it
  is an error.

`only` / `prefix` / `rename` / `except` import-specs are allowed
because `environment` accepts them. This project does not invent a
restricted import language.

`read-forms` reads every datum from a string until eof.

`eval-forms` evaluates those datums in order in the given
environment with Chez `eval`. It does **not** strip `import`. The
values of the last datum are the result (including multiple values).
An empty list of forms returns zero values. Definitions and effects
from earlier datums remain in the environment.

`eval-program` parses a whole-buffer string, drops leading `import`
forms, and `eval-forms` the rest in the given environment. It does
not rebuild the environment; the caller passes the environment that
already matches the header.

Evaluating a region that is only `(+ x x)` still uses the buffer
environment, which was built from the **file** header (or from
`(rnrs)` if there is no header), not from the region. `eval-forms`
is that region path; it must not treat a region's leading `import`
as environment spec.

## Goldens

These were checked against `/home/dharmatech/src/mpl` with an
environment built from `'((mpl rnrs-sans) (mpl all))` and
`(vars a b c d x y z pi t)` evaluated **in that environment**, not
as a library default. Tests must include them as `equal?` checks
after that setup, not weaker substitutes.

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

## Tests

**File.** `tests/worksheet-env.ss`  
**Run.** from the journal root:

```sh
scheme --script tests/worksheet-env.ss
```

Exit `0` on success, nonzero on failure. Do not launch chezmacs.
Do not require a TTY. No test framework beyond this script.

The script may only `(import (chezscheme))` at the file top. It must
create `eo/` if needed, set `(compile-imported-libraries #t)`, and
prepend `lib/` and `src/` with object directory `eo/` **before**
importing `(worksheet-env)` — `prepare-library-directories!` also
mkdir's, but it runs after that import. Then `eval`
`(import (worksheet-env))` into its interaction environment, then
call `prepare-library-directories!`.

Prepend order matches the library: cons the `src/` pair first, then
the `lib/` pair, so `lib/` is searched first.

It must **not** import `(mpl all)` into the interaction environment.

Required checks:

1. Default `(rnrs)` environment from `make-worksheet-environment` of
   `default-import-specs`: `(eval '(+ 1 2) env)` ⇒ `3`; `(eval 'x
   env)` raises; `(eval 'vars env)` raises; `(eval 'alge env)`
   raises.
2. All MPL goldens above in an environment built from
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
10. Clash table above, via `make-worksheet-environment` (not
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

Compare MPL results with `equal?`. Compare import-spec lists with
`equal?` (do not require `eq?` with `default-import-specs`).

An extra check that `make-worksheet-environment` of `'()` succeeds
is allowed; it is specified behavior. Do not treat it as a
substitute for any numbered check.

If MPL, Surfage, or Dharmalab is missing from `/home/dharmatech/src`,
that is a predecessor failure. Do not stub the goldens.

## Acceptance

Wrong unless all of these are true:

1. `scheme --script tests/worksheet-env.ss` from the journal root
   exits `0` and covers the twelve checks.
2. A worksheet-shaped string that begins with
   `(import (mpl rnrs-sans) (mpl all))`, then `(vars x y)`, then
   `(+ x x)` evaluates `(+ x x)` to `(* 2 x)` with no `mpl:` prefix.
3. After those private environments exist,
   `(eval '(+ 1 2) (interaction-environment))` is still `3`.
4. Default `(rnrs)`: `(+ 1 2)` is `3`, `x` / `vars` / `alge` are
   not defined. No auto-`vars`.
5. Two `make-worksheet-environment` results do not share
   definitions.
6. Leading `import` is environment spec, not `eval`. A non-leading
   `import` raises from `eval-program`.
7. The clash table holds, including `((rnrs) (chezscheme))` raises
   and `((chezscheme))` succeeds.
8. No chezmacs module, no `config.e` change, no sample `.ws` file,
   no edit under `/home/dharmatech/src/e`.

## Non-goals (this slice)

- `lib/worksheet-mode.sls`, mode `"worksheet"`, keymap `'worksheet`
- `examples/mpl.ws`
- The `config.e` snippet
- Binding `C-x C-e` or duplicating chezmacs `eval:run!`
- Inserting `; => (* 2 x)` or a result line under point
- Auto-`vars`, mode name `"mpl"`, default import of MPL
- Prefixing identifiers (`mpl:+`)
- Importing worksheet libraries into `(interaction-environment)`
- `kernel:load-module!` of anything
- Editing `/home/dharmatech/src/e`
- Fingerprint / daemon / wire changes
- Hot-reload of `/home/dharmatech/src/mpl` (or other `~/src`
  libraries) when those files are saved
- Sharing one env across heads or across buffers (no buffer table
  in 000)
- Evaluating inside `(library …)` forms as if they were a REPL
- Changing MPL, Surfage, or Dharmalab
- Windows / non-Chez Scheme
- Unbound-identifier self-quoting
- A later seam in chezmacs `eval.sls`

chezmacs-mpl 001 (mode, `C-x C-e`, sample file, `config.e`) is a
later checkpoint, after this one is implemented and reviewed. Do
not write it. Do not implement it here.
