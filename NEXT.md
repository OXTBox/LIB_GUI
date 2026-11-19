# LIB_GUI: where it stands

Monday, November 17, 2026. Written by Claude (Opus 5.5, a helper), on the branch gui-step1; stage 3, Gui.FromStack and the `popup` kind added 18 Nov.

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
| Popup (18 Nov) | `popup`: a right-click menu (below) |
| Test | `OXT-BEYOND/tests/t41_lib_gui.txt`: 251 checks (51 for `Gui.FromStack`, 30 for `popup`), all pass on both engines (`python3 -I oxt_headless.py --engine both t41_lib_gui.txt`), no window needed (the old "menu rule" check now reads the menu's list colour, `uGuiListText`, since the closed button is light text; the old "slider not drawn" check now uses a made-up kind) |

### Stage 3: what the new kinds do

| Kind | What you see | `Gui.Get` / `Gui.Set` | When it fires `guiDo` |
|---|---|---|---|
| `panel` | a filled box (a group); widgets with `in=<panel>` live in it and their places count from its top left. Its label is a small title at the top. Panels may sit in panels | its label | never |
| `slider` | a scale scrollbar from `min=` to `max=` (0 to 100 if not given), starting at `value=` | the number; whole numbers, unless `min` or `max` has a decimal point (`min=-1.0`) | once when the mouse lets go |
| `tabs` | drawn tabs (LIB_THEME's tab rule: never the native tab control) on a page. A widget with `tab=<tabs>:<item>` shows only while that tab is picked | the picked tab; Set picks one (no message) | once a click on a tab |
| `view` | a placeholder: a dark box with its label in the middle. It is where an app will draw (the 3D picture, a map); nothing is drawn in it yet | Get gives its rect now (it moves with `stick=`); Set changes its words | a click, with the point inside it (`x,y`) |

### The popup kind (18 Nov): right-click menus

```
popup	whoMenu	Copy name|-|Clear	on=who
popup	ReviewMenu	Reviewed|Not Reviewed|-|Open in Explorer|Copy Path	on=list	do=ReviewPicked	end=true
```

Written like `menu`: the name, then the items (`|` between them, `-` a separator). No place is needed (it opens
at the mouse); one given is used for its hidden button and not read back.

| | |
|---|---|
| `on=<widget>` | a right-click on that widget opens it; on a widget in a panel, a popup `on=` the panel opens too. Without `on=`: a right-click on anything no other popup claims (the card too). An `on=` naming no widget of the file is noted in `Gui.Problems()` |
| `end=true` | when LIB_MENU is in use, LIB_MENU's ending (`Menu.WithEnd`: Leave comment..., Explore here..., Minimize) comes after the items; picking one of those goes to `Menu.EndPick` (target: the `on=` widget, else the card), never to `guiDo`. Without LIB_MENU: no ending, and a note in `Gui.Problems()` |
| `do=` | as for every kind: the message gets the item instead of `guiDo name, item` |
| What is built | a hidden button, style menu, menuMode popup, coloured by the menu rule (dark `menuText` on the light `menuFace`: it is only ever seen open). The card gets `on mouseDown pButton` calling `Gui.PopupClick pButton, the long id of the target` (a card script with its own mouseDown is left alone and noted: call it there). Tabs now pass a right-click on |
| `Gui.Popup name` | shows it at the mouse from script (returns why not, e.g. no screen, or "is off") |
| `Gui.PopupClick pButton, pTarget` | what the card calls: opens the right popup for a button-3 click; returns its name |
| `Gui.Get` / `Gui.Set` | Get: the last item picked (empty before one). Set: new items (`\|` or lines between them; the ending is added again) |
| `Gui.Show` / `Gui.Enable` false | the popup is off: it stays hidden and does not open |
| `Gui.FromStack` | a popup-menu button becomes `popup name items`, no place; a built one keeps `on=`, `do=`, `end=` (its items without the ending). A hand-laid one gets no `on=` (the owner's Status Browser pops it from the stack script, `SB.RightClicked`): add `on=` by hand |
| `Gui.LastPopup()` | the last popup asked for, a tab, and shown / off / not shown (for tests: headless there is no screen, `popup` throws, and it says "not shown") |

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

### Gui.FromStack (18 Nov): reading a window out of a stack

`Gui.FromStack(pStack [, pCard])` gives the `.gui` text of a stack's card; `Gui.FromStackToFile pStack, pPath`
writes it (to a `.gui` path only: it refuses any other ending, so it can never write a stack). It only
reads the stack, with messages locked, and sets nothing on it.

| Control | Becomes |
|---|---|
| anything `Gui.Build` made | its own kind and options (kept on the control), with places, labels and values as they are NOW (after use or a resize) |
| button / checkbox / radio button | `button` / `toggle` (`value=true` if hilited) / `toggle x-style=radio` |
| option menu, combo box | `choice` (items, `value=` the shown item; a combo box adds `x-style=combo`) |
| tabbed button | `tabs`; a group named like one of its tabs gets `tab=<tabs>:<item>` (the usual tab pattern) |
| pulldown in the stack's menubar group | `menu` |
| list field / locked one-line field / other fields | `list` (lines as items, `value=` the selected line) / `label` / `field` or `text` (many lines, a scrollbar, or taller than 40) |
| scale scrollbar | `slider` with `min= max= value=` |
| line graphic; rectangle showing its name | `line`; `view` |
| group | `panel` (its controls get `in=` and places counted from it) |
| tooltip, hidden, greyed (hand controls) | `tip=`, `x-visible=false`, `x-enabled=false` |
| popup menu | `popup` (items; no place, no `on=`: add it by hand) |
| plain scrollbar, other graphics, images, players, widgets | a `# unknown: ...` comment line with its type, name, place and items (also in `Gui.Problems()`) |
| a field with many lines | its text is not carried (a `.gui` line holds one): a `# note:` line says so |

Names are made unique (`dup`, `dup_2`). The window's title keeps only its words ("FOR OWNER | Notes" gives
"Notes", "FOR <WHO> Name" gives "Name"). The first lines say how much was read and that scripts are not carried.

Round trip (tested): stage3.gui and notes.gui are built, read back, and every widget's kind, place, label,
value and option comes back as the file had it; built again, every control is in the same place with the same
value, and reading the second window gives the same text.

The owner's Status Browser (`LIB_DEV/livecode/Status_Browser_gui_For_edits.livecode`, read from a copy):
`gui/status_browser_from_stack.gui`. All 8 controls mapped (regenerated 18 Nov from a copy: `ReviewMenu` is now a
`popup` line, with no `on=`: his script pops it up from the list's right-click); the 6 lines of `LLMNote` are not carried. The list carries the file names it held
when saved.

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
- The XTJSON importer (`tools/gui_from_xtjson.py`, the rest of stage 3), the GUI Builder: later stages.
- To check on screen (not testable headless: `popup` needs a screen): does a right-click on the Notes list
  (`who`) open `whoMenu` at the mouse, dark text on light, and does picking an item reach `guiDo`? Does a
  right-click in a `field`/`text` (unlocked) open its popup on Windows? A `choice` or `menu` may open its own
  list on a right-click instead.
- `popup` cascades (submenus) and checkmarks are not done: the items are passed as written, so LIB_MENU-style
  menu text (`!c`, tab-indented submenus) is untested.
- Stick (resizing) of hand-laid windows is not read (the IDE's Geometry Manager keeps it in its own way): add `stick=` by hand.
- One small change from the plan: widgets live under `tLayoutA["widget"][name]` instead of straight
  under the layout, so a widget may be called "order" or "gui".

## Next step

Stage 2's "done when": build LIB_TOOLBAR's strip and a copy of the Status Browser from `.gui`
files, and have the owner click through them. Then `tools/gui_from_xtjson.py`, the last of stage 3.

For the owner: open the Stage3 window as above, click the tabs, drag the corner, and say whether it looks right.
And: read one of your own windows out (Message Box, with lib_gui in use):
`put Gui.FromStack("Status_Browser")` (it only reads; nothing is saved), and say whether the lines look like your window.
