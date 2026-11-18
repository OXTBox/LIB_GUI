# LIB_GUI

Monday, November 16, 2026. Plan: `PLAN.md`. Built so far (18 Nov): the `.gui` reader, the native face, panels, sliders, tabs, views and resizing by `stick=`; see `NEXT.md`.

A window as a small text file (`.gui`: one widget a line), shown by any "face": real xTalk
controls here, raygui inside xt3d (LIB_RAYGUI), vector lines and Python later. Plus the GUI
Builder, the app that makes those files, so a tool window can be made, wired and run without
the old IDE. xTalk is the scripting language, from the HyperCard family.

```
gui	1
window	Notes	420,300	Notes
field	note	8,8,404,240	stick=left,top,right,bottom
button	save	8,260,100,28	Save
```

| It owns | It leaves to |
|---|---|
| the `.gui` format, the widget kinds, `Gui.*`, `guiDo`, the native face, the Builder | colours: LIB_THEME. Who and titles: LIB_USERS. raygui drawing: LIB_RAYGUI. The launcher: LIB_TOOLBAR |
