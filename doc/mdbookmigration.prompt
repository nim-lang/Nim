# Migrate an mdBook project to `nim book`

Convert a Markdown documentation book (currently built with mdBook) into a
`nim book` project. The book lives in a directory (call it `book/`) with a
`SUMMARY.md` at its root, and the API docs (generated from `.nim` source via
`nim doc --project --index:on`) live in a sibling `api/` directory that ends up
at `<outdir>/api/`.

## Context

`nim book` is a Nim compiler command that turns a directory of Nim-flavored
Markdown (`.md`) files into a static documentation site, using `SUMMARY.md` for
structure/navigation. It supports:

- `.. include::` with `:code:` (syntax-highlighted code inclusion),
  `:start-after:`/`:end-before:` (selective inclusion), and `:literal:` (plain).
- `.. admonition::` (and the shorthand `.. note::`, `.. warning::`,
  `.. important::`).
- `.. title::` for page titles.
- `.. importdoc::` + Pandoc-style references for cross-referencing Nim symbols.
- `.. image::` for images.

## Migration steps

### 1. Admonitions

Replace mdBook's fenced-code admonitions with RST directives:

- ` ```admonish warning` / ` ```admonition warning` → `.. warning::`
- ` ```admonish note` / ` ```admonition note` → `.. note::`
- ` ```admonish important` → `.. important::`
- ` ```admonish info` → `.. note::` (there is **no** `info` directive; map it
  to `note`)

Valid admonition directives in Nim's RST are: `admonition`, `attention`,
`caution`, `danger`, `error`, `hint`, `important`, `note`, `tip`, `warning`.
Map any mdBook admonition type not in this list to the closest valid one
(e.g. `info` → `note`).

The body text must be indented (3 spaces) under the directive. Remove the
surrounding ` ``` ` fences.

### 2. Code inclusion

Replace mdBook's `{{#include PATH}}` and `{{#shiftinclude auto:PATH:NAME}}` with
`.. include::`:

- Whole file: `{{#include PATH}}` or `{{#shiftinclude auto:PATH:all}}` →

  ```
  .. include:: PATH
     :code:
  ```

- Selective (named section): `{{#shiftinclude auto:PATH:NAME}}` →

  ```
  .. include:: PATH
     :start-after: #ANCHOR: NAME
     :end-before: #ANCHOR_END: NAME
     :code:
  ```

Notes:

- `:code:` gives Nim syntax highlighting (defaults to Nim; use `:code: <lang>`
  for other languages).
- The `#ANCHOR:` / `#ANCHOR_END:` markers must exist in the source `.nim`
  files. Normalize them to `#ANCHOR:` (no space after `#`) — a space after `#`
  is interpreted as a Markdown heading.
- Include paths are resolved **relative to each `.md` file's own directory**
  (not the book root). Adjust `../` counts accordingly.
- Remove the surrounding ` ```nim ` fences — `.. include::` is a block
  directive, not inline.

### 3. Remove mdBook artifacts

Remove any leftover mdBook-specific markup, in particular `<!-- toc -->`
comments (mdBook's table-of-contents placeholder). `nim book` generates its own
TOC from the document headings, so these placeholders are dead and should be
deleted.

### 4. Emphasis syntax

Replace underscore emphasis with asterisks: `_italic_` → `*italic*` (and
`__bold__` → `**bold**` if present). Nim's Markdown dialect does not support
`_` for emphasis — only `*`.

Be careful not to touch underscores that are part of identifiers, filenames, or
URLs (e.g. `http_server_middleware.md`, `YOUR_NTFY_TOPIC_NAME`, `#ANCHOR_END`).
Only convert genuine emphasis markup.

### 5. Titles

Add `.. title:: <Title>` at the top of each document (before any other
content), using the document's first heading as the title.

- **Use plain text only.** `.. title::` renders its argument as RST and then
  HTML-escapes the result, so any markup or escapable characters produce
  garbage:
  - Backticks (`` ` ``) → escaped `<tt>` HTML.
  - `*` and `_` → emphasis markup.
  - `&`, `<`, `>`, `"` → HTML-escaped to `&amp;`, `&lt;`, `&gt;`, `&quot;`.
- So strip/replace any of these from the title. For example,
  `Scaling & Finishing Touches` must become `Scaling and Finishing Touches`
  (or otherwise remove the `&`), because `&` renders as `&amp;`.
- Remove the original top-level `# Heading` (it's now redundant with
  `.. title::`).
- Promote all remaining headings one level: `##` → `#`, `###` → `##`, etc.

### 6. References

There are **two distinct kinds** of references, with different syntax:

**6a. Module and page links** — use **regular Markdown links** (NOT `importdoc`
references). Module/page references via `importdoc` resolve inconsistently
(e.g. `chronos` resolves but `httpagent` doesn't), so always use explicit
Markdown links:

- Page link: `[Errors and exceptions](./error_handling.html)`
- Module link: `[httpagent](./api/chronos/apps/http/httpagent.html)`

The `.html` path is relative to the current page's location (adjust `../` as
needed). API module pages live under `./api/chronos/...`.

**6b. Nim code references** (symbols, procs, types, etc.) — use Pandoc-style
references, resolved via `.. importdoc::`:

**First read these to learn the syntax:**

- https://nim-lang.org/docs/markdown_rst.html#referencing
- https://nim-lang.org/docs/docgen.html#simple-documentation-links

- **The reference syntax is `[Ref]`** (square brackets, no trailing
  underscore). It is **not** `` `ref`_ `` and **not** `ref_`.
- The API docs live in `./api` (i.e. `<outdir>/api/`), so `importdoc` paths
  must point there: `.. importdoc:: ../../api/chronos/module` (adjust `../`
  count for the file's depth).
- **Unique symbols** → `[symbol]`.
- **Ambiguous/overloaded symbols** (defined in multiple modules, or multiple
  overloads) → use the parenthesized signature form:
  `[symbol(ParamType1, ParamType2)]`. This is the disambiguation syntax (NOT
  the comma-separated complex name).
- Leave stdlib links (`nim-lang.org/docs/...`) as-is — they can't be resolved
  via `importdoc`.

### 7. Images

Replace Markdown image syntax `![alt](path)` with `.. image:: path` (optionally
with `:alt:`).

## Verification

After migration, build with:

```sh
nim book --outdir:<outdir> book
```

and check:

- No broken-link warnings.
- All `importdoc` references resolve (no "cannot open ...idx" errors).
- Titles render cleanly (no escaped HTML).
- Code blocks are syntax-highlighted.
- The sidebar navigation reflects `SUMMARY.md` (with foldable sections and
  current-page highlighting).
