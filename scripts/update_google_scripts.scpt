# Helpers
on getLinkList(theFile)
	set fileHandle to open for access theFile
	set theLines to paragraphs of (read fileHandle)
	close access fileHandle
	return theLines
end getLinkList

on openFormTabs()
	# Open all links, change to "edit" version of form, open script editor.
	set links to getLinkList("/Users/adamprice/Desktop/a_few_links.txt")
	repeat with link in links
		tell application "Google Chrome"
			set myTab to make new tab at end of tabs of front window
			set URL of myTab to link
		end tell
	end repeat
end openFormTabs

on openEditMode()
	# For each tab, open edit mode
	tell application "Google Chrome"
		set i to 0
		repeat with t in (tabs of front window)
			set i to i + 1
			set (active tab index of front window) to i
			set myTab to active tab of front window
			
			set longLink to (get URL of active tab of front window)
			set AppleScript's text item delimiters to "viewform"
			set ti to text items of longLink
			set AppleScript's text item delimiters to "edit"
			set URL of myTab to (ti as text)
		end repeat
	end tell
end openEditMode

on openScriptEditors()
	# For each tab, open script editors
	tell application "Google Chrome" to activate
	delay 0.5
	tell application "Google Chrome"
		set i to 0
		repeat with t in (tabs of front window)
			set i to i + 1
			set (active tab index of front window) to i
			set myTab to active tab of front window
			
			tell application "Extra Suites"
				delay 0.5
				ES move mouse {1360, 150}
				delay 0.5
				ES click mouse
				delay 0.5
				ES move mouse {1360, 450}
				delay 0.5
				ES click mouse
			end tell
		end repeat
	end tell
end openScriptEditors

on addScriptPropertiesToAllTabs()
	# For each tab, go to File > Project properties > Script Properties > Add row > and add prop and val
end addScriptPropertiesToAllTabs

on addTriggerToAllTabs()
	# Then go to Resources > Current Project Triggers > Add a new trigger > Save
	# Then delay, then select "Accept on oAuth dialog"
	# Then close tab
end addTriggerToAllTabs

openFormTabs()
delay 1
openEditMode()
delay 1
#openScriptEditors()
#delay 1
#addScriptPropertiesToAllTabs()
#delay 1
#addTriggerToAllTabs()