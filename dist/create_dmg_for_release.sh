#!/usr/bin/env bash

# Code from: http://stackoverflow.com/questions/96882/how-do-i-create-a-nice-looking-dmg-for-mac-os-x-using-command-line-tools

set -e 
set -u

source=./binary
title=DTerm
size=2000
applicationName=DTerm.app
backgroundPictureName=dmg_background.png
finalDMGName=${title}.dmg

function FinalizeDMG()
{
	echo "***************************"
	echo ${FUNCNAME[0]}
	chmod -Rf go-w /Volumes/"${title}"
	sync
	sync
	hdiutil detach ${device}
	hdiutil convert "./pack.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${finalDMGName}"
	rm -f ./pack.temp.dmg 
}

function CreateDMG()
{
	echo "***************************"
	echo ${FUNCNAME[0]}
	# create dmg
	hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ \
	      -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k pack.temp.dmg
	
	# mount dmg
	device=$(hdiutil attach -readwrite -noverify -noautoopen "pack.temp.dmg" | \
	         egrep '^/dev/' | sed 1q | awk '{print $1}')
}

function CopyBackgroundImage()
{
	echo "***************************"
	echo ${FUNCNAME[0]}
	mkdir /Volumes/DTerm/.background
	cp ../Images/dmg_background.png /Volumes/DTerm/.background/
}

function SetFolderOptions()
{
	echo "***************************"
	echo ${FUNCNAME[0]}
	echo '
	   tell application "Finder"
	     tell disk "'${title}'"
	           open
	           set current view of container window to icon view
	           set toolbar visible of container window to false
	           set statusbar visible of container window to false
	           set the bounds of container window to {400, 100, 845, 420}
	           set theViewOptions to the icon view options of container window
	           set arrangement of theViewOptions to not arranged
	           set icon size of theViewOptions to 100
	           set background picture of theViewOptions to file ".background:'${backgroundPictureName}'"
	           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
	           set position of item "'${applicationName}'" of container window to {100, 140}
	           set position of item "Applications" of container window to {345, 140}
	           update without registering applications
	           delay 5
	           close
	     end tell
	   end tell
	' | osascript
}

CreateDMG
CopyBackgroundImage
SetFolderOptions
FinalizeDMG