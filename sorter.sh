#!/bin/bash

LOCKFILE=/tmp/sorter.lock
if shlock -f $LOCKFILE -p $$ ; then

	FINISH_DIR=~/"Movies/Finished/"
	MOVIE_DIR=~/"Movies/Movies/"
	#TV_DIR="/Volumes/TVShowHDD/TV_Shows/"
	TV_DIR=~/"Movies/TV_Shows/"
	mkdir $MOVIE_DIR $TV_DIR $FINISH_DIR

	for FULLFILENAME in $FINISH_DIR*; do
		FILENAME=$(echo $FULLFILENAME | egrep -oe '[^\/]*$.*')

		EXTENSION=$(echo $FILENAME | egrep -oe '.(zip|avi|mp4|mkv)')
		if [[ ! "$EXTENSION" ]]; then
			FILENAME=$(echo "$FILENAME.zip")
			EXTENSION='.zip'
		fi

		# Replace non-space characters between words with spaces in the filename
		FILENAMEWITHSPACES=$(echo $FILENAME | tr ._ ' ' | sed 's/%[12][0-9A-F]/ /g')
		# Determine media type and name convention based on filename
		# Standard US
		DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?[sS][0-3][0-9][eE][0-3][0-9]')
		CHARTOREMOVE=8
		# UK
		if [[ "$DOWNLOADNAME" = '' ]]; then
			DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?1?[0-9]x[0-3][0-9]')
			CHARTOREMOVE=6
		fi
		# Daily Show
		if [[ "$DOWNLOADNAME" = '' ]]; then
			DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?20([[:digit:]]{2} ){3}')
			CHARTOREMOVE=12
		fi
		# Full Season
		if [[ "$DOWNLOADNAME" = '' ]]; then
			DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oie '.*(season |s)[0-9]{1,2}')
			CHARTOREMOVE=1
		fi
		# Full Series
		if [[ "$DOWNLOADNAME" = '' ]]; then
			DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oie '.*(complete.*series|series.*complete)')
			CHARTOREMOVE=0
		fi

		# Process Movies
		if [[ "$DOWNLOADNAME" = '' ]]; then
			DOWNLOADNAME=$(echo $FILENAMEWITHSPACES | egrep -oe '.*?(480p|720p|1080p)')
			if [[ "$DOWNLOADNAME" != '' ]]; then
				mv "$FINISH_DIR$FILENAME" "$MOVIE_DIR$DOWNLOADNAME$EXTENSION"
			fi
		# Process TV Shows
		else
			if [[ "$CHARTOREMOVE" != '1' ]]; then
				SHOWNAME=$(echo $DOWNLOADNAME | rev | cut -c $CHARTOREMOVE- | rev)
			else
				SHOWNAME=$(echo $DOWNLOADNAME | \
					perl -nle'print $& if m{^[a-zA-Z0-9 &]+?(?=[^a-zA-Z0-9]*?([Ss]eason|SEASON|[Ss][\d]{1,2}))}' \
					| rev | cut -c $CHARTOREMOVE- | rev )
			fi
			SHOWNAME=$(echo $SHOWNAME | tr '[:upper:]' '[:lower:]')
			mkdir "$TV_DIR$SHOWNAME"

			# Unzip if file is compressed, otherwise do nothing, then sort
			if [[ "$EXTENSION" = '.zip' ]]; then
				ZIPSUCCESS=$(unar -o "$TV_DIR$SHOWNAME" "$FINISH_DIR$FILENAME")
				if [[ "$ZIPSUCCESS" ]]; then
					rm "$FINISH_DIR$FILENAME"
				fi
			else
				mv "$FINISH_DIR$FILENAME" "$TV_DIR$SHOWNAME"
			fi
		fi

		# NOTIFICATION_EMAIL=bifif123@gmail.com 
		# if [[ "$DOWNLOADNAME" != '' ]]; then
		# 	osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "$DOWNLOADNAME is ready to watch. Enjoy!"
		# else
		# 	osascript sendFinishedMessage.applescript $NOTIFICATION_EMAIL "$FILENAME has been downloaded, but requires manual sorting."
		# fi
	done

	# If remaining files in finished, call script again
	if [[ $(ls $FINISH_DIR) ]]; then
		rm $LOCKFILE
		./sorter.sh
	fi
fi