-- ********************************************************************************** --
-- **   UI class for program "KrutoyTurtle"                                        ** --
-- **                                                                              ** --
-- ********************************************************************************** --

KUI = {}
KUI.__index = KUI

local sub = string.sub

local borderStylesStr = {
  ['selectedBtn']= '/\\/\\  ||',
  ['standart']   = '++++--||',
  ['none']       = '        ',
  ['inlineBtn']  = '[]][    '
}
-- Transform string to array
local borderStyles = {}
for k,v in pairs(borderStylesStr) do
  borderStyles[k] = {}
  local styleStr = v
  for i = 1, #styleStr do
    borderStyles[k][i] = (styleStr:sub(i,i))
  end
end


local alignTypes = {'left', 'right', 'center'}

KUI.items = {} -- Array of UI elements
KUI.selectedObj = nil -- Currently selected item
KUI.currentWindow = nil -- Current drawing window



-- Repeat char many as need times to make string
local function repeatChar(char, count)
  local returnString = ''
  for _=0, count-1 do
    returnString = returnString..char
  end
  return returnString
end


function KUI.drawText(text, x,y, w,h, align)
  align = align or 'center'
  
  -- String params
  local textLinesCount = 1 + select(2, text:gsub('\n', '\n'))
  
  -- Top spaces
  local vertSpace = (h-textLinesCount)/2
  local clearLine = repeatChar(' ', w)
  for _=1, math.floor(vertSpace) do
    term.setCursorPos(x, y)
    term.write(clearLine)
  end
  
  -- Bottom spaces
  for _=1, math.ceil (vertSpace) do
    term.setCursorPos(x, y+h-1)
    term.write(clearLine)
  end  
  
  -- Write lines 
  local currLine = 0
  for l in text:gmatch('[^\r\n]+') do
    local margin = {0,0} -- Spaces from left and right
    local horisSpace = (w - #l)
    
    -- Align styles
    if    (align == 'left') then
      margin = {0, horisSpace}
    elseif(align == 'right')then
      margin = {horisSpace, 0}
    elseif(align == 'center')then
      margin = {math.floor(horisSpace/2), math.ceil(horisSpace/2)}
    end
    
    term.setCursorPos(x, y+currLine)
    term.write( repeatChar(' ',margin[1])..l..repeatChar(' ',margin[2]))
    currLine = currLine+1
  end
end

-- Draw simple panel with borders
function KUI.drawPanel(x,y, w,h, borderStyle)
  borderStyle = borderStyle or 'standart'
  local styleArr = borderStyles[borderStyle]
  
  -- Horisontal lines
  if(h > 1) then
    term.setCursorPos(x, y)
    term.write(styleArr[1]..repeatChar(styleArr[5], w-2)..styleArr[2])
    term.setCursorPos(x, y+h-1)
    term.write(styleArr[4]..repeatChar(styleArr[6], w-2)..styleArr[3])
  elseif h==1 then
    term.setCursorPos(x, y);     term.write(styleArr[1])
    term.setCursorPos(x+w-1, y); term.write(styleArr[2])
  end
  
  -- Vertical lines
  for i=0,h-3 do
    term.setCursorPos(x, y+i+1)
    term.write(styleArr[7])
    term.setCursorPos(x+w-1, y+i+1)
    term.write(styleArr[8])
  end

end

-- Draw panel with text
function KUI.drawTextPanel(text, x,y, w,h, borderStyle, align)
  KUI.drawPanel(x,y, w,h, borderStyle)
  
  if borderStyle == 'none' then
    KUI.drawText(text, x,y+((h>1) and 1 or 0), w,h, align)
  else
    KUI.drawText(text, x+1,y+((h>1) and 1 or 0), w-2,h, align)
  end
end

-- ********************************************************************************** --
-- Add gui element to current window
-- ********************************************************************************** --
function KUI.add(obj)
  -- Standart values
  obj.borderStyle = obj.borderStyle or 'standart'
  obj.align       = obj.align       or 'center'
  obj.padding     = obj.padding     or {0,0,0,0}

  -- Add additional info
  obj.center = {x=obj.x+obj.w/2, y=obj.y+obj.h/2}
  
  obj.nextTab = KUI.items[1] or obj
  if(#KUI.items >= 1) then 
  KUI.items[#KUI.items].nextTab = obj 
  end
  
  if obj.type == 'button' or obj.type == 'input' then
    obj.selectable = true
  end
  
  table.insert(KUI.items, obj)
end

-- ********************************************************************************** --
-- Set new window. Add all objects in list to screen
-- ********************************************************************************** --
function KUI.setWindow(window, selectedId)
  KUI.items = {}
  KUI.selectedObj = nil
  for _,obj in pairs(window) do
    KUI.add(obj)
    
    if obj.id == selectedId then KUI.selectedObj = obj end
  end
  KUI.selectedObj = KUI.selectedObj or KUI.items[1]
  KUI.draw()
end

-- ********************************************************************************** --
-- Draw all objects in list
-- ********************************************************************************** --
function KUI.draw()
  term.clear()
  for _,obj in pairs(KUI.items) do
    
    -- Switch type
    if     obj.type == 'panel' then
      KUI.drawPanel(obj.x,obj.y, obj.w,obj.h, obj.borderStyle)
    elseif obj.type == 'text' then
      KUI.drawText(obj.text,
        obj.x+obj.padding[4],
        obj.y+obj.padding[1],
        obj.w-obj.padding[2]-obj.padding[4],
        obj.h-obj.padding[1]-obj.padding[3],
        obj.align)
    elseif obj.type == 'textPanel' or obj.type == 'button' or obj.type == 'input' then
      KUI.drawTextPanel(obj.text,
        obj.x+obj.padding[4],
        obj.y+obj.padding[1],
        obj.w-obj.padding[2]-obj.padding[4],
        obj.h-obj.padding[1]-obj.padding[3],
        obj.borderStyle, obj.align)
    else
      
    end
    
    -- This object is selected and selectable
    if KUI.selectedObj == obj and obj.selectable == true then
      KUI.drawPanel(obj.x-1,
                    obj.y,
                    obj.w+2+obj.padding[2]+obj.padding[4],
                    obj.h  +obj.padding[1]+obj.padding[3], 'inlineBtn')
    end
    
  end
  
  -- Set Cursor
  local selObj = KUI.selectedObj
  if selObj.type == 'input' then
    term.setCursorPos(selObj.x+selObj.padding[4]+#selObj.text, selObj.y+selObj.padding[1])
    term.setCursorBlink(true)
  else
    term.setCursorBlink(false)
  end
  
  sleep(0)
end

function KUI.navigate()
  while true do
    local e, keyCode = os.pullEvent('key')
    
    -- Call user-defined event
    if KUI.onKeyPressed then KUI.onKeyPressed(keyCode) end
    
    -- Input line
    local selObj = KUI.selectedObj
    if selObj ~= nil and selObj.type == 'input' then
      local keyMap = {"",1,2,3,4,5,6,7,8,9,0,"-",[57]=" "}
      if keyMap[keyCode] ~= nil then
        selObj.text = selObj.text .. keyMap[keyCode]
        KUI.draw()
      elseif keyCode == 14 then -- BACKSPACE
        selObj.text = selObj.text:sub(1,#selObj.text-1)
        KUI.draw()
      end
    end
    
    if     keyCode == 200 then --UP
      KUI.prevTab()
    elseif keyCode == 203 then --LEFT
      
    elseif keyCode == 205 then --RIGHT
      
    elseif keyCode == 15 or keyCode == 208 then --TAB --DOWN
      KUI.nextTab()
    elseif keyCode == 28  then --ENTER
      if selObj ~= nil then
        return selObj.id, selObj
      end
    end
  end
end

function KUI.nextTab()
  local oldSelectedObj = KUI.selectedObj
  KUI.selectedObj = KUI.selectedObj.nextTab
  while KUI.selectedObj.selectable ~= true and oldSelectedObj ~= KUI.selectedObj do
    KUI.selectedObj = KUI.selectedObj.nextTab
  end
  KUI.draw()
end

function KUI.prevTab()
  local oldSelectedObj = KUI.selectedObj
  local nextTab = KUI.selectedObj.nextTab
  local lastSelectable = (nextTab.selectable == true) and nextTab or oldSelectedObj
  while oldSelectedObj ~= nextTab.nextTab do
    nextTab = nextTab.nextTab
    if nextTab.selectable == true then lastSelectable = nextTab end
  end
  KUI.selectedObj = lastSelectable
  KUI.draw()
end
