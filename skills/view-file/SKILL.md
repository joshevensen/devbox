# view-file

Display the contents of a file in chat with syntax highlighting.

## Usage

```
/view-file <path>
```

`<path>` can be absolute or relative to the current working directory. Shell expansions like `~` are supported.

---

## Steps

### 1. Resolve the path

Expand the argument to an absolute path:

```bash
realpath -e "<path>"
```

If `realpath` returns an error, tell the user the file was not found and stop.

### 2. Read the file

Use the Read tool on the resolved path.

If the file is unreadable (permissions, binary, etc.), report the error and stop.

### 3. Detect the language for syntax highlighting

Map the file extension to a markdown language tag:

| Extension | Tag |
|---|---|
| `.php` | `php` |
| `.blade.php` | `blade` |
| `.js`, `.mjs`, `.cjs` | `javascript` |
| `.ts`, `.mts` | `typescript` |
| `.jsx` | `jsx` |
| `.tsx` | `tsx` |
| `.vue` | `vue` |
| `.py` | `python` |
| `.ex`, `.exs` | `elixir` |
| `.eex`, `.heex`, `.leex` | `html` |
| `.rb` | `ruby` |
| `.go` | `go` |
| `.sh`, `.bash` | `bash` |
| `.zsh` | `zsh` |
| `.sql` | `sql` |
| `.json` | `json` |
| `.yaml`, `.yml` | `yaml` |
| `.toml` | `toml` |
| `.html`, `.htm` | `html` |
| `.css` | `css` |
| `.scss`, `.sass` | `scss` |
| `.md` | `markdown` |
| `.xml` | `xml` |
| `.env`, `.env.*` | `bash` |
| `Dockerfile` | `dockerfile` |
| `Makefile` | `makefile` |
| No match | (no tag — plain code block) |

For files with compound extensions (e.g. `foo.blade.php`), match the longest suffix first.

### 4. Display

Output the file path as a heading, then the contents in a fenced code block:

````
**`/absolute/path/to/file.php`**

```php
<file contents here>
```
````

If the file is over 500 lines, show the first 200 lines and add a note: `(showing lines 1–200 of N — pass a line range like /view-file path 50-120 to see a specific section)`.

### 5. Line range (optional)

If the argument includes a line range suffix (e.g. `/view-file app/Models/User.php 40-80`), show only those lines. Label the block with the range:

````
**`/absolute/path/to/file.php`** *(lines 40–80)*

```php
<lines 40–80>
```
````
