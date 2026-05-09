# ll

Display a file tree for a given path.

## Usage

```
/ll [path]
```

- `path` — directory to display (optional, defaults to current working directory)

---

## Steps

Run `tree` on the given path at depth 2, excluding `.git` internals but showing gitignored files:

```bash
tree <path> -L 2 -a -I '.git'
```

If no path was provided, use `.` (current working directory).

If `tree` is not installed, fall back to:

```bash
find <path> -maxdepth 2 -not -path '*/.git/*' | sort | sed -e "s|<path>||" -e "s|[^/]*/|  |g"
```

Display the output as a code block.
