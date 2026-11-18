script "lib_gui"
######################################################################################
## lib_gui (LIB_GUI, 11 17 2026): a window as a small text file (.gui, one widget a line),
## shown by a "face". This file: the format (PLAN.md stage 1), the native face (stage 2: real
## xTalk controls, coloured by LIB_THEME) and stage 3's panel, slider, tabs, view and stick=.
##   start using stack ".../LIB_GUI/livecode/lib_gui.livecodescript"
##   put Gui.Load(tFolder & "/gui/notes.gui") into tLayoutA   read and check a .gui file
##   put Gui.Problems() into tWrong                 what the last read (and build) found wrong
##   put Gui.Text(tLayoutA) into tText               the layout as text again
##   Gui.Save tLayoutA, tFile                        ... into a file
##   Gui.Build tLayoutA, "Notes"                     the native face: a themed stack, its controls
##   go stack "Notes"                                show it
##   Gui.Set "note", "hello"  /  put Gui.Get("note") into tNote
##   Gui.Show "save", false   /  Gui.Enable "save", false
##   on guiDo pName, pValue  ... end guiDo            in the window's script: a widget was used
##   Gui.Resize 700, 500                             lays the window out again by each stick=
##                                                   (a built window does it on resizeStack itself)
## Stage 3 kinds (native face):
##   panel   a group with a face (a filled box); widgets with in=<panel> live in it, their places
##           counting from its top left. A label shows as a small title at its top
##   slider  a scale scrollbar from min= to max= (0 and 100 by default); whole numbers unless
##           min or max has a decimal point (then 1000 steps between them). Fires when let go
##   tabs    drawn tabs (LIB_THEME's tab rule, never the native tab control) on a page; picking a
##           tab shows the widgets with tab=<tabs>:<item> and hides the rest of its pages
##   view    an empty rectangle the app draws in (the 3D picture, a map): here a placeholder face,
##           a dark box with its label in the middle. Gui.Get gives its rect now; a click fires
##           with the point inside it (x,y)
## Native look (dark theme): menus and choices are dark with light text when closed and switch to
## dark text while their list is open (LIB_THEME's menu rule); a list's selected line is light
## text on the hilite colour; a field's hint= shows dimmed while it is empty (Gui.Get gives empty).
## The layout array:
##   tLayoutA["gui"]                     the format's number (1)
##   tLayoutA["order"]                   the widget names, one a line, in file order
##   tLayoutA["widget"][name]["kind"]    and ["place"] (x,y,w,h as written; a window: w,h),
##                                       ["label"], ["opt"][key], ["optkeys"] (one a line, in order)
##   tLayoutA["entries"], tLayoutA["entry"][n]["name" | "raw"]   every line of the file, so
##                                       comments and lines it could not read are written back as they were
## Widgets are kept under ["widget"] (not straight under the layout, as PLAN.md section 4
## sketched) so a widget may be called "order" or "gui".
######################################################################################

constant kKinds = "window panel label button toggle choice list field text slider tabs menu view line"
constant kNativeKinds = "window panel label button toggle choice list field text slider tabs menu view line"
constant kTabHeight = 24
constant kOptions = "do tip hint stick in tab value min max key may theme float glyph"
constant kMenuBarHeight = 28

local sProblems   -- what the last read found wrong, one a line; the native face adds its own
local sStack      -- long id of the window Gui.Get / Set / Show / Enable act on
local sFace       -- the face in use: "native" (the only one in this file)
local sLastFired  -- the last use a face reported: name & tab & value & tab & message
local sInGroup    -- while building: the short id of the panel (group) new controls go in

## ---------------------------------------------------------------------------------
## The format
## ---------------------------------------------------------------------------------

function Gui.Load pFile
   local tText, tLayoutA
   if there is not a file pFile then
      put "file not found:" && pFile into sProblems
      return tLayoutA
   end if
   put textDecode(url ("binfile:" & pFile), "UTF-8") into tText
   return Gui.Parse(tText)
end Gui.Load

function Gui.Problems
   return sProblems
end Gui.Problems

function Gui.Parse pText
   local tLayoutA, tLine, tN, tE, tSeenGui, tFields, tName, tWidgetA, tWhy, tKind, tIn
   put empty into sProblems
   put 1 into tLayoutA["gui"]
   put empty into tLayoutA["order"]
   put 0 into tE
   put false into tSeenGui
   replace (numToChar(13) & numToChar(10)) with numToChar(10) in pText
   replace numToChar(13) with numToChar(10) in pText
   put 0 into tN
   repeat for each line tLine in pText
      add 1 to tN
      add 1 to tE
      put tLine into tLayoutA["entry"][tE]["raw"]
      if word 1 to -1 of tLine is empty or char 1 of word 1 of tLine is "#" then next repeat
      put guiSplit(tLine) into tFields
      put line 1 of tFields into tKind
      if not tSeenGui then
         put true into tSeenGui
         if tKind is "gui" then
            if line 2 of tFields is a number then
               put line 2 of tFields into tLayoutA["gui"]
               if line 2 of tFields > 1 then
                  guiProblem tN, "format" && line 2 of tFields && "is newer than this reader (1): read as well as it can"
               end if
            else
               guiProblem tN, "the gui line has no number"
            end if
            next repeat
         else
            guiProblem tN, "the file does not start with" && quote & "gui 1" & quote & ": read as format 1"
         end if
      else if tKind is "gui" then
         guiProblem tN, "a second gui line: kept as it is"
         next repeat
      end if
      put guiWidget(tFields) into tWidgetA
      put tWidgetA["why"] into tWhy
      if tWhy is not empty then
         guiProblem tN, tWhy & ": line kept as it is, not loaded"
         next repeat
      end if
      put tWidgetA["name"] into tName
      if tName is among the lines of tLayoutA["order"] then
         guiProblem tN, "two widgets named" && quote & tName & quote & ": line kept as it is, not loaded"
         next repeat
      end if
      delete variable tWidgetA["why"]
      delete variable tWidgetA["name"]
      delete variable tWidgetA["seen"]
      put tWidgetA into tLayoutA["widget"][tName]
      if tLayoutA["order"] is empty then
         put tName into tLayoutA["order"]
      else
         put return & tName after tLayoutA["order"]
      end if
      put tName into tLayoutA["entry"][tE]["name"]
      put empty into tLayoutA["entry"][tE]["raw"]
      put tN into tLayoutA["widget"][tName]["line"]
      guiNotes tN, tName, tLayoutA["widget"][tName]
   end repeat
   put tE into tLayoutA["entries"]
   -- in= must name a panel of this file
   repeat for each line tName in tLayoutA["order"]
      put tLayoutA["widget"][tName]["opt"]["in"] into tIn
      if tIn is empty then next repeat
      if tLayoutA["widget"][tIn]["kind"] is not "panel" then
         guiProblem tLayoutA["widget"][tName]["line"], quote & tName & quote && "is in=" & tIn & ", which is not a panel of this file: placed on the window"
      end if
   end repeat
   -- tab= must name tabs of this file and one of their items
   repeat for each line tName in tLayoutA["order"]
      put tLayoutA["widget"][tName]["opt"]["tab"] into tIn
      if tIn is empty then next repeat
      put guiTabCheck(tIn, tLayoutA) into tWhy
      if tWhy is not empty then
         guiProblem tLayoutA["widget"][tName]["line"], quote & tName & quote && "is tab=" & tIn & ":" && tWhy & ": always shown"
      end if
   end repeat
   return tLayoutA
end Gui.Parse

-- what is wrong with a tab=<tabs>:<item> (empty when nothing)
private function guiTabCheck pTab, pLayoutA
   local tStrip, tItem
   if ":" is not in pTab then return "it needs <tabs>:<item>"
   put char 1 to offset(":", pTab) - 1 of pTab into tStrip
   put char offset(":", pTab) + 1 to -1 of pTab into tItem
   if pLayoutA["widget"][tStrip]["kind"] is not "tabs" then return tStrip && "is not tabs of this file"
   if tItem is not among the lines of guiItems(pLayoutA["widget"][tStrip]["label"]) then return tItem && "is not one of its tabs"
   return empty
end guiTabCheck

-- one line's fields (tabs between them, empty ones skipped), one a line
private function guiSplit pLine
   local tField, tOut
   set the itemDelimiter to tab
   repeat for each item tField in pLine
      put word 1 to -1 of tField into tField
      if tField is empty then next repeat
      put tField & return after tOut
   end repeat
   delete the last char of tOut
   return tOut
end guiSplit

-- the fields of one line as a widget; ["why"] says what makes it unreadable
private function guiWidget pFields
   local tW, tField, tKey, tPlace, tN, tWant
   put line 1 of pFields into tW["kind"]
   put line 2 of pFields into tW["name"]
   if tW["name"] is empty or guiIsPlace(tW["name"]) or "=" is in tW["name"] then
      put tW["kind"] && "has no name" into tW["why"]
      return tW
   end if
   put empty into tW["optkeys"]
   put 2 into tN
   repeat for each line tField in line 3 to -1 of pFields
      if "=" is in tField then
         put char 1 to offset("=", tField) - 1 of tField into tKey
         if tKey is empty or the number of words of tKey is not 1 then
            put "an option with no name (" & tField & ")" into tW["why"]
            return tW
         end if
         if tKey is among the lines of tW["optkeys"] then
            put "option" && tKey && "given twice" into tW["why"]
            return tW
         end if
         put char offset("=", tField) + 1 to -1 of tField into tW["opt"][tKey]
         put tKey & return after tW["optkeys"]
      else if guiIsNumberList(tField) then
         if tW["place"] is not empty then
            put "two places (" & tW["place"] & " and " & tField & ")" into tW["why"]
            return tW
         end if
         put 4 into tWant
         if tW["kind"] is "window" then put 2 into tWant
         set the itemDelimiter to comma
         if the number of items of tField is not tWant then
            put "a place needs" && tWant && "numbers (" & tField & ")" into tW["why"]
            return tW
         end if
         put tField into tW["place"]
      else
         if tW["seen"] is true then
            put "two labels (" & tW["label"] & " and " & tField & ")" into tW["why"]
            return tW
         end if
         put tField into tW["label"]
         put true into tW["seen"]
      end if
   end repeat
   if tW["optkeys"] is not empty then delete the last char of tW["optkeys"]
   return tW
end guiWidget

-- notes that do not stop a widget loading
private command guiNotes pLine, pName, pWidgetA
   local tKey
   if pWidgetA["kind"] is not among the words of kKinds then
      guiProblem pLine, "unknown kind" && quote & pWidgetA["kind"] & quote && "(" & pName & "): kept, faces skip it"
   else if pWidgetA["place"] is empty and pWidgetA["kind"] is not among the words of "window menu" then
      guiProblem pLine, quote & pName & quote && "has no place: faces put it at the top left"
   end if
   repeat for each line tKey in pWidgetA["optkeys"]
      if tKey is among the words of kOptions then next repeat
      if tKey begins with "x-" then next repeat
      guiProblem pLine, "unknown option" && quote & tKey & quote && "(" & pName & "): kept, faces ignore it"
   end repeat
end guiNotes

private command guiProblem pLine, pWhat
   if sProblems is not empty then put return after sProblems
   if pLine is 0 or pLine is empty then
      put pWhat after sProblems
   else
      put "line" && pLine & ":" && pWhat after sProblems
   end if
end guiProblem

-- two or more whole numbers with commas between: a place, or a place written wrong
private function guiIsNumberList pField
   replace space with empty in pField
   return matchText(pField, "^-?[0-9]+(,-?[0-9]+)+$")
end guiIsNumberList

private function guiIsPlace pField
   return guiIsNumberList(pField)
end guiIsPlace

-- the layout as text: the kind, the name, the place, the label, then the options in their order;
-- comments, blank lines and lines it could not read come back as they were
function Gui.Text pLayoutA
   local tOut, tE, tName, tDone, tHasGui, tFields
   put false into tHasGui
   repeat with tE = 1 to pLayoutA["entries"]
      put pLayoutA["entry"][tE]["name"] into tName
      if tName is empty then
         put pLayoutA["entry"][tE]["raw"] & return after tOut
         put guiSplit(pLayoutA["entry"][tE]["raw"]) into tFields
         if line 1 of tFields is "gui" then
            put true into tHasGui
         end if
      else if pLayoutA["widget"][tName]["kind"] is not empty then
         put guiLine(tName, pLayoutA["widget"][tName]) & return after tOut
         put tName & return after tDone
      end if
   end repeat
   -- widgets added since the file was read
   repeat for each line tName in pLayoutA["order"]
      if tName is among the lines of tDone then next repeat
      if pLayoutA["widget"][tName]["kind"] is empty then next repeat
      put guiLine(tName, pLayoutA["widget"][tName]) & return after tOut
   end repeat
   if not tHasGui then
      if pLayoutA["gui"] is empty then
         put "gui" & tab & 1 & return before tOut
      else
         put "gui" & tab & pLayoutA["gui"] & return before tOut
      end if
   end if
   if char -1 of tOut is return then delete char -1 of tOut
   return tOut
end Gui.Text

private function guiLine pName, pWidgetA
   local tOut, tKey
   put pWidgetA["kind"] & tab & pName into tOut
   if pWidgetA["place"] is not empty then put tab & pWidgetA["place"] after tOut
   if pWidgetA["label"] is not empty then put tab & pWidgetA["label"] after tOut
   repeat for each line tKey in pWidgetA["optkeys"]
      put tab & tKey & "=" & pWidgetA["opt"][tKey] after tOut
   end repeat
   return tOut
end guiLine

command Gui.Save pLayoutA, pFile
   put textEncode(Gui.Text(pLayoutA) & return, "UTF-8") into url ("binfile:" & pFile)
   return the result
end Gui.Save

## ---------------------------------------------------------------------------------
## Faces
## ---------------------------------------------------------------------------------

function Gui.Face
   if sFace is empty then return "native"
   return sFace
end Gui.Face

command Gui.UseFace pName
   if pName is not "native" then
      guiProblem 0, "face" && quote & pName & quote && "is not in this library yet: the native face is used"
      put "native" into pName
   end if
   put pName into sFace
end Gui.UseFace

## ---------------------------------------------------------------------------------
## The native face: a stack and real xTalk controls, coloured by LIB_THEME
## ---------------------------------------------------------------------------------

-- builds pStack from the layout (makes the stack when there is none; a stack that exists keeps
-- its script). pScript, when given, becomes the new stack's script (its guiDo and do= handlers);
-- the house closeStackRequest is added to it when missing. The stack is not shown: go to it.
command Gui.Build pLayoutA, pStack, pScript
   local tWin, tW, tH, tTheme, tName, tWidgetA, tCard, tMenuX, tObj, tKind, tTitle, tAbsA, tIn, n
   put empty into tWin
   repeat for each line tName in pLayoutA["order"]
      if pLayoutA["widget"][tName]["kind"] is "window" then
         put tName into tWin
         exit repeat
      end if
   end repeat
   if pStack is empty then put tWin into pStack
   if pStack is empty then put "GuiWindow" into pStack
   put 400 into tW
   put 300 into tH
   if tWin is not empty and pLayoutA["widget"][tWin]["place"] is not empty then
      set the itemDelimiter to comma
      put item 1 of pLayoutA["widget"][tWin]["place"] into tW
      put item 2 of pLayoutA["widget"][tWin]["place"] into tH
   end if
   put pLayoutA["widget"][tWin]["opt"]["theme"] into tTheme
   if tTheme is empty then put "dark" into tTheme
   guiUseTheme tTheme

   lock screen
   lock messages
   Theme.Begin
   if there is not a stack pStack then
      create stack pStack
      put pScript into tObj
      if tObj is empty then put "-- built by lib_gui from a .gui file" into tObj
      if not (tObj contains "on closeStackRequest") then
         put return & "on closeStackRequest" & return & "   set the destroyStack of this stack to true" & return \
               & "   close stack (the mainStack of this stack)" & return & "end closeStackRequest" after tObj
      end if
      -- stick=: an app with its own resizeStack calls Gui.Resize in it
      if not (tObj contains "on resizeStack") then
         put return & "on resizeStack pNewWidth, pNewHeight" & return & "   Gui.Window the short name of me" & return \
               & "   Gui.Resize pNewWidth, pNewHeight" & return & "   pass resizeStack" & return & "end resizeStack" after tObj
      end if
      set the script of stack pStack to tObj
      if the result is not empty then guiProblem 0, "native: the window script does not compile:" && the result
   end if
   set the destroyStack of stack pStack to true
   set the width of stack pStack to tW
   set the height of stack pStack to tH
   set the resizable of stack pStack to true
   set the uGuiSize of stack pStack to tW & comma & tH
   put the label of stack pStack into tTitle
   if tWin is not empty then
      put guiTitle(pLayoutA["widget"][tWin]["label"], tWin) into tTitle
      set the label of stack pStack to tTitle
      guiWindowOptions pStack, pLayoutA["widget"][tWin]
   end if
   put the long id of stack pStack into sStack
   set the defaultStack to pStack
   put the long id of card 1 of stack pStack into tCard
   put 0 into tMenuX
   put guiAbsRects(pLayoutA) into tAbsA
   repeat for each line tName in guiBuildOrder(pLayoutA)
      put pLayoutA["widget"][tName] into tWidgetA
      put tWidgetA["kind"] into tKind
      if tKind is "window" then next repeat
      if tKind is not among the words of kNativeKinds then
         guiProblem tWidgetA["line"], "native: does not draw" && tKind && "yet (" & tName & "): skipped"
         next repeat
      end if
      if there is a control tName of tCard then delete control tName of tCard
      put empty into sInGroup
      put tWidgetA["opt"]["in"] into tIn
      if tIn is not empty and tKind is among the words of "menu tabs" then
         guiProblem tWidgetA["line"], "native:" && tKind && "in a panel not done yet (" & tName & "): placed on the window"
      else if tIn is not empty and there is a group tIn of tCard then
         put the short id of group tIn of tCard into sInGroup
      end if
      if tKind is "menu" then
         if tMenuX is 0 then
            Theme.MenuBar pStack, 0, 0, tW, kMenuBarHeight
            put the result into tObj
            set the uGuiPart of tObj to "bar"
            set the uGuiStick of tObj to "left,top,right"
            put 4 into tMenuX
         end if
         guiMakeMenu tName, tWidgetA, tMenuX
         add the result + 2 to tMenuX
      else
         put tAbsA[tName] into tWidgetA["abs"]
         guiMake tName, tWidgetA
      end if
   end repeat
   put empty into sInGroup
   guiKeepRects tCard
   Theme.ApplyStack pStack
   guiAfterTheme tCard
   -- each tabs shows its first page (or its value=)
   repeat with n = 1 to the number of controls of tCard
      put the long id of control n of tCard into tObj
      if the uGuiKind of tObj is "tabs" then
         guiTabShow tObj, the uGuiValue of tObj
      end if
   end repeat
   Theme.End
   unlock messages
   unlock screen
   return sStack
end Gui.Build

-- every widget's place on the window (left,top,right,bottom): one in=<panel> counts from the panel
private function guiAbsRects pLayoutA
   local tName, tOutA, tRect, tIn, tPlace, n
   repeat for each line tName in pLayoutA["order"]
      put guiRect(pLayoutA["widget"][tName]["place"], pLayoutA["widget"][tName]["kind"]) into tRect
      put pLayoutA["widget"][tName]["opt"]["in"] into tIn
      put 0 into n
      repeat while tIn is not empty and n < 10
         if pLayoutA["widget"][tIn]["kind"] is not "panel" then exit repeat
         put guiRect(pLayoutA["widget"][tIn]["place"], "panel") into tPlace
         put guiShift(tRect, item 1 of tPlace, item 2 of tPlace) into tRect
         put pLayoutA["widget"][tIn]["opt"]["in"] into tIn
         add 1 to n
      end repeat
      put tRect into tOutA[tName]
   end repeat
   return tOutA
end guiAbsRects

-- a rect moved by pDX, pDY
private function guiShift pRect, pDX, pDY
   set the itemDelimiter to comma
   return (item 1 of pRect + pDX) & comma & (item 2 of pRect + pDY) & comma & (item 3 of pRect + pDX) & comma & (item 4 of pRect + pDY)
end guiShift

-- the order controls are made in: tabs (their page lies under what is put on it), then panels,
-- a panel before the panels in it, then the rest as the file has them
private function guiBuildOrder pLayoutA
   local tName, tOut, tDepthA, tIn, n, tDepth, tMax, tRest
   put 0 into tMax
   repeat for each line tName in pLayoutA["order"]
      switch pLayoutA["widget"][tName]["kind"]
         case "tabs"
            put tName & return after tOut
            break
         case "panel"
            put 0 into n
            put pLayoutA["widget"][tName]["opt"]["in"] into tIn
            repeat while tIn is not empty and n < 10
               if pLayoutA["widget"][tIn]["kind"] is not "panel" then exit repeat
               add 1 to n
               put pLayoutA["widget"][tIn]["opt"]["in"] into tIn
            end repeat
            put tName & return after tDepthA[n]
            put max(tMax, n) into tMax
            break
         default
            put tName & return after tRest
      end switch
   end repeat
   repeat with tDepth = 0 to tMax
      put tDepthA[tDepth] after tOut
   end repeat
   return tOut & tRest
end guiBuildOrder

-- each control's place when built (a line: its two points), kept for Gui.Resize
private command guiKeepRects pCard
   local n, tObj
   repeat with n = 1 to the number of controls of pCard
      put the long id of control n of pCard into tObj
      if the uGuiKind of tObj is empty and the uGuiPart of tObj is empty then next repeat
      if the uGuiRect of tObj is not empty then next repeat
      if the uGuiKind of tObj is "line" then
         set the uGuiRect of tObj to guiPointsRect(the points of tObj)
      else
         set the uGuiRect of tObj to the rect of tObj
      end if
   end repeat
end guiKeepRects

private function guiPointsRect pPoints
   return line 1 of pPoints & comma & line 2 of pPoints
end guiPointsRect

-- loads LIB_THEME (next to LIB_GUI) when it is not in use yet, and the window's theme
private command guiUseTheme pTheme
   local tPath
   if "lib_theme" is not among the lines of the stacksInUse then
      put guiFolder() into tPath
      set the itemDelimiter to "/"
      put item 1 to -2 of tPath & "/LIB_THEME/livecode/lib_theme.livecodescript" into tPath
      start using stack tPath
   end if
   Theme.Use pTheme
   if the result is not empty then
      guiProblem 0, "native:" && the result & ": dark used"
      Theme.Use "dark"
   end if
end guiUseTheme

-- the LIB_GUI folder (this script is in its livecode/ folder)
private function guiFolder
   local tPath
   put the effective filename of stack "lib_gui" into tPath
   set the itemDelimiter to "/"
   return item 1 to -3 of tPath
end guiFolder

-- the window's title comes from LIB_USERS when it is in use (never built by hand)
private function guiTitle pLabel, pName
   local tWhat
   put pLabel into tWhat
   if tWhat is empty then put pName into tWhat
   if "LIB_USERS" is among the lines of the stacksInUse then
      return Users.Title(tWhat)
   end if
   return "FOR OWNER |" && tWhat
end guiTitle

private command guiWindowOptions pStack, pWidgetA
   local tMin
   put pWidgetA["opt"]["min"] into tMin
   set the itemDelimiter to comma
   if the number of items of tMin is 2 then
      if item 1 of tMin is an integer and item 2 of tMin is an integer then
         set the minWidth of stack pStack to item 1 of tMin
         set the minHeight of stack pStack to item 2 of tMin
      end if
   end if
   set the uGuiKind of stack pStack to "window"
   if pWidgetA["opt"]["float"] is not empty then
      guiProblem pWidgetA["line"], "native: float=" & pWidgetA["opt"]["float"] && "not done yet"
   end if
end guiWindowOptions

-- x,y,w,h -> left,top,right,bottom (no place: top left, a usual size)
private function guiRect pPlace, pKind
   local tX, tY, tW, tH
   set the itemDelimiter to comma
   if pPlace is empty then
      put 8 into tX
      put 8 into tY
      put 100 into tW
      put 24 into tH
   else
      put item 1 of pPlace into tX
      put item 2 of pPlace into tY
      put item 3 of pPlace into tW
      put item 4 of pPlace into tH
   end if
   if pKind is not "line" then
      put max(tW, 1) into tW
      put max(tH, 1) into tH
   end if
   return tX & comma & tY & comma & (tX + tW) & comma & (tY + tH)
end guiRect

-- a label's items: "|" between them
private function guiItems pLabel
   replace "|" with return in pLabel
   return pLabel
end guiItems

private command guiMakeMenu pName, pWidgetA, pX
   local tB, tW
   reset the templateButton
   create button pName
   put it into tB
   set the style of tB to "menu"
   set the menuMode of tB to "pulldown"
   set the label of tB to pName
   set the text of tB to guiItems(pWidgetA["label"])
   put max(48, 9 * the number of chars of pName + 20) into tW
   set the rect of tB to pX, 2, pX + tW, kMenuBarHeight - 2
   set the script of tB to guiMenuScript()
   guiTag tB, "menu", pName, pWidgetA
   return tW
end guiMakeMenu

-- a new control of pType on the current card, or in the panel being built (sInGroup)
private function guiNew pType, pName
   local tGid
   put sInGroup into tGid
   switch pType
      case "button"
         if tGid is empty then
            create button pName
         else
            create button pName in group id tGid
         end if
         break
      case "field"
         if tGid is empty then
            create field pName
         else
            create field pName in group id tGid
         end if
         break
      case "graphic"
         if tGid is empty then
            create graphic pName
         else
            create graphic pName in group id tGid
         end if
         break
      case "scrollbar"
         if tGid is empty then
            create scrollbar pName
         else
            create scrollbar pName in group id tGid
         end if
         break
      case "group"
         if tGid is empty then
            create group pName
         else
            create group pName in group id tGid
         end if
         break
   end switch
   return it
end guiNew

private command guiMake pName, pWidgetA
   local tKind, tObj, tRect, tValue, tScript, tLabel
   put pWidgetA["kind"] into tKind
   put pWidgetA["abs"] into tRect
   if tRect is empty then put guiRect(pWidgetA["place"], tKind) into tRect
   put pWidgetA["opt"]["value"] into tValue
   put pWidgetA["label"] into tLabel
   reset the templateButton
   reset the templateField
   reset the templateGraphic
   switch tKind
      case "label"
         put guiNew("field", pName) into tObj
         set the rect of tObj to tRect
         set the lockText of tObj to true
         set the traversalOn of tObj to false
         set the dontWrap of tObj to true
         set the text of tObj to tLabel
         break
      case "button"
         put guiNew("button", pName) into tObj
         set the rect of tObj to tRect
         set the label of tObj to tLabel
         put "on mouseUp" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" into tScript
         break
      case "toggle"
         put guiNew("button", pName) into tObj
         set the style of tObj to "checkbox"
         set the rect of tObj to tRect
         set the label of tObj to tLabel
         set the hilite of tObj to (tValue is true)
         put "on mouseUp" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" into tScript
         break
      case "choice"
         put guiNew("button", pName) into tObj
         set the style of tObj to "menu"
         set the menuMode of tObj to "option"
         set the rect of tObj to tRect
         set the text of tObj to guiItems(tLabel)
         if tValue is not empty and tValue is among the lines of guiItems(tLabel) then
            set the menuHistory of tObj to lineOffset(tValue, guiItems(tLabel))
         else
            set the menuHistory of tObj to 1
         end if
         put guiMenuScript() into tScript
         break
      case "list"
         put guiNew("field", pName) into tObj
         set the rect of tObj to tRect
         set the listBehavior of tObj to true
         set the lockText of tObj to true
         set the dontWrap of tObj to true
         set the vScrollbar of tObj to true
         set the text of tObj to guiItems(tLabel)
         if tValue is not empty and tValue is among the lines of the text of tObj then
            set the hilitedLines of tObj to lineOffset(tValue, the text of tObj)
         end if
         put "on mouseUp" & return & "   Gui.ListMark the long id of me" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" & return \
               & "on selectionChanged" & return & "   Gui.ListMark the long id of me" & return & "end selectionChanged" into tScript
         break
      case "field"
         put guiNew("field", pName) into tObj
         set the rect of tObj to tRect
         set the dontWrap of tObj to true
         set the autoTab of tObj to true
         if tValue is not empty then
            set the text of tObj to tValue
         else
            set the text of tObj to tLabel
         end if
         guiHintStart tObj, pWidgetA["opt"]["hint"]
         put "on returnInField" & return & "   Gui.Fire the long id of me" & return & "end returnInField" & return \
               & guiFieldScript() into tScript
         break
      case "text"
         put guiNew("field", pName) into tObj
         set the rect of tObj to tRect
         set the vScrollbar of tObj to true
         if tValue is not empty then
            set the text of tObj to tValue
         else
            set the text of tObj to tLabel
         end if
         guiHintStart tObj, pWidgetA["opt"]["hint"]
         put guiFieldScript() into tScript
         break
      case "line"
         put guiNew("graphic", pName) into tObj
         set the style of tObj to "line"
         set the itemDelimiter to comma
         set the points of tObj to (item 1 to 2 of tRect) & return & (item 3 to 4 of tRect)
         set the foregroundColor of tObj to Theme.Get("dim")
         set the uThemeSkip of tObj to true
         break
      case "panel"
         put guiMakePanel(pName, tRect, tLabel) into tObj
         break
      case "slider"
         put guiNew("scrollbar", pName) into tObj
         guiSliderStart tObj, tRect, pWidgetA
         put "on mouseUp" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" & return \
               & "on mouseRelease" & return & "   Gui.Fire the long id of me" & return & "end mouseRelease" into tScript
         break
      case "tabs"
         put guiMakeTabs(pName, tRect, tLabel, tValue) into tObj
         break
      case "view"
         put guiNew("graphic", pName) into tObj
         set the style of tObj to "rectangle"
         set the rect of tObj to tRect
         set the filled of tObj to true
         set the opaque of tObj to true
         set the lineSize of tObj to 1
         set the backgroundColor of tObj to Theme.Get("bg")
         set the foregroundColor of tObj to Theme.Get("dim")
         if tLabel is empty then put "view" into tLabel
         set the label of tObj to tLabel
         set the showName of tObj to true
         set the uThemeSkip of tObj to true
         put "on mouseUp" & return & "   Gui.ViewClick the long id of me" & return & "end mouseUp" into tScript
         break
   end switch
   if tScript is not empty then set the script of tObj to tScript
   guiTag tObj, tKind, pName, pWidgetA
   if pWidgetA["opt"]["in"] is not empty and sInGroup is not empty then
      set the uGuiAnchor of tObj to pWidgetA["opt"]["in"]
   end if
end guiMake

-- a panel: a group holding a face (a filled box) and, when it has a label, a small title
private function guiMakePanel pName, pRect, pLabel
   local tG, tObj, tOld
   put guiNew("group", pName) into tG
   set the lockLoc of tG to true
   set the rect of tG to pRect
   set the showBorder of tG to false
   put sInGroup into tOld
   put the short id of tG into sInGroup
   put guiNew("graphic", pName & "_face") into tObj
   set the style of tObj to "rectangle"
   set the rect of tObj to pRect
   set the filled of tObj to true
   set the opaque of tObj to true
   set the lineSize of tObj to 1
   set the backgroundColor of tObj to Theme.Get("panel")
   set the foregroundColor of tObj to Theme.Get("border")
   guiPart tObj, "face", pName, "left,top,right,bottom"
   if pLabel is not empty then
      set the itemDelimiter to comma
      put guiNew("field", pName & "_title") into tObj
      set the rect of tObj to (item 1 of pRect + 6), (item 2 of pRect + 2), max(item 1 of pRect + 7, item 3 of pRect - 6), (item 2 of pRect + 22)
      set the lockText of tObj to true
      set the traversalOn of tObj to false
      set the dontWrap of tObj to true
      set the opaque of tObj to false
      set the showBorder of tObj to false
      set the textStyle of tObj to "bold"
      set the foregroundColor of tObj to Theme.Get("dim")
      set the text of tObj to pLabel
      guiPart tObj, "title", pName, "left,top,right"
   end if
   put tOld into sInGroup
   set the uGuiLabel of tG to pLabel
   return tG
end guiMakePanel

-- a control that is part of a widget (not one itself): coloured here, laid out with its widget
private command guiPart pObj, pPart, pAnchor, pStick
   set the uThemeSkip of pObj to true
   set the uGuiPart of pObj to pPart
   set the uGuiAnchor of pObj to pAnchor
   set the uGuiStick of pObj to pStick
end guiPart

-- a slider: a scale from min= to max=, at value= (else min=)
private command guiSliderStart pObj, pRect, pWidgetA
   local tMin, tMax, tValue
   put pWidgetA["opt"]["min"] into tMin
   put pWidgetA["opt"]["max"] into tMax
   if tMin is not a number then put 0 into tMin
   if tMax is not a number then put 100 into tMax
   if tMax < tMin then put tMin into tMax
   set the style of pObj to "scale"
   set the rect of pObj to pRect
   set the showValue of pObj to false
   set the uGuiMin of pObj to tMin
   set the uGuiMax of pObj to tMax
   -- a scrollbar holds whole numbers: a slider with fractions runs 0..1000 inside
   set the uGuiWhole of pObj to not ("." is in tMin or "." is in tMax)
   if the uGuiWhole of pObj is true then
      set the startValue of pObj to tMin
      set the endValue of pObj to tMax
   else
      set the startValue of pObj to 0
      set the endValue of pObj to 1000
   end if
   put pWidgetA["opt"]["value"] into tValue
   if tValue is not a number then put tMin into tValue
   guiSliderSet pObj, tValue
end guiSliderStart

private command guiSliderSet pObj, pValue
   local tMin, tMax
   put the uGuiMin of pObj into tMin
   put the uGuiMax of pObj into tMax
   put max(tMin, min(tMax, pValue)) into pValue
   if the uGuiWhole of pObj is true then
      set the thumbPosition of pObj to round(pValue)
   else if tMax > tMin then
      set the thumbPosition of pObj to round(1000 * (pValue - tMin) / (tMax - tMin))
   else
      set the thumbPosition of pObj to 0
   end if
end guiSliderSet

private function guiSliderGet pObj
   local tMin, tMax
   if the uGuiWhole of pObj is true then return round(the thumbPosition of pObj)
   put the uGuiMin of pObj into tMin
   put the uGuiMax of pObj into tMax
   return tMin + (tMax - tMin) * (the thumbPosition of pObj) / 1000
end guiSliderGet

-- tabs: a page (a filled box, named as the widget) with LIB_THEME's drawn tabs along its top
private function guiMakeTabs pName, pRect, pLabel, pValue
   local tPage, tItems, tTabW, tItem, tMost, n, tF, tL, tT, tR, tB
   set the itemDelimiter to comma
   put item 1 of pRect into tL
   put item 2 of pRect into tT
   put item 3 of pRect into tR
   put item 4 of pRect into tB
   put guiItems(pLabel) into tItems
   if tItems is empty then put "1" into tItems
   put guiNew("graphic", pName) into tPage
   set the style of tPage to "rectangle"
   set the rect of tPage to tL, (tT + kTabHeight - 1), tR, max(tT + kTabHeight, tB)
   set the filled of tPage to true
   set the opaque of tPage to true
   set the lineSize of tPage to 1
   set the backgroundColor of tPage to Theme.Get("panel")
   set the foregroundColor of tPage to Theme.Get("border")
   set the uThemeSkip of tPage to true
   put 0 into tMost
   repeat for each line tItem in tItems
      put max(tMost, the number of chars of tItem) into tMost
   end repeat
   put min(8 * tMost + 28, max(40, (tR - tL) div the number of lines of tItems)) into tTabW
   put 1 into n
   repeat while there is a field ("tab_" & pName & "_" & n)
      delete field ("tab_" & pName & "_" & n)
      add 1 to n
   end repeat
   Theme.TabStrip pName, tItems, tL, tT, tTabW, kTabHeight
   put 1 into n
   repeat while there is a field ("tab_" & pName & "_" & n)
      put the long id of field ("tab_" & pName & "_" & n) into tF
      set the script of tF to "on mouseDown" & return & "   Gui.TabPick the long id of me" & return & "end mouseDown"
      guiPart tF, "tab", pName, "left,top"
      add 1 to n
   end repeat
   set the uGuiItems of tPage to tItems
   if pValue is not among the lines of tItems then put line 1 of tItems into pValue
   set the uGuiValue of tPage to pValue
   return tPage
end guiMakeTabs

-- what every control carries, so the layout can be read back out of the built stack
private command guiTag pObj, pKind, pName, pWidgetA
   local tKey, tOpts
   set the uGuiKind of pObj to pKind
   set the uGuiName of pObj to pName
   set the uGuiDo of pObj to pWidgetA["opt"]["do"]
   set the uGuiSent of pObj to empty
   set the uGuiStick of pObj to pWidgetA["opt"]["stick"]
   set the uGuiTab of pObj to pWidgetA["opt"]["tab"]
   repeat for each line tKey in pWidgetA["optkeys"]
      put tab & tKey & "=" & pWidgetA["opt"][tKey] after tOpts
   end repeat
   set the uGuiOptions of pObj to char 2 to -1 of tOpts
   if pWidgetA["opt"]["tip"] is not empty then
      set the tooltip of pObj to pWidgetA["opt"]["tip"]
   else if pWidgetA["opt"]["hint"] is not empty then
      set the tooltip of pObj to pWidgetA["opt"]["hint"]
   end if
   if pWidgetA["opt"]["key"] is not empty then
      guiProblem pWidgetA["line"], "native: key=" & pWidgetA["opt"]["key"] && "not done yet (" & pName & ")"
   end if
   if pWidgetA["opt"]["may"] is not empty then
      guiProblem pWidgetA["line"], "native: may=" & pWidgetA["opt"]["may"] && "not checked yet, shown to all (" & pName & ")"
   end if
end guiTag

-- after Theme.ApplyStack: labels are words on the page, not boxes; menus and choices dark when
-- closed (LIB_THEME's menu rule still holds for their open list: see Gui.MenuOpen); lists show
-- their selected line in light text; a field's hint is dimmed; the menu strip is a dark bar
private command guiAfterTheme pCard
   local n, tObj, tKind
   repeat with n = 1 to the number of controls of pCard
      put the long id of control n of pCard into tObj
      put the uGuiKind of tObj into tKind
      if tKind is "label" then
         set the opaque of tObj to false
         set the showBorder of tObj to false
      else if tKind is among the words of "list field text" then
         set the opaque of tObj to true
         set the uGuiFaceText of tObj to Theme.Get("text")
         set the uGuiHintColor of tObj to Theme.Get("dim")
         if tKind is "list" then
            set the uGuiListText of tObj to guiHiliteText()
            Gui.ListMark tObj
         else if the uGuiHintOn of tObj is true then
            set the foregroundColor of tObj to Theme.Get("dim")
         end if
      else if tKind is among the words of "menu choice" then
         -- the menu rule: the open list is drawn on a light background in the button's text
         -- colour, so the button is dark text only while its list is open
         set the uGuiListText of tObj to Theme.Get("menuText")
         set the uGuiFaceText of tObj to Theme.Get("text")
         set the foregroundColor of tObj to Theme.Get("text")
         set the backgroundColor of tObj to Theme.Get("panel")
         if tKind is "menu" then
            set the showBorder of tObj to false
         end if
      end if
   end repeat
   if there is a graphic "Theme.MenuBar" of pCard then
      set the backgroundColor of graphic "Theme.MenuBar" of pCard to Theme.Get("panel")
      set the foregroundColor of graphic "Theme.MenuBar" of pCard to Theme.Get("panel")
   end if
end guiAfterTheme

-- the text colour of a list's selected line: the theme's hiliteText, else white
private function guiHiliteText
   if Theme.Get("hiliteText") is not empty then return Theme.Get("hiliteText")
   return "255,255,255"
end guiHiliteText

private function guiMenuScript
   return "on mouseDown" & return & "   Gui.MenuOpen the long id of me" & return & "   pass mouseDown" & return & "end mouseDown" & return \
         & "on menuPick pItem" & return & "   Gui.MenuRest the long id of me" & return & "   Gui.Fire the long id of me, pItem" & return & "end menuPick" & return \
         & "on mouseUp" & return & "   Gui.MenuRest the long id of me" & return & "end mouseUp" & return \
         & "on mouseRelease" & return & "   Gui.MenuRest the long id of me" & return & "end mouseRelease"
end guiMenuScript

private function guiFieldScript
   return "on openField" & return & "   Gui.HintOff the long id of me" & return & "end openField" & return \
         & "on closeField" & return & "   Gui.Fire the long id of me" & return & "   Gui.HintOn the long id of me" & return & "end closeField" & return \
         & "on exitField" & return & "   Gui.HintOn the long id of me" & return & "end exitField"
end guiFieldScript

-- a menu or choice is about to open its list: dark text for the light list (the menu rule)
command Gui.MenuOpen pObj
   if the uGuiListText of pObj is not empty then
      set the foregroundColor of pObj to the uGuiListText of pObj
   end if
end Gui.MenuOpen

-- its list closed: the theme's text colour again
command Gui.MenuRest pObj
   if the uGuiFaceText of pObj is not empty then
      set the foregroundColor of pObj to the uGuiFaceText of pObj
   end if
end Gui.MenuRest

-- a list's selected lines in light text (the field's hiliteColor is behind them)
command Gui.ListMark pObj
   local tLine, tColor
   put the uGuiListText of pObj into tColor
   if tColor is empty then exit Gui.ListMark
   lock screen
   set the foregroundColor of char 1 to -1 of pObj to empty
   set the itemDelimiter to comma
   repeat for each item tLine in the hilitedLines of pObj
      if tLine is an integer then
         set the foregroundColor of line tLine of pObj to tColor
      end if
   end repeat
   unlock screen
end Gui.ListMark

-- a field's hint: shown (dimmed) while the field is empty and not being typed in
private command guiHintStart pObj, pHint
   set the uGuiHint of pObj to pHint
   set the uGuiHintOn of pObj to false
   if pHint is not empty and the text of pObj is empty then
      set the text of pObj to pHint
      set the uGuiHintOn of pObj to true
   end if
end guiHintStart

-- typing starts (the field is entered): the hint goes
command Gui.HintOff pObj
   if the uGuiHintOn of pObj is not true then exit Gui.HintOff
   set the text of pObj to empty
   set the uGuiHintOn of pObj to false
   if the uGuiFaceText of pObj is not empty then
      set the foregroundColor of pObj to the uGuiFaceText of pObj
   end if
end Gui.HintOff

-- the field is left (or set) empty: the hint comes back
command Gui.HintOn pObj
   if the uGuiHint of pObj is empty then exit Gui.HintOn
   if the uGuiHintOn of pObj is true then exit Gui.HintOn
   if the text of pObj is not empty then exit Gui.HintOn
   set the text of pObj to the uGuiHint of pObj
   set the uGuiHintOn of pObj to true
   if the uGuiHintColor of pObj is not empty then
      set the foregroundColor of pObj to the uGuiHintColor of pObj
   end if
end Gui.HintOn

-- the stack a control is on
private function guiStackOf pObj
   local tObj
   put pObj into tObj
   repeat 20 times
      if word 1 of tObj is "stack" then return tObj
      put the long id of the owner of tObj into tObj
   end repeat
   return empty
end guiStackOf

-- a control was used: send guiDo pName, pValue (or the do= message with the value) to its window.
-- pValue is given by menus (the item picked); otherwise it is read from the control.
-- A field sends once for one text: return then leaving the field does not send twice.
command Gui.Fire pObj, pValue
   local tName, tKind, tDo, tStack
   put the uGuiName of pObj into tName
   put the uGuiKind of pObj into tKind
   put the uGuiDo of pObj into tDo
   if tKind is not among the words of "menu choice view" then put guiValueOf(pObj) into pValue
   if tKind is among the words of "field text" then
      if ("s" & the uGuiSent of pObj) is ("s" & pValue) then exit Gui.Fire
      set the uGuiSent of pObj to pValue
   end if
   put guiStackOf(pObj) into tStack
   put tStack into sStack
   if tDo is not empty then
      put tName & tab & pValue & tab & tDo into sLastFired
      dispatch tDo to tStack with pValue
   else
      put tName & tab & pValue & tab & "guiDo" into sLastFired
      dispatch "guiDo" to tStack with tName, pValue
   end if
end Gui.Fire

-- the last use a face reported: name, value, message (tabs between): for tests and the Builder's log
function Gui.LastFired
   return sLastFired
end Gui.LastFired

-- Gui.Get / Set / Show / Enable act on this window (Gui.Build and every use of a widget set it)
command Gui.Window pStack
   if there is a stack pStack then put the long id of stack pStack into sStack
end Gui.Window

private function guiControl pName
   local tCard, tErr
   if sStack is empty then return empty
   try
      put the long id of card 1 of sStack into tCard
   catch tErr
      return empty
   end try
   if there is not a control pName of tCard then return empty
   return the long id of control pName of tCard
end guiControl

private function guiValueOf pObj
   local tLines
   switch the uGuiKind of pObj
      case "toggle"
         return the hilite of pObj
      case "choice"
         return the label of pObj
      case "list"
         put the hilitedLines of pObj into tLines
         if tLines is empty then return empty
         return line (item 1 of tLines) of the text of pObj
      case "field"
      case "text"
         if the uGuiHintOn of pObj is true then return empty
         return the text of pObj
      case "label"
         return the text of pObj
      case "button"
         return the label of pObj
      case "menu"
         return the text of pObj
      case "panel"
         return the uGuiLabel of pObj
      case "slider"
         return guiSliderGet(pObj)
      case "tabs"
         return the uGuiValue of pObj
      case "view"
         return the rect of pObj
   end switch
   return empty
end guiValueOf

function Gui.Get pName
   local tObj
   put guiControl(pName) into tObj
   if tObj is empty then return empty
   return guiValueOf(tObj)
end Gui.Get

-- a list: one line that is in it selects that line; anything else becomes its lines.
-- a choice: picks the item (no menuPick is sent). menu: its items, "|" or a line between them.
command Gui.Set pName, pValue
   local tObj, tItems
   put guiControl(pName) into tObj
   if tObj is empty then return "no widget" && quote & pName & quote
   lock messages
   switch the uGuiKind of tObj
      case "toggle"
         set the hilite of tObj to (pValue is true)
         break
      case "choice"
         put the text of tObj into tItems
         if pValue is among the lines of tItems then
            set the menuHistory of tObj to lineOffset(pValue, tItems)
         end if
         break
      case "list"
         if the number of lines of pValue is 1 and pValue is among the lines of the text of tObj then
            set the hilitedLines of tObj to lineOffset(pValue, the text of tObj)
         else
            set the text of tObj to pValue
         end if
         Gui.ListMark tObj
         break
      case "field"
      case "text"
         if pValue is empty then
            set the text of tObj to empty
            set the uGuiHintOn of tObj to false
            Gui.HintOn tObj
         else
            Gui.HintOff tObj
            set the text of tObj to pValue
         end if
         break
      case "label"
         set the text of tObj to pValue
         break
      case "button"
         set the label of tObj to pValue
         break
      case "menu"
         set the text of tObj to guiItems(pValue)
         break
      case "panel"
         set the uGuiLabel of tObj to pValue
         if there is a field (pName & "_title") of tObj then
            set the text of field (pName & "_title") of tObj to pValue
         end if
         break
      case "slider"
         if pValue is a number then
            guiSliderSet tObj, pValue
         end if
         break
      case "tabs"
         if pValue is among the lines of the uGuiItems of tObj then
            guiTabShow tObj, pValue
         end if
         break
      case "view"
         set the label of tObj to pValue
         break
   end switch
   unlock messages
   return empty
end Gui.Set

command Gui.Show pName, pFlag
   local tObj
   put guiControl(pName) into tObj
   if tObj is empty then return "no widget" && quote & pName & quote
   set the visible of tObj to (pFlag is not false)
   if the uGuiKind of tObj is "tabs" then
      guiTabParts tObj, "visible", (pFlag is not false)
      guiTabShow tObj, the uGuiValue of tObj
   end if
end Gui.Show

command Gui.Enable pName, pFlag
   local tObj
   put guiControl(pName) into tObj
   if tObj is empty then return "no widget" && quote & pName & quote
   set the enabled of tObj to (pFlag is not false)
   if the uGuiKind of tObj is "tabs" then
      guiTabParts tObj, "enabled", (pFlag is not false)
   end if
end Gui.Enable

## ---------------------------------------------------------------------------------
## Tabs and views
## ---------------------------------------------------------------------------------

-- a tab was clicked: show its page, then fire (once a click)
command Gui.TabPick pTab
   local tCard, tPage
   put the long id of the owner of pTab into tCard
   if there is not a graphic (the uTabStrip of pTab) of tCard then exit Gui.TabPick
   put the long id of graphic (the uTabStrip of pTab) of tCard into tPage
   if the enabled of tPage is false then exit Gui.TabPick
   guiTabShow tPage, the uTabName of pTab
   Gui.Fire tPage
end Gui.TabPick

-- the tab pItem looks selected; widgets with tab=<these tabs>:<item> show only on their page
private command guiTabShow pPage, pItem
   local tCard, tName, n, tF, tObj, tTab, tOn
   put the uGuiName of pPage into tName
   put the long id of the owner of pPage into tCard
   if pItem is not among the lines of the uGuiItems of pPage then put line 1 of the uGuiItems of pPage into pItem
   set the uGuiValue of pPage to pItem
   lock screen
   put 1 into n
   repeat while there is a field ("tab_" & tName & "_" & n) of tCard
      put the long id of field ("tab_" & tName & "_" & n) of tCard into tF
      if the uTabName of tF is pItem then
         set the backgroundColor of tF to the uOnBack of tF
         set the foregroundColor of tF to the uOnText of tF
         set the textStyle of tF to "bold"
      else
         set the backgroundColor of tF to the uOffBack of tF
         set the foregroundColor of tF to the uOffText of tF
         set the textStyle of tF to "plain"
      end if
      add 1 to n
   end repeat
   repeat with n = 1 to the number of controls of tCard
      put the long id of control n of tCard into tObj
      put the uGuiTab of tObj into tTab
      if tTab is empty or ":" is not in tTab then next repeat
      if char 1 to offset(":", tTab) - 1 of tTab is not tName then next repeat
      put char offset(":", tTab) + 1 to -1 of tTab into tTab
      put (tTab is pItem) into tOn
      set the visible of tObj to (tOn and the visible of pPage)
   end repeat
   unlock screen
end guiTabShow

-- the tabs' own fields follow the page when it is hidden, shown, greyed
private command guiTabParts pPage, pProp, pFlag
   local tCard, tName, n
   put the uGuiName of pPage into tName
   put the long id of the owner of pPage into tCard
   put 1 into n
   repeat while there is a field ("tab_" & tName & "_" & n) of tCard
      if pProp is "visible" then
         set the visible of field ("tab_" & tName & "_" & n) of tCard to pFlag
      else
         set the enabled of field ("tab_" & tName & "_" & n) of tCard to pFlag
      end if
      add 1 to n
   end repeat
end guiTabParts

-- a view was clicked: fire with the point inside it (x,y from its top left)
command Gui.ViewClick pObj
   local tX, tY, tClick
   put the clickLoc into tClick
   put (item 1 of tClick) - (the left of pObj) into tX
   put (item 2 of tClick) - (the top of pObj) into tY
   Gui.Fire pObj, tX & comma & tY
end Gui.ViewClick

## ---------------------------------------------------------------------------------
## Resizing by stick=
## ---------------------------------------------------------------------------------

-- lays the window out again for pWidth x pHeight: each widget keeps its distance from the edges
-- its stick= names (left,top by default) of the window, or of its panel when it is in= one.
-- Places are worked out from the built size each time, so many resizes never drift.
command Gui.Resize pWidth, pHeight
   local tCard, tSize, tOldA, tNewA, tTodo, tLeft, tObj, tAnchor, tPass, tRect, tName, n
   if sStack is empty then return "no window"
   put the long id of card 1 of sStack into tCard
   put the uGuiSize of sStack into tSize
   if tSize is empty then return "not built by lib_gui"
   if pWidth is not a number or pHeight is not a number then
      put the width of sStack into pWidth
      put the height of sStack into pHeight
   end if
   set the itemDelimiter to comma
   put "0,0," & tSize into tOldA["w"]
   put "0,0," & pWidth & comma & pHeight into tNewA["w"]
   repeat with n = 1 to the number of controls of tCard
      put the long id of control n of tCard into tObj
      if the uGuiRect of tObj is not empty then put tObj & return after tTodo
   end repeat
   lock screen
   repeat with tPass = 1 to 12
      if tTodo is empty then exit repeat
      put empty into tLeft
      repeat for each line tObj in tTodo
         put "w" & the uGuiAnchor of tObj into tAnchor
         if tNewA[tAnchor] is empty then
            put tObj & return after tLeft
            next repeat
         end if
         put guiStickRect(the uGuiRect of tObj, tOldA[tAnchor], tNewA[tAnchor], the uGuiStick of tObj, the uGuiKind of tObj) into tRect
         if the uGuiKind of tObj is "line" then
            set the points of tObj to (item 1 to 2 of tRect) & return & (item 3 to 4 of tRect)
         else
            set the rect of tObj to tRect
         end if
         put the uGuiName of tObj into tName
         if tName is not empty and the uGuiPart of tObj is empty then
            put the uGuiRect of tObj into tOldA["w" & tName]
            put tRect into tNewA["w" & tName]
         end if
      end repeat
      put tLeft into tTodo
   end repeat
   unlock screen
   return empty
end Gui.Resize

-- a place (pRect, as built) laid out again: it moves with its anchor's top left, and grows or
-- moves with the anchor's size by the edges pStick names
private function guiStickRect pRect, pOld, pNew, pStick, pKind
   local tL, tT, tR, tB, tDW, tDH
   set the itemDelimiter to comma
   if pStick is empty then put "left,top" into pStick
   put item 1 of pRect + item 1 of pNew - item 1 of pOld into tL
   put item 2 of pRect + item 2 of pNew - item 2 of pOld into tT
   put item 3 of pRect + item 1 of pNew - item 1 of pOld into tR
   put item 4 of pRect + item 2 of pNew - item 2 of pOld into tB
   put (item 3 of pNew - item 1 of pNew) - (item 3 of pOld - item 1 of pOld) into tDW
   put (item 4 of pNew - item 2 of pNew) - (item 4 of pOld - item 2 of pOld) into tDH
   if "right" is among the items of pStick then
      add tDW to tR
      if "left" is not among the items of pStick then add tDW to tL
   end if
   if "bottom" is among the items of pStick then
      add tDH to tB
      if "top" is not among the items of pStick then add tDH to tT
   end if
   if pKind is not "line" then
      put max(tR, tL + 1) into tR
      put max(tB, tT + 1) into tB
   end if
   return tL & comma & tT & comma & tR & comma & tB
end guiStickRect
