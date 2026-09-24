# Worksheet mode for chezmacs

An extension for the [e](https://github.com/paveluv/e) text editor
(sometimes called **chezmacs**).

A **worksheet** is a Scheme program with its own top level, taken from
the file's leading `(import …)` forms. `C-x C-e` in that buffer uses
that environment. `M-x` stays the editor, with Chez `+`.

The file [`examples/mpl.ws`](examples/mpl.ws)
is a demo worksheet using the
[MPL](https://github.com/dharmatech/mpl) computer algebra library.

Files ending in `.ws` open in worksheet mode. `C-x C-e`
evaluates the selected region, or the whole buffer if there is no
region. `C-c C-c` evaluates the last complete form before point and
inserts the value on the next line as a `; =>` comment.

Example of loading it from e's `config.e`:

```scheme
(extension:load! "~/src/chezmacs-worksheet-mode" "worksheet-mode" '("~/src"))
```

Design notes: [`docs/design/`](docs/design/).

Video of worksheet mode in action:

https://youtu.be/PfXqDh_ueFw
