-- This script is created for import multi tracks from a csv file at a time
-- Tracks will be generated from start when there's no highlighted track
-- Or they will be generated from the position of track selected

-- tags: Tracks management
-- author: Yunaa

-- USER CONFIG AREA -----------------------------------------------------------

-- Use Preset Script for safe moding or to create a new action with your own values
-- https://github.com/X-Raym/REAPER-ReaScripts/tree/master/Templates/Script%20Preset

-- console = true -- true/false: display debug messages in the console
sep = "\t" -- default sep
col_name = 1 -- Name colomn index in the CSV
             -- Read the first colomn to name tracks

-- CSV to Table
-- http://lua-users.org/wiki/LuaCsv
function ParseCSVLine (line,sep)
  local res = {}
  local pos = 1
  sep = sep or ','
  while true do
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt..string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos)
        if (c == '"') then txt = txt..'"' end
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end
    end
  end
  return res
end

--@read lines from paresed CSV file
--@from X-Raym 
-- https://github.com/X-Raym/REAPER-ReaScripts/blob/master/Regions/X-Raym_Import%20markers%20and%20regions%20from%20tab-delimited%20CSV%20file.lua
function read_lines(filepath)

  lines = {}

  local f = io.input(filepath)
  repeat

    s = f:read ("*l") -- read one line

    if s then  -- if not end of file (EOF)
      table.insert(lines, ParseCSVLine (s,sep))
    end

  until not s  -- until end of file

  f:close()

end


--@return integer of selected track
--@from Adaline Simonian
-- https://gist.github.com/adalinesimonian/95117229c9fb85e299288f2a3723ffa4
function GetInsertionPoint()
  local selectionSize = reaper.CountSelectedTracks(0)
  if selectionSize == 0 then
    return reaper.GetNumTracks()
  end

  track = reaper.GetSelectedTrack(0, selectionSize - 1)
  return reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
end

retval, filetxt = reaper.GetUserFileNameForRead("", "generate tracks named with text in file", "csv")
if not retval then return false end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

read_lines(filetxt)

local insertPos = GetInsertionPoint()

for i, line in ipairs(lines) do

  -- Name Variable
  local name = line[col_name]
  
  reaper.InsertTrackAtIndex(insertPos+i-1, true)
  relatedTrack = reaper.GetTrack(0, insertPos+i-1)
  
  reaper.GetSetMediaTrackInfo_String(relatedTrack, "P_NAME", string.format("%s", name), true)
end


-- reaper.Undo_EndBlock(undo_text, -1) -- End of the undo block. Leave it at the bottom of your main function.
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
