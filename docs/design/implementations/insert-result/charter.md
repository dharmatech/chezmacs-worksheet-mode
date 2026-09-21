# Charter — insert worksheet results

**Status.** Handoff from the high-level discussion in Grok (journal
`2026-09-21-chezmacs-mpl`) into a **design conversation**. Not
chezmacs upstream. Not a checkpoint. Not an implementer assignment.
Specification will live beside this file as [`spec.md`](spec.md).
Parent map: [`README.md`](README.md). Design map:
[`../../README.md`](../../README.md). Worksheet
predecessor: [`../worksheet/`](../worksheet/).

The editor's checkout and command are still `e`
(`/home/dharmatech/src/e`). This project calls the editor
**chezmacs**.

This is a **new** implementation folder. Do not add a 002 to
[`../worksheet/`](../worksheet/). That series is closed. Do not
amend [`../worksheet/spec.md`](../worksheet/spec.md) as if this
feature had been in scope there.

**Your job.** Turn this charter into a specification for inserting
the value of the last complete Scheme form before point into the
same worksheet buffer, as a `; =>` comment on the following line.
Reuse the worksheet environment from `(worksheet-env)` /
`(worksheet-mode)`. Then **stop**. Do not write checkpoints. Do not
implement. Do not specify a notebook UI, Org-babel blocks, or
changes to chezmacs's kernel.

If you have been told to read this file, this is the whole assignment.

---

## 1. How this conversation works

1. Read this charter, [`README.md`](README.md),
   [`../worksheet/README.md`](../worksheet/README.md), and the
   authority in §5. Inspect the running extension at the journal
   root. Do not rely on the Grok transcript; this file is the
   assignment.
2. Record the locked decisions in §4. Resolve the open questions in
   §4.7–§4.9.
3. Write `spec.md` in this folder. A later checkpoint-manager
   conversation slices **insert-result 000**, and further numbers
   only if the spec cannot fit in one checkpoint, under
   `checkpoints/` in this same directory.
4. Stop. The human reviews it. Do not write those checkpoint files.

The checkpoint manager and implementers will not have this charter.
Put every rule they need in the specification.

Keep the spec **small enough to slice**. Prefer **one** checkpoint.
A CAS notebook, result cells, HTML, or a second evaluation
environment are defects in this document.

## 2. Predecessors (do not start without these)

| What | Ready when |
|---|---|
| Worksheet 000–001 | [`../worksheet/`](../worksheet/) implemented. `scheme --script tests/worksheet-env.ss` from the journal root exits 0. `lib/worksheet-mode.sls` is loaded from `config.e` as `"worksheet-mode"`. |
| chezmacs | `/home/dharmatech/src/e` runs. `head:point` is `(row . col)`. `edit:insert-text!`, `edit:replace-region-text!`, `edit:call-as-one-edit!`, `edit:buffer-text` exist. |
| Sample | `examples/mpl.ws` at the journal root |

No chezmacs tree edit is a predecessor. Default: **do not edit**
`/home/dharmatech/src/e/lib/**`.

## 3. Bar (acceptance)

The specification is wrong unless all of these are true:

1. **Last form before point.** With point immediately after
   `(+ x x)` in a worksheet that has imported MPL and run
   `(vars …)`, the insert command evaluates that form in the
   **buffer's** worksheet environment and writes the next line:

   ```scheme
   (+ x x)
   ; => (* 2 x)
   ```

2. **`C-x C-e` is unchanged.** Region, else whole buffer, echo
   only. This command is a different key and a different shape
   (last complete form, insert). `M-x (+ 1 2)` is still `3`.

3. **Results are comments.** The inserted text is a Scheme comment
   starting with `; => `, then the value printed as Chez `~s`
   (same as `worksheet-mode`'s non-void echo). Whole-buffer
   `C-x C-e` still `read`s the file as a program; result lines are
   not expressions.

4. **Re-run replaces.** If the line immediately after the form is
   already a result comment (`; =>` after optional whitespace),
   overwrite that result. Do not stack a second `; =>` line.

5. **Void and errors stay out of the file.** `define`, `vars`, and
   other void results insert nothing (echo as today is enough).
   Evaluation errors and interrupts echo; they do not insert and
   they do not replace a previous good result.

6. **First consumer is tests plus a hand check.** A Chez-script
   (no TTY, no chezmacs) covers last-form-at-index, comment
   rendering, replace-vs-insert on a string, and "void / error
   produce no result line." A named hand check in chezmacs: open
   `examples/mpl.ws`, point after `(+ x x)`, hit the key, see
   `; => (* 2 x)`, hit it again, still one result line; `M-x
   (+ 1 2)` is `3`.

7. **One undo step** for the buffer edit (`edit:call-as-one-edit!`).
   Point remains at the end of the evaluated form so the same key
   re-runs.

## 4. Locked decisions (record these; do not reopen 4.1–4.6)

### 4.1 Same environment as worksheet mode

Use `(worksheet-env)` and the existing per-buffer environment in
`(worksheet-mode)` (`environment-for` / the weak table). Do not
build a second env. Leading `(import …)` remains environment spec
via `parse-worksheet`. If the last complete form before point **is**
an `import` form, do not evaluate it as an expression: echo an
error, insert nothing.

Do not import MPL into `(interaction-environment)`. Do not
`kernel:load-module!` MPL.

### 4.2 Last complete datum at or before point

Not the whole buffer. Not "the current line" unless that line is
exactly one datum. Read datums from the start of `edit:buffer-text`
with Chez `read` (comments and whitespace skipped, same as
`read-forms`). The command's form is the last complete datum whose
source **end** is at or before the character index of `head:point`.

If point sits in the middle of a form, use the previous complete
datum, not the broken one. If there is no complete datum before
point, echo a short message and insert nothing.

`head:point` is `(row . col)`, 0-based. Convert through
`edit:buffer-text` (lines joined with newline; trailing newline
when the buffer keeps one). The spec must define that conversion
so tests can use a string plus an index without chezmacs.

This command **ignores the mark.** Region eval remains `C-x C-e`.

### 4.3 Where the result sits

The result occupies the line immediately after the **line on which
the form ends**.

```scheme
(algebraic-expand
  (alge "(x+1)^2"))
; => (+ 1 (* 2 x) (^ x 2))
```

A result line is a line whose first non-whitespace characters are
`; =>`. Replacement covers that one line (see §4.7 if pretty-print
needs more than one).

Do not skip blank lines: if the next line is empty, insert the
result there (replace the empty line) or put the result on that
next-line slot so the blank is not left between form and result.
Pick the smaller rule in the spec; tests must show it.

### 4.4 Command, key, module

Keep `(worksheet-mode)` as the chezmacs module. Add an exported
command (name it in the spec; `insert-last!` is the expected
shape). Bind it in keymap context `'worksheet` only.

**Key: `C-c C-c`.** Do not rebind `C-x C-e`. `M-x` remains
`eval:prompt!`. After the kernel prefixes the library, the command
is `worksheet-mode:insert-last!` (or the name the spec chooses) at
`M-x` as well.

`doc:register!` an entry. `init!` stays the load hook.

Do not add a second `kernel:load-module!` stem. `config.e` already
loads `"worksheet-mode"`; this project must not require a new
snippet unless the spec proves it must.

### 4.5 Code lives in this journal

Running code stays at the journal root:

```text
lib/worksheet-env.sls      may gain testable string helpers
lib/worksheet-mode.sls     command + key
tests/                     Chez-script(s)
examples/mpl.ws            hand-check file; do not fill it with
                           committed `; =>` lines
docs/design/implementations/insert-result/
  charter.md
  spec.md
  checkpoints/
```

Do not copy MPL. Do not edit `/home/dharmatech/src/e`. Do not add
the extension to chezmacs's bundled module list.

String algebra (index of last datum, render `; =>`, splice a
result into a text) must be callable from `scheme --script`
without chezmacs. Those helpers may live in `(worksheet-env)` or
a new `(worksheet-insert)` that imports only `(chezscheme)` and
`(worksheet-env)`. `(worksheet-mode)` performs the buffer edit.

### 4.6 Out of this layer

- Changing `C-x C-e` / `run!` meaning
- Notebook cells, HTML, images
- Inserting bare (non-comment) Scheme data as the result
- Auto-`vars` or MPL as default import
- Evaluating a form that has not yet ended
- Sharing environments across buffers
- Patching `eval.sls`
- Org-mode `#+RESULTS` blocks
- Stealing scheme-mode keys

### 4.7 Printed form of the value (resolve this)

Non-void success uses Chez `format` `~s` of each returned value,
joined the same way `worksheet-mode` already joins multiple
values (`", "`). Default lean: **one** result line. If the printed
text contains a newline, either flatten to one line or continue
with `;    ` on following lines that still count as "the result"
for replacement. Pick one; tests show it.

`#<void>` is not inserted (§3.5).

### 4.8 Tests (resolve this)

Name the Chez-script path and how it is run from the journal
root. Required cases:

- last complete datum at several indexes (after `)`, mid-form,
  before any form, after a comment)
- two leading `import`s are not the "last form" when point is
  after `(+ x x)`
- render `; => (* 2 x)`
- insert then replace on a string (still one result line)
- void / error paths produce no result text
- MPL golden: text of `examples/mpl.ws` (or a copy in the test),
  index after `(+ x x)`, environment via `parse-worksheet` +
  `make-worksheet-environment` + `vars`, value `(* 2 x)`

Hand check: §3.6. Do not block on a chezmacs TTY harness.

### 4.9 Slice (resolve this)

Prefer **insert-result 000** as the only checkpoint: helpers +
command + key + tests + hand check. Split only if that cannot
fit in one implementer context. There is no insert-result 002
unless 000 cannot include the chezmacs command.

## 5. Authority

- [`README.md`](README.md) — this project
- [`../../README.md`](../../README.md) — design map
- [`../worksheet/spec.md`](../worksheet/spec.md) — environment,
  `parse-worksheet`, `C-x C-e`; **not** a license to reopen it
- `lib/worksheet-env.sls`, `lib/worksheet-mode.sls`
- `examples/mpl.ws`
- `/home/dharmatech/src/e/lib/head/head.sls` — `point`,
  `current-buffer`, `call-with-interrupt`
- `/home/dharmatech/src/e/lib/head/edit.sls` — `buffer-text`,
  `insert-text!`, `replace-region-text!`, `call-as-one-edit!`,
  `set-message!`
- `/home/dharmatech/src/e/lib/head/keymap.sls` —
  `bind-default!` in context `'worksheet`
- `/home/dharmatech/src/e/manual/KEY_BINDING.md` — mode context
  before the global map
- Chez `read`, `format`, `port-position` / string ports as needed
  to locate datum ends

The worksheet charter's clash rules, default `(rnrs)`, and
no-auto-`vars` still hold. This project does not change them.

## 6. Non-goals

- A Maxima / Mathematica / Jupyter notebook
- Insert-below for scheme-mode buffers
- Rewriting `examples/mpl.ws` to contain results in git
- Changing MPL, Surfage, or Dharmalab
- Windows / non-Chez Scheme

## 7. Goldens

The value inserted for `(+ x x)` after MPL `import` and `vars` is
the same as worksheet 000:

```text
(+ x x)   ; => (* 2 x)
```

Other MPL goldens from the worksheet spec may appear in tests the
same way (evaluate the form, compare the value, then check the
comment spelling). Do not weaken `(* 2 x)` to a string-contains
check.
