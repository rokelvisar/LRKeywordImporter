--[[----------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

--------------------------------------------------------------------------------

ShowCustomDialog.lua
From the Hello World sample plug-in. Displays a custom dialog and writes debug info.

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrStringUtils = import 'LrStringUtils'


-- Create the logger and enable the print function.

local myLogger = LrLogger( 'libraryLogger' )
myLogger:enable( "logfile" ) -- Pass either a string or a table of actions.

-- Write trace information to the logger.

local function outputToLog( message )
	myLogger:trace( message )
end

-- http://lua-users.org/wiki/MakingLuaLikePhp
local function explode(div,str) -- credit: http://richard.warburton.it
	if (div=='') then return false end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

-- Parse a CSV line, taking into consideration quoted items that include the separator.
-- http://lua-users.org/wiki/LuaCsv
function parseCSVLine (line,sep) 
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


--[[
	Demonstrates a custom dialog with a simple binding. The dialog displays a
	checkbox and a text field.  When the check box is selected the text field becomes
	enabled, if the checkbox is unchecked then the text field is disabled.
	
	The check_box.value and the edit_field.enabled are bound to the same value in an
	observable table.  When the check_box is checked/unchecked the changes are reflected
	in the bound property 'isChecked'.  Because the edit_field.enabled value is also bound then
	it reflects whatever value 'isChecked' has.
]]
local function showCustomDialog()

	LrFunctionContext.callWithContext( "showCustomDialog", function( context )
	
	    local f = LrView.osFactory()

	    -- Create a bindable table.  Whenever a field in this table changes
	    -- then notifications will be sent.
	    local props = LrBinding.makePropertyTable( context )
	    props.isChecked = false
		
		local staticTextValue = f:static_text {
			title = "... select import file",
			width = 300,
			alignment = left
		}		

	    -- Create the contents for the dialog.
	    local c = f:row {
	
		    -- Bind the table to the view.  This enables controls to be bound
		    -- to the named field of the 'props' table.
		    
		    bind_to_object = props,
				
			f:static_text {
				--alignment = "right",
				-- width = LrView.share "label_width",
				alignment = "left",
				width = 100,	
				title = "Filename: "
			},
			staticTextValue,
		    f:push_button {
					title = "Select file",
					action = function()
						staticTextValue.title = LrDialogs.runOpenPanel({
							title = "Day One Journal Location",
							canChooseDirectories = false,
							allowsMultipleSelection = false,						
						})[1]
						outputToLog( "File find button clicked." )
					end
				}
	    }

	
	    local retval = LrDialogs.presentModalDialog {
			    title = "Keyword Importer",
				resizable = true,
				cancelVerb = cancel,
			    contents = c
		}
		
		outputToLog(retval)
		
		if retval == "ok" then
			outputToLog("Got file & OK so calling the actual keyword import")
			local keywords = 'init'
			LrTasks.startAsyncTask(function()
				local catalog = import "LrApplication".activeCatalog()
				-- local fileobj = catalog:findPhotoByPath("D:\\files\\Data\\Dropbox\\Photos\\Library\\2014-04 Chicago\\IMG_0730.JPG")
				-- keywords = fileobj:getFormattedMetadata('keywordTags')	
				local keywordFilename = staticTextValue.title
				outputToLog("Logging to file: ", keywordFilename)
				outputToLog(keywordFilename)
				
				for line in io.lines(keywordFilename) do
					local lineBits = explode("|",line)
					local filename = lineBits[1]

					outputToLog(lineBits[1])
					
					local fileobj = catalog:findPhotoByPath(lineBits[1])
					if not fileobj then
						outputToLog("File not found: " .. lineBits[1])
					else
						outputToLog("Got fileobj, looking for keywords in " .. lineBits[2])
						-- keywordList = explode(",",lineBits[2])
						keywordList = parseCSVLine(lineBits[2], ",")
						
						local itemct = 0
						for index,item in pairs(keywordList) do
							item = LrStringUtils.trimWhitespace(item)
							outputToLog(item)
							catalog:withWriteAccessDo( 'writePhotosKeywords', function( context )
								local newKeyword = catalog:createKeyword(item, {}, true, nil, true)
								fileobj:addKeyword(newKeyword)
							end )
						end
					end
				end
			end)
		else
			outputToLog("Retval not OK: " .. retval)
		end
		

	end) -- end main function

end


-- Now display the dialogs.
showCustomDialog()
