# LIB_GUI: where it stands

Monday, November 17, 2026. Written by Claude (Opus 5.5, a helper), on the branch gui-step1; stage 3 added 18 Nov.

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
| Look fixes (18 Nov) | dark theme: `choice` and `menu` are light text on the panel colour when closed and turn to dark text while their list is open (`Gui.MenuOpen` / `Gui.MenuRest`: LIB_THEME's menu rule for the light list); the menu strip is a dark bar; a `list`'s selected line is white on the hilite colour (`Gui.ListMark`; a theme key `hiliteText` overrides); `hint=` shows dimmed in an empty `field` or `text` and goes when it is entered (`Gui.HintOff` / `Gui.HintOn`), `Gui.Get` gives empty under it |
| Stage 3 (18 Nov) | `panel slider tabs view` and `stick=` (below) |
| Test | `OXT-BEYOND/tests/t41_lib_gui.txt`: 170 checks, all pass, no window needed (the old "menu rule" check now reads the menu's list colour, `uGuiListText`, since the closed button is light text; the old "slider not drawn" check now uses a made-up kind) |

### Stage 3: what the new kinds do

| Kind | What you see | `Gui.Get` / `Gui.Set` | When it fires `guiDo` |
|---|---|---|---|
| `panel` | a filled box (a group); widgets with `in=<panel>` live in it and their places count from its top left. Its label is a small title at the top. Panels may sit in panels | its label | never |
| `slider` | a scale scrollbar from `min=` to `max=` (0 to 100 if not given), starting at `value=` | the number; whole numbers, unless `min` or `max` has a decimal point (`min=-1.0`) | once when the mouse lets go |
| `tabs` | drawn tabs (LIB_THEME's tab rule: never the native tab control) on a page. A widget with `tab=<tabs>:<item>` shows only while that tab is picked | the picked tab; Set picks one (no message) | once a click on a tab |
| `view` | a placeholder: a dark box with its label in the middle. It is where an app will draw (the 3D picture, a map); nothing is drawn in it yet | Get gives its rect now (it moves with `stick=`); Set changes its words | a click, with the point inside it (`x,y`) |

`stick=`: a built window lays itself out again when it is resized (a `resizeStack` handler is
added to its script; an app script with its own `resizeStack` should call `Gui.Resize pNewWidth, pNewHeight`).
`left,top` (the default) stays put; `right` alone moves with the right edge; `left,right` stretches;
the same for `top` and `bottom`. In a panel, the edges are the panel's.

To try stage 3 in the IDE (Message Box), then drag the window's bottom-right corner:
```
start using stack "<projects>/LIB_GUI/livecode/lib_gui.livecodescript"
Gui.Build Gui.Load("<projects>/LIB_GUI/gui/stage3.gui"), "Stage3"
go stack "Stage3"
```
Click the Look and Sound tabs; the Sound page has a panel in a panel ("Mixer").

To try it in the IDE (Message Box):
```
start using stack "<projects>/LIB_GUI/livecode/lib_gui.livecodescript"
Gui.Build Gui.Load("<projects>/LIB_GUI/gui/notes.gui"), "Notes"
go stack "Notes"
```
Clicking a widget with no handler for `guiDo` does nothing visible yet; look at `Gui.LastFired()`.

## Not done yet (on purpose)

- `tabs` and `menu` inside a panel (`in=`) are placed on the window instead, and noted.
- A `view` is only a placeholder face; drawing into it (an image, the xt3d picture) is the app's job, later.
- To check on screen (not testable headless): do the tabs, the panel faces and the sliders look right in
  the dark theme on Windows (scale scrollbars are drawn by Windows and may stay light), and does dragging
  the window corner move things smoothly?
- To check on screen (not testable headless): does the open list of File and of the choice show dark text on light,
  and does the closed button go back to light text after a cancelled menu (restored on menuPick, mouseUp, mouseRelease)?
  If the choice's open list turns out dark (Windows draws option menus itself), clear its `uGuiListText` in `guiAfterTheme`.
- `key=`, `float=`, `may=` are noted as "not done yet" in `Gui.Problems()`.
- No About card on built stacks yet (rule 17).
- `Gui.FromStack`, the XTJSON importer (the rest of stage 3), the GUI Builder: later stages.
- One small change from the plan: widgets live under `tLayoutA["widget"][name]` instead of straight
  under the layout, so a widget may be called "order" or "gui".

## Next step

Stage 2's "done when": build LIB_TOOLBAR's strip and a copy of the Status Browser from `.gui`
files, and have the owner click through them. Then the rest of stage 3 (`Gui.FromStack`, `tools/gui_from_xtjson.py`).

For the owner: open the Stage3 window as above, click the tabs, drag the corner, and say whether it looks right.
