- created: 2026-08-28
- created_by: opus-5
- created_during: f/help-that-helps
- completed: 2026-08-28
- completed_during: f/help-that-helps
- size: s

## Blockers

(none)

## Questions

_None._

## Findings

Result: merged to main on 2026-08-28, preserved under archive/help-that-helps.

- Asking for help printed a single line naming four commands and explaining
  none. It also ran the alternatives for a source together with the alternatives
  for a command using the same separator, so `install <owner>/<repo> | <path> |
  sync` could not be parsed by eye at all.
- The same line was printed for an unknown command, so the answer to a mistake
  and the answer to a question were identical, and neither answered anything.
- Operator's assessment, verbatim: "your --help explains nothing at all, it's
  actually horrible."

## Proposal

Describe every command and option in a sentence, send a question to standard
output and a mistake to standard error, and name what was not understood.

## Testing

`tests/store-in-git-folder.sh` gains twenty-six assertions: every command and
option appears and is described, help goes to standard output and succeeds, the
three spellings agree, an unknown command names the word and fails, no command
at all fails, and the two commands taking arguments say what they needed. 437
assertions across eight suites at branch HEAD, all green.

## Changelog entry

#### 📝 `f/help-that-helps` → `archive/help-that-helps`

`kai --help` printed one line that named four commands and explained none of
them, with the alternatives for a source run together with the alternatives for
a command so it could not be read by eye; the same line answered an unknown
command, making the reply to a mistake identical to the reply to a question.
Help now describes each command and option in a sentence, says where the
packages physically live, and points at the write-ups for the configuration file
and the package format. A question goes to standard output and succeeds; a
mistake names the word that was not understood, prints the help, and fails.

_Board: `help-that-helps`._

## Readme delta

None. The README already lists the command grammar; this is the tool explaining
itself at the terminal.
