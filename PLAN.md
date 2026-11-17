# LIB_GUI: the plan

Monday, November 16, 2026. Draft 1, by Fable 5.2, for the owner to correct. TODO A-42; it also
settles what Spark writes in S-3 / A-45 and what S-4's "ports" are. A plan only: no code yet.

## 1. What it is for

The owner's brief: "a future gui building application with the foundation that we have for
preserving the system outside of the engine libraries", judged by the closing argument: **does
it stand alone, and is it easy and enjoyable enough to put away the old IDE?**

Today a window exists only inside a binary stack file that one program can open. LIB_GUI makes
the window a **small text file** (`.gui`) that says what is in it, and gives every runtime a
**face** that shows that file. The stack becomes one way of showing the window, not the only
place it lives.

| Part | What it is |
|---|---|
| The `.gui` file | one widget a line: kind, name, place, label, options. Written by hand, by Spark, by the Builder, or read out of a stack the owner laid out |
| The faces | **native** (real xTalk controls, coloured by LIB_THEME): here. **raygui** (inside xt3d): LIB_RAYGUI. **vector** (drawn in lines by iGame3D XT): later, here. **tkinter** and others: later, each a small reader |
| The calls | `Gui.*`, the same whatever face is showing; one message back, `guiDo` |
| The GUI Builder | the app: open a `.gui`, see it, drag and resize, set labels and actions, save. Its own window is a `.gui` |

The "put away the old IDE" test, made concrete: **a new tool window is made, wired and run
without the IDE open.** Lay it out in the Builder, write its handlers in a `.livecodescript`
file in any text editor, start it from the toolbar.

## 2. What it stands on

- xTalk, as script files in git (`livecode/lib_gui.livecodescript`), tested headless.
- LIB_THEME for every colour (`Theme.Use`, `Theme.ApplyStack`); its menu rule (dark menu text)
  and tab rule (drawn tabs, never the native tab control) are followed by the native face.
- LIB_USERS for titles and for "may this user save".
- LIB_DATA when a layout is saved by a user rather than shipped with an app.
- LIB_XTJSON harvests as a source of old layouts (the 2007 iGame3D windows), read by one small tool.
- The owner's way of working is kept: he lays windows out by hand in the IDE
  (`*_gui_For_edits`), and the build reads his layout and never writes to his file.
  `Gui.FromStack` is that reading-out, now into a `.gui` file.

## 3. The `.gui` file

Plain UTF-8 text. One widget a line. Fields are separated by tabs. `#` starts a comment.

```
# kind    name     then, in any order: a place (x,y,w,h), a label, and key=value options
gui	1
window	StatusBrowser	1140,700	Status Browser	theme=dark	min=800,500
menu	File	Refresh|-|Quit
menu	Help	About
list	files	8,38,420,620	stick=left,top,bottom
text	note	436,38,696,300	stick=left,top,right
field	feedback	436,346,696,270	stick=left,right,bottom	hint=Your note about this file
button	submit	436,624,120,28	Submit	stick=left,bottom
button	tell	564,624,140,28	Tell Claude	stick=left,bottom	tip=Ask the AI to read your reviews now	do=TellClaude
```

| Rule | |
|---|---|
| Field 1, field 2 | the kind and the name. Names are unique in a file; scripts use the name, never a number |
| A field of four numbers | the place: `x,y,width,height` in pixels at 100% scale, from the window's top left. (A window has two: `width,height`.) |
| A field with `=` | an option |
| Any other field | the label (the text shown). For `menu`, `choice`, `tabs`: the items, `|` between them, `-` a dividing line |
| Order after the name | free: a hand or a small model cannot get it wrong |
| Icons | a label may be a Unicode symbol (`▶`, `⚙`); there are no image files in a layout |
| Line 1 | `gui 1`: the format's number, so old files can be read forever |

### The widget kinds (fourteen; a new kind is added here first)

| Kind | What it is | Value it holds | Native face | raygui face |
|---|---|---|---|---|
| `window` | the window itself | - | a stack | `GuiWindowBox` or the whole view |
| `panel` | a box that holds others (`in=<panel>` on the others; their places count from the panel) | - | a group with a border | `GuiGroupBox` |
| `label` | words | - | a locked field | `GuiLabel` |
| `button` | press it | - | a button | `GuiButton` |
| `toggle` | on or off | true / false | a checkbox | `GuiCheckBox` |
| `choice` | pick one from a short list | the item | an option menu | `GuiDropdownBox` |
| `list` | pick a line from a long list | the line | a list field | `GuiListView` |
| `field` | type one line | the text | a field | `GuiTextBox` |
| `text` | many lines, read or typed | the text | a scrolling field | a text panel (read only at first) |
| `slider` | a number between two ends (`min=`, `max=`) | the number | a scrollbar | `GuiSlider` |
| `tabs` | pages (`tab=<tabs>:<item>` on a panel puts it on a page) | the item | `Theme.TabStrip` | `GuiTabBar` |
| `menu` | one menu of the menu bar | - | `Theme.MenuBar` + a pulldown | a button that drops a list |
| `view` | an empty rectangle the app draws in (the 3D picture, a map) | - | an image or graphic | the place the scene is drawn |
| `line` | a dividing line | - | a line graphic | `GuiLine` |

### The options

| Option | Meaning |
|---|---|
| `do=<Name>` | when used, send the message `<Name>` with the value, instead of `guiDo` |
| `tip=<words>` | the tooltip |
| `hint=<words>` | grey words in an empty field |
| `stick=left,top,right,bottom` | which window edges it keeps its distance from when the window is resized (default `left,top`) |
| `in=<panel>` / `tab=<tabs>:<item>` | where it lives |
| `value=<v>` | what it holds at the start |
| `min=` `max=` | a slider's ends; a window's smallest size |
| `key=<key>` | a keyboard shortcut |
| `may=<word>` | shown only to users who may (LIB_USERS word, e.g. `may=save`) |
| `theme=<name>` | on the window: the LIB_THEME theme |
| `float=front` | on the window: stays in front of other windows (the toolbar) |
| `glyph=<name>` | later: a 1-bit picture from LIB_BIT shown in place of a symbol, the same in every face (a face's font may lack `▶`) |
| `x-<anything>=` | an app's own option; faces ignore it, the file keeps it |

A face that meets a kind or option it does not know **skips it and says so** (`Gui.Problems()`),
never fails: an older face can still show a newer file.

## 4. The handlers

```
start using stack ".../LIB_GUI/livecode/lib_gui.livecodescript"

put Gui.Load(tFolder & "/gui/status_browser.gui") into tLayoutA    -- reads and checks
Gui.Build tLayoutA, "StatusBrowser"        -- native face: makes the stack and its controls
Gui.Set "files", tListOfFiles              -- by name; the same call under every face
put Gui.Get("feedback") into tNote

on guiDo pName, pValue                     -- arrives at the window's script
   if pName is "submit" then Review.Submit Gui.Get("feedback")
end guiDo
on TellClaude                              -- a widget with do=TellClaude
end TellClaude
```

| Handler | Gives or does |
|---|---|
| `Gui.Parse(pText)` / `Gui.Load(pFile)` | the layout as an array (`tLayoutA[name][kind / rect / label / option...]`, plus the order) |
| `Gui.Problems()` | what the last read found wrong, one a line (`line 7: two widgets named "ok"`) |
| `Gui.Text(pLayoutA)` / `Gui.Save pLayoutA, pFile` | the layout as text again; what it does not understand it writes back unchanged |
| `Gui.Build pLayoutA, pStack` | the native face: a themed stack with these controls. Builds into an existing stack when one is named |
| `Gui.FromStack(pStack)` | a layout read out of any stack (kinds, names, places, labels, menu items): the owner's hand-laid windows |
| `Gui.Get(pName)` / `Gui.Set pName, pValue` | a widget's value |
| `Gui.Show pName, pFlag` / `Gui.Enable pName, pFlag` | hide, show, grey out |
| `Gui.Resize pWidth, pHeight` | lays the widgets out again by their `stick` |
| `Gui.Face()` / `Gui.UseFace pName` | `native`, `raygui`, `vector`; a face library registers itself |
| `guiDo pName, pValue` | the message a face sends when a widget is used |

Each control the native face makes carries its kind, name and action in custom properties
(`uGuiKind`, `uGuiName`, `uGuiDo`), so the layout can be read back out of the built stack.
The built stack follows the house rules by itself: `closeStackRequest` frees it (LIB_ALPHA 12b),
the title comes from `Users.Title`, an About card is added from the app's About text (rule 17).

### What a face must do (the contract for LIB_RAYGUI and every later face)

1. Take the layout array from `Gui.Load`; never read the file its own way.
2. Answer `Gui.Get / Set / Show / Enable / Resize` for every kind it draws.
3. Send `guiDo pName, pValue` (or the `do=` message) when a widget is used, once per use.
4. Skip what it does not know and add a line to `Gui.Problems()`.
5. Take its colours from the LIB_THEME theme named on the window.

## 5. The GUI Builder (the app)

One window, itself a `.gui` file (`gui/builder.gui`), in the three-part shape of the old
iGame3D tools: a palette of the fourteen kinds on the left, the window being made in the
middle, the selected widget's line as a small property list on the right.

| It does | How |
|---|---|
| New / Open / Save a `.gui` | menus; saves ask `Users.May("save")` |
| Add a widget | click a kind, drag a rectangle |
| Move, resize, rename, relabel | drag; arrow keys move 1 px, with Shift 10; a grid snap of 4 px |
| Set options | the property list is the widget's line, one option a row |
| Try it | "Run" shows the layout as a real window; every `guiDo` is listed in a log pane |
| See the other faces | "Show in raygui" sends the same file to the xt3d bench (when LIB_RAYGUI is there) |
| Take in an old window | "Import" reads a harvest (`tools/gui_from_xtjson.py`) or a live stack (`Gui.FromStack`) |
| Stub the handlers | "Write handlers" makes a `.livecodescript` with an empty handler for each action |

It never edits its own running window (the LIB_SCRIPTBLOCKS rule: tools edit examples and other
files, never their own source).

## 6. Who owns what (the same words in all four plans)

| Library | Owns | Never does |
|---|---|---|
| **LIB_USERS** | who is at the controls: the roster, the current user, the wording of window titles, the stamp on log lines, the "may I" words | draws nothing, opens no windows |
| **LIB_THEME** (exists) | colours and line weight, as `themes/<name>.txt` | no layout, no widgets |
| **LIB_GUI** | what a window contains: the `.gui` layout file, the widget kinds, the calls `Gui.*`, the message `guiDo`, the native face (real xTalk controls) and the GUI Builder app | no colours of its own (asks LIB_THEME), no content of its own (no launcher list, no user names) |
| **LIB_RAYGUI** | one more face for the same `.gui` file: raygui drawn inside xt3d (iGame3D xRay); the `xt3d_Gui*` calls; how a theme becomes a raygui style | no layout format and no widget kinds of its own |
| **LIB_TOOLBAR** | one app: the floating launcher strip, and its content file `*.toolbar` (what the buttons are, what they open) | no widget code (its window is built by LIB_GUI); it does not decide who may press what (asks LIB_USERS) |

The rules that follow from the table:

1. A window is laid out once, as a `.gui` file, and shown by any face. Nobody ports a window by hand.
2. A new widget kind is added to LIB_GUI first (the format and the native face), then to the other faces.
3. Colour is LIB_THEME's. Who is LIB_USERS's. What is on the launcher is LIB_TOOLBAR's. How it is drawn in raylib is LIB_RAYGUI's.
4. A row of tools inside an app's own window (iGame3D XT's 26 tools) is ordinary `.gui` buttons belonging to that app. LIB_TOOLBAR is only the floating strip that sits outside a window: the projects launcher, or an app's own tools floated the way the 2007 iGame3D main strip was.
5. XTJSON stays the full, lossless record of a stack. A `.gui` file is the small design a person or Spark can write by hand. There is one tool, one way: XTJSON harvest to `.gui`.
6. No script builds a window title by hand: it asks `Users.Title`.

Build order across the four: (1) LIB_USERS core, (2) LIB_GUI stage 1: the format and the native face,
(3) LIB_TOOLBAR, the first real customer, (4) LIB_RAYGUI: one button proven in the bench, then the
player, (5) the GUI Builder app, (6) the vector face for iGame3D XT.

Where LIB_GUI meets the existing libraries:

| Library | How they fit |
|---|---|
| LIB_XTJSON | the full record of a stack, for archive and rebuild. `tools/gui_from_xtjson.py <harvest> <stack>` writes a `.gui` from one (kinds, names, places, labels; scripts are not carried). Nothing goes the other way: `Gui.Build` makes the stack directly |
| LIB_SPARK (S-3, A-45) | Spark writes `.gui` files, not XTJSON: a line a widget is within a small model's reach, and `Gui.Problems()` marks its mistakes. The owner's keep / redo (O-10) is done in the Builder's Run view |
| S-4 ("port approved UIs to raygui, Dear ImGui, tkinter") | becomes "write a face": raygui is LIB_RAYGUI; tkinter is about 150 lines of standard Python on the pythonizing day; Dear ImGui only if a C++ host ever needs it |
| LIB_EDITOR / iGame3D XT | its tool row, Library, Inspector become `.gui` files of that app, when each is next touched; nothing is rewritten for its own sake |
| LIB_DEV (Status Browser, Game Browser) | the first windows to be read out with `Gui.FromStack` as test material; they keep working as they are |
| LIB_GENERICA | a label beginning `@` is looked up in the app's label set (`@quit`), so a retheme changes a window's words too. Later; plain labels work from the first day |
| The engine contract | a game may still call only what the contract lists (`HUD.Set` for words on screen). `Gui.*` is for tools. Whether games get it is question 4 |
| The 2007 `murgaRevOut` stack | the first try at this idea (xTalk window to another toolkit). Its lesson, kept: convert from data, not from a live window |

## 7. What is built first

| Stage | What | Done when |
|---|---|---|
| 1 | The format: `Gui.Parse / Load / Problems / Text / Save` | the example above reads, writes back the same, and three broken files give three clear problem lines |
| 2 | The native face: `Gui.Build`, `Gui.Get / Set / Show / Enable`, `guiDo`, for `window label button toggle choice list field text menu line` | LIB_TOOLBAR's strip and a copy of the Status Browser are built from `.gui` files and work |
| 3 | `Gui.FromStack`, `gui_from_xtjson.py`; `panel slider tabs view`, `Gui.Resize` | the 2007 Inspector's material card comes out as a `.gui` and builds again, looking right to the owner |
| 4 | The GUI Builder | the owner makes a small tool window with the IDE closed, and says whether it was pleasant |
| 5 | The vector face (iGame3D XT draws `label button toggle slider list` in lines) | one settings panel shows the same in XT and xRay |
| 6 | A face outside xTalk (tkinter) | the Status Browser's layout opens in Python with no engine installed: the proof it stands alone |

Stages 1 and 2 are a few days for Opus and unblock LIB_TOOLBAR. Stage 4 is the big one. Fable is
not needed again unless the format has to change.

## 8. How it is tested headless

`OXT-BEYOND/tests/oxt_headless.py` bodies in `tests/`, the same way as `t16_theme_studio`:

- **Format:** read, write, read again: the two arrays are equal. Unknown kinds and options
  survive the round trip. Each mistake (no name, two same names, three numbers in a place,
  `in=` a panel that is not there) gives one line in `Gui.Problems()` and the rest still loads.
- **Native face:** build into an invisible stack; count the controls; each has the right
  place, label and custom properties; colours match the theme file; menu text is dark (the menu
  rule). `send "mouseUp"` to a button: the stub `guiDo` recorded its name once. `Gui.Set`
  then `Gui.Get` gives the value back for every kind.
- **Reading out:** `Gui.FromStack` of the built stack gives the layout that built it.
- **Importer:** `gui_from_xtjson.py` on the 2007 harvest's `Dev` stack names its 8 controls.
- **Builder:** its actions are handlers (`Builder.Add`, `Builder.Move`, `Builder.Save`), each
  with a `Builder.State()` line the test reads; no mouse needed.

What headless cannot say: whether a window looks right or is pleasant. That is the owner's
part, at stages 2 and 4.

## 9. Options rejected

| Option | Why not |
|---|---|
| XTJSON as the design format | it is the right archive (everything, lossless) and the wrong thing to write: hundreds of properties a control, and tied to one engine's property names |
| JSON or XML of our own | needs a parser in every face and is easy for a small model to break; a line a widget is read with `split` anywhere |
| The raygui layout tool's own file (`.rgl`) | raygui kinds only, no menus, no actions, no resize rule. LIB_RAYGUI may write one out later for people who use that tool |
| HTML and CSS | a browser engine is the opposite of standing alone |
| Scripts inside the layout file | then the layout only runs where that language runs. A layout names actions; the code lives in script files |
| Layout by rows and columns only (no pixel places) | the owner lays windows out by eye; places in pixels plus `stick` keep that, and can be drawn by raygui as they are |
| Building the Builder first | it needs the format and a face to exist; and the toolbar is wanted sooner |
| One library for everything GUI | the raygui part needs the C bridge and the owner's hand-run build; the launcher is content. Three small libraries with one format between them |

## 10. Questions only the owner can answer

| # | Question | Default taken |
|---|---|---|
| 1 | Is a line a widget, tabs between fields, the format you want to read and write? | yes; the example in section 3 is the whole idea |
| 2 | Spark's GUI drafts (S-3): `.gui` files instead of XTJSON descriptions? | yes: `.gui`; the Builder shows them for your keep / redo |
| 3 | Which window do you want to make first with the IDE closed (the stage-4 test)? | a small one: a note pad that writes to `GAME_NOTES.txt` |
| 4 | Do games get `Gui.*` (menus and sliders inside a game), which adds it to the engine contract for all four editions? | not now: tools only; games keep `HUD.Set` |
| 5 | The first face outside xTalk: tkinter, or wait? | wait for the pythonizing day; raygui comes first |
| 6 | Should existing tools (Status Browser, BitEditor, Theme Studio) be moved to `.gui` files? | only when each is next changed for another reason |
| 7 | The Builder's name | "GUI Builder" until you name it |
