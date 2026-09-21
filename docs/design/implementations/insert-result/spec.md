# Specification — insert worksheet results

**Status.** Design for the local **chezmacs-mpl** project. This is not
chezmacs upstream, a checkpoint, or an implementer assignment. A later
checkpoint-manager conversation writes the single **insert-result 000**
checkpoint under [`checkpoints/`](checkpoints/). That conversation will not
have [`charter.md`](charter.md); this file is the law.

The editor's checkout and command remain `e` (`/home/dharmatech/src/e`). This
project calls the editor **chezmacs**. The implemented worksheet layer in
[`../worksheet/`](../worksheet/) is a predecessor and remains authoritative
for environment construction, `C-x C-e`, output capture, and reporting.

This feature adds a second worksheet command. With point immediately after a
complete Scheme form, `C-c C-c` evaluates that form in the current buffer's
existing worksheet environment and puts its non-void value on the following
line as a Scheme comment:

```scheme
(+ x x)
; => (* 2 x)
```

Re-running replaces that result line. `C-x C-e` remains region-or-buffer,
echo-only evaluation. `M-x` remains editor evaluation.

## 1. Resolved choices

These close the charter's open questions. Do not reopen them.

| Question | Choice |
|---|---|
| Printed shape | Exactly one physical result line. Format each returned value with Chez `~s`, join multiple values with `", "`, replace each maximal CR/LF run in the joined text with one ASCII space, then prefix `; => `. |
| Blank next line | Reuse it. A next line containing only whitespace is replaced by the result, so no blank remains between the form and result. |
| Test script | `tests/insert-result.ss`, run from the journal root with `scheme --script tests/insert-result.ss`. |
| Slice | One checkpoint only: **insert-result 000**, containing helpers, command, binding, automated tests, and the named hand check. |
| Source layers | Extend `(worksheet-env)` with pure string/outcome helpers and extend `(worksheet-mode)` with the command. Do not add a third library or another loaded module. |

The one-line choice means replacement always concerns exactly one buffer line;
there is no continuation-comment syntax to recognize or maintain.

## 2. Acceptance bar

The implementation is wrong unless all of these are true:

1. In `examples/mpl.ws`, after its MPL imports and `(vars ...)` have run,
   point immediately after `(+ x x)` plus `C-c C-c` produces exactly
   `; => (* 2 x)` on the next line.
2. The command evaluates the last complete datum whose source end is at or
   before point. It ignores the mark. A datum containing point is not complete
   for this purpose; the preceding complete datum wins.
3. Evaluation uses `environment-for` and therefore the same per-buffer mutable
   environment as worksheet `run!`. It does not construct a second environment
   table, import MPL globally, or load MPL as a chezmacs module.
4. A following result line, recognized by optional whitespace then `; =>`, is
   replaced rather than stacked. A following whitespace-only line is reused.
5. A non-void successful outcome is both echoed as today and inserted as a
   comment. Zero values and one `#<void>` are echoed as `#<void>` and do not
   change the buffer. Errors and interrupts are echoed and do not insert or
   replace anything.
6. The insertion or replacement is one undo step, grouped with
   `edit:call-as-one-edit!`. After a successful edit, point is at the exclusive
   source end of the evaluated form, so the same key targets the same form.
7. Result comments remain ordinary Scheme comments. Whole-buffer `C-x C-e`
   can still `read` and evaluate a worksheet containing them.
8. `C-x C-e`, `worksheet-mode:run!`, and `M-x` retain their implemented
   meanings. The new binding is only `C-c C-c` in keymap context
   `'worksheet`. Scheme-mode and the global map are unchanged.
9. `scheme --script tests/worksheet-env.ss` and
   `scheme --script tests/insert-result.ss` both exit 0. The new script needs
   neither a TTY nor a running chezmacs.
10. No file under `/home/dharmatech/src/e` is edited.

## 3. Project boundary

The only implementation files in scope are:

```text
lib/worksheet-env.sls       add pure, Chez-script-testable helpers
lib/worksheet-mode.sls      add insert-last!, binding, and documentation
tests/insert-result.ss      new Chez-script
```

`examples/mpl.ws` is the hand-check input and must not gain committed result
comments. The installation's `config.e` already loads `"worksheet-mode"`; do
not add or change a `kernel:load-module!` form. Do not edit the predecessor
worksheet specification or create a worksheet 002.

## 4. Pure layer — additions to `(worksheet-env)`

`lib/worksheet-env.sls` continues to import only `(chezscheme)`. Add the five
exports below. They do not know about buffers, heads, marks, keymaps, or undo.

| Export | Contract |
|---|---|
| `position->index` | `(text (row . col)) -> exact character index` (§4.1) |
| `index->position` | `(text index) -> (row . col)` (§4.1) |
| `last-complete-datum-at` | `(text limit) -> (values found? datum end-index)` (§4.2) |
| `render-result-comment` | `outcome -> string or #f` (§4.3) |
| `splice-result-comment` | `(text form-end comment-or-#f) -> (values new-text edit-start edit-end replacement)` (§4.4) |

Here an **outcome** has the representation already used internally by
`(worksheet-mode)`: a successful evaluation is a list of its returned values;
an error or interrupt is a string. An edit start/end is a character index, end
exclusive. When there is no edit, all three edit-plan values are `#f`.

### 4.1 Positions and character indexes

`head:point` is zero-based `(row . col)`. `edit:buffer-text` represents rows
with one `#\newline` character between them and includes a final newline when
the buffer keeps one.

For a valid editor position `(r . c)`, `position->index` returns:

```text
c + sum over rows before r of (row character length + 1)
```

The `+ 1` counts the joining newline. Columns, lengths, Chez string-port
positions, and these indexes are character counts, not UTF-8 byte counts.
Reject a negative or out-of-range row/column rather than silently clamping it.

`index->position` is the inverse scan: every newline before `index` increments
the row and resets the column, and every other character increments the
column. Accept indexes from zero through the string length. The command only
turns indexes that denote real buffer positions into editor positions; in
particular its edit plan never relies on the phantom empty row after a terminal
newline.

Required round trips include the start, the end of a row, a later row, and
non-ASCII text.

### 4.2 Last complete datum

`last-complete-datum-at` validates `0 <= limit <= (string-length text)`, opens
an input string port on the **whole** text, and repeatedly calls Chez `read`.
After each successful datum, `(port-position in)` is its exclusive source end.
Keep the most recent datum whose end is `<= limit`. Return it as
`(values #t datum end)`; return `(values #f #f #f)` when none qualifies.

Important details:

- Do not read only `(substring text 0 limit)`. A prefix ending in the middle of
  an identifier can itself look like a complete symbol. Reading the whole text
  lets the datum's real end prove whether it is before point.
- Comments and whitespace are skipped by `read`; they are not datums. If point
  is in whitespace or a comment, the preceding datum remains eligible.
- As soon as a successful datum ends after `limit`, return the saved datum.
- EOF returns the saved datum. A reader exception also returns the saved datum;
  this is what lets point in a partial or malformed later form select the
  preceding complete one. Do not evaluate anything in this helper.
- A datum ending exactly at point is eligible. The returned `datum` may itself
  be `#f`, which is why `found?` is separate.

Source end, not the start of trailing whitespace, controls both selection and
where point is restored.

### 4.3 Result rendering

`render-result-comment` maps an outcome as follows:

1. An error/interrupt string returns `#f`.
2. An empty successful value list returns `#f`.
3. A one-element successful list whose value is `(void)` returns `#f`.
4. Otherwise, format every value with `(format "~s" value)`, join the strings
   with `", "`, replace every maximal nonempty run of `#\return` and
   `#\newline` characters with one ordinary space, and prefix `"; => "`.

Do not pretty-print, truncate, insert bare data, or spread a result over
multiple comment lines. Multiple values containing `#<void>` are not the
single-void case and are rendered normally.

Examples:

```scheme
(render-result-comment (list '(* 2 x)))  => "; => (* 2 x)"
(render-result-comment (list 1 2))        => "; => 1, 2"
(render-result-comment '())               => #f
(render-result-comment (list (void)))     => #f
(render-result-comment "error: unbound") => #f
```

A value with a custom writer that emits `"a\nb"` renders as `"; => a b"`.
This test makes the chosen newline policy observable; a Scheme string value is
not enough because `~s` escapes its newline.

### 4.4 Splicing one result line

`splice-result-comment` is both the string oracle for tests and the source of
the local buffer edit plan. With `comment-or-#f` equal to `#f`, it returns the
original text and three `#f` plan values. This is the mandatory no-write path
for void, errors, and interrupts.

Otherwise the comment is the canonical one-line string from §4.3. Find the
line containing the character immediately before `form-end` (the datum's
exclusive end), then the line immediately following it. Preserve all text on
the form's line, including spaces or a trailing source comment.

Apply exactly one of these cases:

1. **Following result line.** If the next real line's first non-whitespace
   characters are `; =>`, replace that line's entire content with the canonical
   comment. Do not replace its newline.
2. **Following blank line.** If the next real line contains only whitespace,
   replace its entire content with the comment. Do not leave the blank between
   form and result.
3. **Following other content.** Insert `comment` plus `"\n"` at the start of
   that next line, pushing the old line down.
4. **No next real line.** Insert `"\n"` plus `comment` at the end of the form's
   physical line. If the original text had a terminal newline, insert before
   that newline so the result also has a terminal newline. If it did not, do
   not add one after the result.

For each edit, return the transformed full string plus the exact
`[edit-start, edit-end)` indexes and replacement string that produce it. A
zero-width span represents insertion. The implementation must satisfy:

```text
new-text = text[0:edit-start] + replacement + text[edit-end:]
```

Whitespace for result recognition and blank-line recognition is the
line-local Chez `char-whitespace?` predicate. A replaced indented result becomes
the canonical unindented `; => ...` line. Only that one line is replaced.

The required edge cases preserve whether the input had a terminal newline:

```text
"(+ x x)"   -> "(+ x x)\n; => (* 2 x)"
"(+ x x)\n" -> "(+ x x)\n; => (* 2 x)\n"
```

## 5. Chezmacs layer — additions to `(worksheet-mode)`

### 5.1 Export and command identity

`lib/worksheet-mode.sls` exports `init!`, `run!`, and `insert-last!`.
After module prefixing the new M-x name is
`worksheet-mode:insert-last!`.

Do not create another persistent cell. `insert-last!` calls the existing
`environment-for` with the current buffer and the import specs returned by
`parse-worksheet` on the whole current buffer. Header changes therefore rebuild
the same environment exactly as `run!` already does; otherwise definitions
made by either command are visible to the other.

### 5.2 Evaluation and reporting reuse

Refactor the existing private evaluation/capture code only as needed to let
both commands use it. Preserve all worksheet behavior from the predecessor
specification:

- `head:call-with-interrupt` and the strings `"interrupted"` and
  `"error: "` plus `kernel:condition-text`;
- stdout/stderr capture through `sys:call-with-streamed-output`, the duplicated
  terminal port, mutex, and `'stdout` / `'stderr` log components;
- successful values represented as a list, including all multiple values;
- `edit:set-message!` reporting with `~s` and `", "`;
- `#<void>` reporting for zero values or one void;
- optional kill-ring copy of the joined non-void result when
  `eval:copy-result` is true;
- no `'eval` log record and therefore no pollution of M-x history.

`run!` keeps its exact region-else-whole-buffer selection and remains bound to
`C-x C-e`. It must not begin inserting results as a side effect of this
refactor.

### 5.3 `insert-last!` algorithm

The command acts on the current buffer and does not inspect or deactivate the
mark.

1. Save the current buffer, its `edit:buffer-text`, and `head:point`. Convert
   point with `position->index`.
2. Call `last-complete-datum-at` on that whole text and index. If it reports no
   datum, echo `"No complete form before point"`, make no edit, and return
   `(void)`.
3. If the datum is a pair whose car is the symbol `import`, echo
   `"error: import is worksheet environment syntax"`, make no edit, and return
   `(void)`. Leading imports configure `parse-worksheet`; an import datum is
   never evaluated as an expression.
4. Parse the whole buffer text for import specs, obtain the existing
   `environment-for` that buffer/spec pair, and evaluate **only the selected
   datum** with Chez `eval` in that environment. Do not call `eval-program`,
   evaluate the text prefix, or replay earlier forms.
5. Capture the outcome through §5.2 and report it in the echo area exactly as
   `run!` does. An error or interrupt stops here. A zero-value or single-void
   success stops here. None of these paths calls a text-edit procedure.
6. For a non-void success, pass the captured value list to
   `render-result-comment`, then call `splice-result-comment` with the original
   buffer text and selected datum's end index. Convert its edit indexes with
   `index->position` and perform that one local edit with
   `edit:replace-region-text!`; a zero-width region is an insertion.
7. Enclose evaluation and the possible local edit in
   `(edit:call-as-one-edit! "(worksheet-mode:insert-last!)" ...)`. Nested edits
   caused by evaluated code remain under the command's outer group. The normal
   result insertion/replacement is consequently one undo step.
8. After the successful buffer edit, call
   `edit:set-point-without-scroll!` with the position converted from the saved
   datum-end index. The result edit is strictly on a later line, so that
   position still denotes the datum end. This is true even if the invoking
   point was later in whitespace or a comment.

The command does not evaluate an incomplete form, use the active region, skip
blank lines, or scan backward with parenthesis heuristics. The reader and
source positions in §4.2 define its target.

### 5.4 Registration

Keep the implemented worksheet mode registration and its existing `C-x C-e`
binding. In `init!`, add:

```scheme
(keymap:bind-default! 'worksheet "C-c C-c" insert-last!)
```

Use `bind-default!`, not `bind!`, so a user's context binding may replace the
suggestion. Do not add a global or scheme-mode binding.

Add a `doc:register!` entry for `worksheet-mode:insert-last!`. Its description
must say that it evaluates the last complete form at or before point in the
buffer's worksheet environment, inserts or replaces a following `; =>`
comment for a non-void success, ignores the mark, and leaves errors/void out of
the file. Keep the existing `worksheet-mode:run!` entry.

## 6. Automated verification

### 6.1 Predecessor

From the journal root, this must remain green:

```sh
scheme --script tests/worksheet-env.ss
```

### 6.2 Insert-result Chez-script

**File:** `tests/insert-result.ss`

**Run:**

```sh
scheme --script tests/insert-result.ss
```

Like the predecessor script, it imports only `(chezscheme)` at file top,
creates `eo/` if necessary, installs the journal `lib/` and `/home/dharmatech/src`
library directories before importing `(worksheet-env)` through `eval`, and
does not import MPL into the interaction environment.

Required checks:

1. `position->index` / `index->position` round trips at `(0 . 0)`, a line end,
   a later row/column, and in text containing a non-ASCII character.
2. `last-complete-datum-at` selects a form when point is immediately after its
   closing `)`, selects the preceding form when point is in the middle of a
   later list, and also selects the preceding form when point is in the middle
   of a later identifier token. The token case proves the helper did not read
   only a truncated prefix.
3. Before any complete datum it reports none. In or after a line comment it
   selects the preceding complete datum. A partial/malformed later datum does
   not erase the preceding complete datum.
4. With two separate leading `(import ...)` forms followed by `(vars x)` and
   `(+ x x)`, an index after `(+ x x)` selects `(+ x x)`, not either import.
5. `render-result-comment` renders `(* 2 x)` exactly as
   `"; => (* 2 x)"`, renders multiple values with `", "`, and renders `#f` as
   `"; => #f"` rather than confusing it with no result.
6. A test-only record writer that emits a CR/LF-containing representation
   proves the result has one physical line and each maximal line-break run
   becomes one space.
7. Splicing before a nonblank next line inserts the result. Splicing the
   resulting string again replaces the same line and leaves exactly one
   `; =>` line. An indented old result is recognized and canonicalized.
8. A whitespace-only next line is replaced rather than skipped. Both final
   cases in §4.4 preserve terminal-newline style.
9. For every splice case, applying the returned local edit plan independently
   reproduces the returned full string.
10. Evaluate `(define k 1)` in a default worksheet environment, capture its
    void outcome, and prove `render-result-comment` returns `#f` and splicing
    leaves an existing good result line unchanged. Catch an evaluation error
    as the same failure-string shape used by the mode and prove the same. Thus
    void/error paths neither insert nor replace result text.
11. MPL golden: read `examples/mpl.ws`, obtain specs with `parse-worksheet`,
    create the worksheet environment, evaluate its `(vars ...)` form, locate
    the `(+ x x)` datum at the source index immediately after it, evaluate that
    selected datum, and compare the value with the datum `(* 2 x)` using
    `equal?`. Then compare the rendered comment exactly with
    `"; => (* 2 x)"` and the spliced text exactly at the following-line slot.
    Do not weaken this to a substring-only value check.

The script tests pure selection, rendering, and splicing. It does not launch
chezmacs or try to inspect the head-local weak environment table.

## 7. Named hand check in chezmacs

After the already-installed `config.e` snippet has loaded
`"worksheet-mode"` in a head:

1. Open `examples/mpl.ws`; verify its mode is `"worksheet"` and that the file
   has no committed result lines.
2. With mark inactive, run whole-buffer `C-x C-e` once so the sample's
   `(vars ...)` and other forms execute in the buffer environment.
3. Put point immediately after `(+ x x)` and press `C-c C-c`. The next line is
   exactly `; => (* 2 x)`, the echo contains `(* 2 x)`, and point remains after
   the source form.
4. Press `C-c C-c` again. There is still exactly one result line. Undo once;
   the second replacement is one undo step. Redo or invoke again as needed,
   then change the result text by hand and verify one invocation replaces it
   in one undo step.
5. Put a blank line immediately below `(+ x x)` and invoke the command; the
   result occupies that line rather than appearing below it.
6. Put point after `(vars a b c d x y z pi t)` and invoke the command. It echoes
   `#<void>` and does not add or replace a result line. Invoke on an erroneous
   form and verify the error echoes while any prior good result remains.
7. Put point immediately after the leading `(import ...)` form and invoke. It
   echoes the import-specific error and does not edit the file.
8. Activate a region elsewhere, return point after `(+ x x)`, and invoke
   `C-c C-c`; the region is ignored and `(+ x x)` is evaluated.
9. `M-x (+ 1 2)` is still `3`. Worksheet `C-x C-e` still evaluates region else
   whole buffer without inserting. In a Scheme buffer, global `C-x C-e` is
   still `eval:run!`, and `C-c C-c` has not been stolen.
10. Remove hand-check result comments before committing `examples/mpl.ws`.

Do not block this specification on a TTY automation harness.

## 8. Slice for the checkpoint manager

Write one checkpoint only:

**insert-result 000 — last form to comment.** Extend `(worksheet-env)` with
§4, extend `(worksheet-mode)` with §5, add `tests/insert-result.ss`, keep the
predecessor tests green, and perform/report §7. It is complete only when the
pure tests, environment reuse, worksheet-only binding, one-step edit, and hand
check all agree.

Do not create insert-result 001 or 002 unless implementation reveals a genuine
context-size blocker and the human approves a new slice. Do not write any
checkpoint during the design conversation.

## 9. Non-goals

- Changing worksheet `run!` or the meaning of `C-x C-e`
- Notebook cells, result cells, HTML, images, or Org-babel blocks
- Multi-line pretty-printed result blocks
- Inserting bare Scheme data rather than comments
- Evaluating the current line, the active region, or an unfinished form
- Auto-`vars`, default MPL imports, or MPL in the interaction environment
- A second evaluation environment or environment table
- Sharing environments across buffers or heads
- A new module stem or `config.e` loader entry
- Patching chezmacs, `eval.sls`, MPL, Surfage, or Dharmalab
- Committing generated `; =>` lines to `examples/mpl.ws`
- Windows or non-Chez Scheme
