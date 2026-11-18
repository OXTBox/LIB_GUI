# LIB_GUI: where it stands

Monday, November 17, 2026. Written by Claude (Opus 5.5, a helper), on the branch gui-step1.

## Done

Stages 1 and 2 of PLAN.md section 7, the first working slice, in `livecode/lib_gui.livecodescript`:

| What | State |
|---|---|
| The `.gui` file reader and writer: `Gui.Load`, `Gui.Parse`, `Gui.Problems`, `Gui.Text`, `Gui.Save` | works. Comments, blank lines, unknown kinds and options, and lines it cannot read are all written back as they were |
| Mistakes | no name, two widgets with one name, a place with three numbers, `in=` a panel that is not there, no `gui 1` line: each gives one line in `Gui.Problems()` and the rest of the file still loads |
| The native face: `Gui.Build` | makes a stack of real controls for `window label button toggle choice list field text menu line`, coloured by LIB_THEME (dark by default, `theme=` on the window), menus on a light strip with dark text (the menu rule) |
| `Gui.Get`, `Gui.Set`, `Gui.Show`, `Gui.Enable`, `Gui.Window` | work for every kind above |
| Using a widget | sends `guiDo name, value` to the window's script, or the `do=` message with the value; once a use |
| House rules | the built stack frees itself when closed; its title is "FOR OWNER \| <label>" (or `Users.Title` when LIB_USERS is in use) |
| Examples | `gui/status_browser.gui` (the plan's example), `gui/notes.gui` (one of every kind drawn) |
| Test | `OXT-BEYOND/tests/t41_lib_gui.txt`: 84 checks, all pass, no window needed |

To try it in the IDE (Message Box):
```
start using stack "<projects>/LIB_GUI/livecode/lib_gui.livecodescript"
Gui.Build Gui.Load("<projects>/LIB_GUI/gui/notes.gui"), "Notes"
go stack "Notes"
```
Clicking a widget with no handler for `guiDo` does nothing visible yet; look at `Gui.LastFired()`.

## Not done yet (on purpose)

- `stick=` is stored on each control but nothing moves when the window is resized (`Gui.Resize`, stage 3).
- `panel slider tabs view` are skipped and noted (stage 3). `hint=` shows as a tooltip, not grey words.
- `key=`, `float=`, `may=` are noted as "not done yet" in `Gui.Problems()`.
- No About card on built stacks yet (rule 17).
- `Gui.FromStack`, the XTJSON importer, the GUI Builder: later stages.
- One small change from the plan: widgets live under `tLayoutA["widget"][name]` instead of straight
  under the layout, so a widget may be called "order" or "gui".

## Next step

Stage 2's "done when": build LIB_TOOLBAR's strip and a copy of the Status Browser from `.gui`
files, and have the owner click through them. Then stage 3 (`Gui.Resize`, `panel slider tabs view`,
`Gui.FromStack`).

For the owner: open the Notes window as above and say whether it looks right.
