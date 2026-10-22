# The parameter-file model (ape)

Every `gt*` tool reads its parameters through ape (by way of `hoops` and
`st_app`). This page describes what ape actually does with `.par` files, as
implemented in `src/ape_session.c`, `src/ape_io.c` and `src/ape_par.c`.
Behaviour described here comes from reading the code; it has not been
checked at runtime unless stated otherwise.

Back to the [package overview](README.md).

## The `.par` file format

One parameter per line, seven comma-separated fields:

```
name, type, mode, value, min, max, "prompt"
evfile,   f,  a,  ,        ,     , "Event data file name"
algorithm,s,  a,  "PHA2",  CCUBE|CMAP|LC|PHA1|PHA2|HEALPIX, , "Type of output file"
emin,     r,  a,  30,      ,     , "Start value for first energy bin in MeV"
mode,     s,  h,  "ql",    ,     , "Mode of automatic parameters"
```

- **Lines** starting with `#`, and blank lines, are kept as unnamed entries
  so that they survive a rewrite of the file. Lines longer than 8192
  characters are rejected (`APE_BUF_SIZE` in `ape_io.c`).
- **Types** (`ape_par.c`, list near line 965): `b` (boolean), `i` (integer),
  `r` (real), `s` (string), `f` (file name), and file names with access
  checks: `fr` (must be readable), `fw` (writable), `fe` (must exist), `fn`
  (must not exist). `d` and `g` are also accepted. In the Fermitools par
  files only `b`, `i`, `r`, `s`, `f` and `fr` occur.
- **Modes** are built from `a` (auto), `h` (hidden), `q` (query) and `l`
  (learn), e.g. `ql`, `hl`, `a`.
- **min/max:** a numeric range, or, in the `min` field only, an
  enumeration `A|B|C`.
- **Special values:** for numeric parameters, `INDEF`, `NONE`, `UNDEF` and
  `UNDEFINED` mean "undefined", and `INF`, `INFINITY` and `NAN` mean
  infinite (for reals). `hoops` turns these into the `P_UNDEFINED` and
  `P_INFINITE` exception codes.
- **Environment variables** (`${VAR}`, `$ENV{VAR}`, `$ENV(VAR)`, `$(VAR)`)
  are expanded whenever a field is read (`get_field` in `ape_par.c` calls
  `ape_util_expand_env_var`), unless the field is in single quotes.

## PFILES: where par files are found

`PFILES` holds two path lists separated by `;`:

```
PFILES="<local dir>:<local dir>...;<system dir>:<system dir>..."
```

- Text **before** the `;` is the *local* (user, writable) path. Text
  **after** it is the *system* (read-only, installed) path. If there is no
  `;`, the whole value is the local path and there is no system path
  (`create_paths` in `ape_io.c`).
- Empty entries (`::`, a leading `:`) are kept as empty directory names.
- ape reads `PFILES` once, on first use, and caches it.
  `ape_io_set_pfiles()` overrides the cached value without touching the
  environment.
- If `PFILES` is not set, both lists are empty. ape then falls back to
  `./<tool>.par` in the current directory (see below). There is **no**
  built-in `~/pfiles` default.

The conda activation script (`recipe/activate.sh` in the ScienceTools
umbrella) sets it up:

| `PFILES` before activation | After activation |
|----------------------------|------------------|
| unset | `.:$HOME/pfiles;$INST_DIR/syspfiles` (and creates `~/pfiles`) |
| contains `;` | `$PFILES:$INST_DIR/syspfiles` (syspfiles is appended to the system part) |
| no `;` | `$PFILES;$INST_DIR/syspfiles` (the old value becomes the local part) |

Each package's `pfiles/*.par` are installed to
`share/fermitools/syspfiles/` (`FERMI_INSTALL_PFILESDIR`).

## Opening a tool's parameters (`ape_session_init`)

The par-file name is the basename of `argv[0]` with any extension replaced
by `.par` (`get_pfile_name`). Then:

1. `ape_util_interpret_env()` reads `APEDEBUG` (enables debug messages) and
   `HEADASNOQUERY` (disables all prompting).
2. Search the **system** path, in order, for `<tool>.par`.
3. Search the **local** path, in order, for `<tool>.par`.
4. If there is no local copy but there is a system copy, clone the system
   file in memory and name it `<first local dir>/<tool>.par`. That is where
   it will be written on save. The first local directory is not created if
   it doesn't exist.
5. If neither path has the file, try `<tool>.par` relative to the current
   directory, and treat it as the local file.
6. **Merge** system and local into the *merged* file (next section).
7. Clone *merged* into *current*, then apply the command line to *current*
   (`ape_io_apply_command_line`), then check the file format (but not
   values).

### Merging system and local files (`ape_io_merge_par_files`)

Parameters are matched **by name**.

- If both files have the same parameters in the same order, with the same
  type, mode, min and max, **and** the system file is not newer than the
  local file, the local file is used unchanged.
- Otherwise the **system file defines the structure**: type, mode, min and
  max always come from the system file. Parameters that exist only in the
  local file are dropped.
- **Values** come from the local file, with one exception: if the system
  file is newer than the local one (by mtime), values of **hidden**
  parameters are taken from the system file. So after a Fermitools upgrade,
  hidden parameters reset to their new defaults, while learned values of
  non-hidden parameters are kept.
- A local parameter that fails `ape_par_check` is replaced wholesale by the
  system one.
- If the system file has a parameter the local file lacks, the system file
  (with local values filled in for matching names) becomes the merged file,
  under the local file's name.

## Command-line syntax (`ape_io_apply_command_line`)

- `name=value`, `name = value`, `name= value` are all accepted.
- `name+` / `name-` set a boolean to yes / no.
- **Names are case-insensitive and may be abbreviated** to any unique
  prefix. An exact match wins over prefixes. An ambiguous prefix is an
  error ("contains an ambiguous parameter name").
- Arguments that are not assignments are **positional**: they are assigned,
  in order, to the non-hidden parameters that were not assigned
  explicitly. Too many positional arguments is an error. Naming a parameter
  twice is an error.
- A parameter set on the command line is flagged `cmd_line`, which makes
  its effective mode hidden (no prompt) for this run.

## Modes, prompting and learning

The **effective mode** of a parameter (`ape_par_get_eff_mode`):

1. Start with its own mode field.
2. If that is `a`, use the value of the file's `mode` parameter instead
   (default `ql` if the file has no `mode` parameter). The `l` (learn) flag
   is taken from `mode` only if `mode` turns learning on.
3. If the parameter was given on the command line, it becomes `h`.
4. Reprompt flags (`eQueryHidden`, `eMultiQuery`, set through
   `PILSetReprompt` or the prompt-style API) can force `q`.

A query (`ape_par_query`) prompts only when the effective mode is `q`, and
not at all when prompting is overridden (`HEADASNOQUERY` set, or
`ape_util_override_query_mode`). The prompt has the form
`Prompt text (min:max) [current value] `. It is written to **stdout** and read from
**stdin** with `fgets`. Pressing Enter (truly empty input) keeps the current
value. On EOF the query fails with `eInputFailure`. Input that fails
`ape_par_check` with a recoverable error (wrong type, out of range, not in
the enumeration) re-prompts.

**Learning:** when the session is saved (`ape_session_save`), a copy of
*current* is made, and every parameter whose effective mode lacks `l` is
reset to its *merged* (pre-command-line) value
(`ape_io_revert_unlearned`). The copy is then written to the local file.
So:

- `ql` / `hl` parameters remember the last value used, including values
  given on the command line.
- `q` / `h` parameters, and `a` parameters when `mode` is `q` or `h`, are
  never changed on disk by a run.

**When files are written:** after **every** query (`query_value` calls
`ape_session_save`), and on `ape_trad_close(1)`. Writes go to a temporary
file `<file>-<host>-<pid>`, which is then `rename`d over the target, so a
crash does not leave a half-written par file. A write that fails (for
example because the local directory doesn't exist) prints an ape error, but
callers of `ape_trad_close` ignore its status.

## The command-line utilities

All of these are thin `main()`s over `ape_binary_*` in `src/ape_binary.c`.
The first argument is a tool name (looked up through `PFILES`, exactly like
the tool itself) or, with `-f` or a path that contains `/` and ends in
`.par`, a par file.

| Tool | Usage | Does |
|------|-------|------|
| `pget` | `pget [-f] tool [par ...]` | Print parameter values, without prompting and without saving. |
| `pset` | `pset [-f] tool [par=value ...]` | Set values in the local par file. With only the tool name, prompts for every parameter. |
| `plist` | `plist [-f] tool` | List all parameters with their current values. |
| `pquery` | `pquery [-f] tool par [args]` | Query one parameter as the tool would, then save **without** reverting unlearned parameters. |
| `pquery2` | same | Like `pquery`, but saves with normal learning rules. |
| `punlearn` | `punlearn [-f] tool ...` | Overwrite the local par file with a copy of the system one. |
| `pcheck` | `pcheck tool [args]` | Check the par file format and values; report errors. |

`punlearn gtfoo` is the standard fix for a corrupt or stale local
`gtfoo.par`.

## Practical consequences for Fermitools users and developers

- **Where local copies land.** With the default activation
  (`PFILES=".:$HOME/pfiles;…"`), a tool that has no local copy yet gets one
  written to **`./`** (the first local directory), not `~/pfiles`. A copy
  already in `~/pfiles` is found and updated in place. To keep the working
  directory clean, put `$HOME/pfiles` first, or remove `.` from the local
  part.
- **Changing a `.par` file in a package.** Installed users keep their local
  copies. Type, mode, range and enumeration changes are picked up through
  the merge, but non-hidden values stay at the user's learned values until
  they run `punlearn`. Renamed parameters lose their learned value.
- **Running without prompts** (scripts, CI, batch jobs): give every `a`
  parameter on the command line, set `mode=h` on the command line, or set
  `HEADASNOQUERY`. If stdin is not a terminal and a prompt happens anyway,
  the tool reads from stdin and fails on EOF.
- **Parallel runs** of the same tool from the same directory share one
  local par file. Writes are atomic (rename), but the last writer wins, and
  one run can pick up learned values that another run wrote.
