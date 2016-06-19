# Helpers
on getLinkList(theFile)
	set fileHandle to open for access theFile
	set theLines to paragraphs of (read fileHandle)
	close access fileHandle
	return theLines
end getLinkList

on openFormTabs()
	# Open all links, change to "edit" version of form, open script editor.
	set links to getLinkList("/Users/adamprice/Desktop/links.txt")
	tell application "Google Chrome" to activate
	tell application "Google Chrome" to make new window
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
			delay 0.1
		end repeat
	end tell
end openEditMode

on closeEmptyTabs()
	tell application "Google Chrome"
		set windowList to every tab of every window whose title is "New Tab"
		repeat with tabList in windowList
			set tabList to tabList as any
			repeat with tabItr in tabList
				set tabItr to tabItr as any
				close tabItr
			end repeat
		end repeat
	end tell
end closeEmptyTabs

on openScriptEditors()
	tell application "Google Chrome" to activate
	tell application "Google Chrome"
		set i to 1
		repeat with t in (tabs of front window)
			set (active tab index of front window) to i
			set myTab to active tab of front window
			tell application "Extra Suites"
				delay 0.5
				ES move mouse {1755, 150}
				delay 0.5
				ES click mouse
				delay 0.5
				ES move mouse {1755, 450}
				delay 0.5
				ES click mouse
			end tell
			delay 1
			set i to i + 2
		end repeat
	end tell
end openScriptEditors


# Note: This one is especially flaky because sometimes the Script Properties for a particular
# tab have a permanent spinner. It's a good idea to go through these and double check after.
on addScriptPropertiesToAllTabs()
	# For each tab, go to File > Project properties > Script Properties > Add row > and add prop and val
	tell application "Google Chrome" to activate
	tell application "Google Chrome"
		set i to 1
		repeat until i > (count of tabs in front window)
			set (active tab index of front window) to i
			set myTab to active tab of front window
			if (get URL of myTab) starts with "https://script.google.com" then
				tell application "Extra Suites"
					ES move mouse {70, 160} # File
					delay 0.2
					ES click mouse
					delay 0.2
					ES move mouse {115, 470} # Project Properties
					delay 0.2
					ES click mouse
					delay 0.2
					ES move mouse {896, 730} # Script Properties
					delay 0.2
					ES click mouse
					delay 0.2
					ES move mouse {658, 786} # Add Row
					delay 0.2
					ES click mouse
					delay 0.2
					tell application "System Events" to keystroke "BNCServiceURLEndpoint"
					delay 0.2
					ES move mouse {950, 790} # First Value
					delay 0.2
					ES click mouse
					delay 0.2
					tell application "System Events" to keystroke "https://bnc-slack-teams.herokuapp.com/submitFormId" & tab & return
					delay 0.1
				end tell
			end if
			set i to i + 1
		end repeat
	end tell
end addScriptPropertiesToAllTabs

on addTriggerToAllTabs()
	# Then go to Resources > Current Project Triggers > Add a new trigger > Save
	# Then delay, then select "Accept on oAuth dialog"
	# Then close tab
	tell application "Google Chrome" to activate
	tell application "Google Chrome"
		set i to 1
		repeat until i > (count of tabs in back window)
			set (active tab index of back window) to i
			set myTab to active tab of back window
			if (get URL of myTab) starts with "https://script.google.com" then
				tell application "Extra Suites"
					ES move mouse {300, 160} # Resources
					delay 0.1
					ES click mouse
					delay 0.1
					ES move mouse {300, 195} # Current Project Triggers
					delay 0.1
					ES click mouse
					delay 2
					ES move mouse {600, 867} # No triggers set up
					delay 0.2
					ES click mouse
					delay 0.2
					ES move mouse {575, 970} # Save
					delay 0.2
					ES click mouse
					delay 2
					ES move mouse {790, 900} # Review Permissions
					delay 0.2
					ES click mouse
					delay 2
					ES move mouse {1450, 1060} # Allow
					delay 0.2
					ES click mouse
					delay 2
				end tell
			end if
			set i to i + 1
			exit repeat
		end repeat
	end tell
end addTriggerToAllTabs



############################################
# Main Execution Routines
# Note: It's not realistic to run all of these in a row.
# Instead, you have to uncomment each line in turn, run it,
# make sure it all worked out, and then continue with the next routine.
############################################
#openFormTabs()
#openEditMode()
#closeEmptyTabs()
#openScriptEditors()
#addScriptPropertiesToAllTabs()
#addTriggerToAllTabs()
