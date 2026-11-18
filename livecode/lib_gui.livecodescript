script "lib_gui"
######################################################################################
## lib_gui (LIB_GUI, 11 17 2026): a window as a small text file (.gui, one widget a line),
## shown by a "face". This file: the format (PLAN.md stage 1) and the native face (stage 2:
## real xTalk controls, coloured by LIB_THEME).
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
constant kNativeKinds = "window label button toggle choice list field text menu line"
constant kOptions = "do tip hint stick in tab value min max key may theme float glyph"
constant kMenuBarHeight = 28

local sProblems   -- what the last read found wrong, one a line; the native face adds its own
local sStack      -- long id of the window Gui.Get / Set / Show / Enable act on
local sFace       -- the face in use: "native" (the only one in this file)
local sLastFired  -- the last use a face reported: name & tab & value & tab & message

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
   return tLayoutA
end Gui.Parse

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
   local tWin, tW, tH, tTheme, tName, tWidgetA, tCard, tMenuX, tObj, tKind, tTitle
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
      set the script of stack pStack to tObj
      if the result is not empty then guiProblem 0, "native: the window script does not compile:" && the result
   end if
   set the destroyStack of stack pStack to true
   set the width of stack pStack to tW
   set the height of stack pStack to tH
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
   repeat for each line tName in pLayoutA["order"]
      put pLayoutA["widget"][tName] into tWidgetA
      put tWidgetA["kind"] into tKind
      if tKind is "window" then next repeat
      if tKind is not among the words of kNativeKinds then
         guiProblem tWidgetA["line"], "native: does not draw" && tKind && "yet (" & tName & "): skipped"
         next repeat
      end if
      if there is a control tName of tCard then delete control tName of tCard
      if tKind is "menu" then
         if tMenuX is 0 then
            Theme.MenuBar pStack, 0, 0, tW, kMenuBarHeight
            put 4 into tMenuX
         end if
         guiMakeMenu tName, tWidgetA, tMenuX
         add the result + 2 to tMenuX
      else
         guiMake tName, tWidgetA
      end if
   end repeat
   Theme.ApplyStack pStack
   guiAfterTheme tCard
   Theme.End
   unlock messages
   unlock screen
   return sStack
end Gui.Build

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
   set the script of tB to "on menuPick pItem" & return & "   Gui.Fire the long id of me, pItem" & return & "end menuPick"
   guiTag tB, "menu", pName, pWidgetA
   return tW
end guiMakeMenu

private command guiMake pName, pWidgetA
   local tKind, tObj, tRect, tValue, tScript, tLabel
   put pWidgetA["kind"] into tKind
   put guiRect(pWidgetA["place"], tKind) into tRect
   put pWidgetA["opt"]["value"] into tValue
   put pWidgetA["label"] into tLabel
   reset the templateButton
   reset the templateField
   reset the templateGraphic
   switch tKind
      case "label"
         create field pName
         put it into tObj
         set the rect of tObj to tRect
         set the lockText of tObj to true
         set the traversalOn of tObj to false
         set the dontWrap of tObj to true
         set the text of tObj to tLabel
         break
      case "button"
         create button pName
         put it into tObj
         set the rect of tObj to tRect
         set the label of tObj to tLabel
         put "on mouseUp" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" into tScript
         break
      case "toggle"
         create button pName
         put it into tObj
         set the style of tObj to "checkbox"
         set the rect of tObj to tRect
         set the label of tObj to tLabel
         set the hilite of tObj to (tValue is true)
         put "on mouseUp" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" into tScript
         break
      case "choice"
         create button pName
         put it into tObj
         set the style of tObj to "menu"
         set the menuMode of tObj to "option"
         set the rect of tObj to tRect
         set the text of tObj to guiItems(tLabel)
         if tValue is not empty and tValue is among the lines of guiItems(tLabel) then
            set the menuHistory of tObj to lineOffset(tValue, guiItems(tLabel))
         else
            set the menuHistory of tObj to 1
         end if
         put "on menuPick pItem" & return & "   Gui.Fire the long id of me, pItem" & return & "end menuPick" into tScript
         break
      case "list"
         create field pName
         put it into tObj
         set the rect of tObj to tRect
         set the listBehavior of tObj to true
         set the lockText of tObj to true
         set the dontWrap of tObj to true
         set the vScrollbar of tObj to true
         set the text of tObj to guiItems(tLabel)
         if tValue is not empty and tValue is among the lines of the text of tObj then
            set the hilitedLines of tObj to lineOffset(tValue, the text of tObj)
         end if
         put "on mouseUp" & return & "   Gui.Fire the long id of me" & return & "end mouseUp" into tScript
         break
      case "field"
         create field pName
         put it into tObj
         set the rect of tObj to tRect
         set the dontWrap of tObj to true
         set the autoTab of tObj to true
         if tValue is not empty then
            set the text of tObj to tValue
         else
            set the text of tObj to tLabel
         end if
         put "on returnInField" & return & "   Gui.Fire the long id of me" & return & "end returnInField" & return \
               & "on closeField" & return & "   Gui.Fire the long id of me" & return & "end closeField" into tScript
         break
      case "text"
         create field pName
         put it into tObj
         set the rect of tObj to tRect
         set the vScrollbar of tObj to true
         if tValue is not empty then
            set the text of tObj to tValue
         else
            set the text of tObj to tLabel
         end if
         put "on closeField" & return & "   Gui.Fire the long id of me" & return & "end closeField" into tScript
         break
      case "line"
         create graphic pName
         put it into tObj
         set the style of tObj to "line"
         set the itemDelimiter to comma
         set the points of tObj to (item 1 to 2 of tRect) & return & (item 3 to 4 of tRect)
         set the foregroundColor of tObj to Theme.Get("dim")
         set the uThemeSkip of tObj to true
         break
   end switch
   if tScript is not empty then set the script of tObj to tScript
   guiTag tObj, tKind, pName, pWidgetA
end guiMake

-- what every control carries, so the layout can be read back out of the built stack
private command guiTag pObj, pKind, pName, pWidgetA
   local tKey, tOpts
   set the uGuiKind of pObj to pKind
   set the uGuiName of pObj to pName
   set the uGuiDo of pObj to pWidgetA["opt"]["do"]
   set the uGuiSent of pObj to empty
   set the uGuiStick of pObj to pWidgetA["opt"]["stick"]
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

-- after Theme.ApplyStack: labels are words on the page, not boxes
private command guiAfterTheme pCard
   local n, tObj
   repeat with n = 1 to the number of controls of pCard
      put the long id of control n of pCard into tObj
      if the uGuiKind of tObj is "label" then
         set the opaque of tObj to false
         set the showBorder of tObj to false
      else if the uGuiKind of tObj is "list" or the uGuiKind of tObj is "field" or the uGuiKind of tObj is "text" then
         set the opaque of tObj to true
      end if
   end repeat
end guiAfterTheme

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
   if tKind is not among the words of "menu choice" then put guiValueOf(pObj) into pValue
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
      case "label"
         return the text of pObj
      case "button"
         return the label of pObj
      case "menu"
         return the text of pObj
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
         break
      case "field"
      case "text"
      case "label"
         set the text of tObj to pValue
         break
      case "button"
         set the label of tObj to pValue
         break
      case "menu"
         set the text of tObj to guiItems(pValue)
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
end Gui.Show

command Gui.Enable pName, pFlag
   local tObj
   put guiControl(pName) into tObj
   if tObj is empty then return "no widget" && quote & pName & quote
   set the enabled of tObj to (pFlag is not false)
end Gui.Enable
