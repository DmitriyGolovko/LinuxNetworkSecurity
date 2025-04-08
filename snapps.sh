#!/bin/bash

#Create snapshot of processes.
#Later compare current processes for new processes.
#For security threats.

#Store files based on current minute.
DATE=$(date +"%Y%m%d%H%M")

DIR=~/.snapps

if [ ! -d $DIR ]; then
	mkdir $DIR
fi

function display_help() {
	echo "Usage: ./snapps.sh (help|snap|view|diff) [date1] [date2]"
	echo ""
	echo "Description: Take snapshots of processes to compare in a later time."
	echo ""
	echo "Commands:"
	echo -e "help\t\t\tDisplay this help message.\n"
	echo -e "snap\t\t\tTake snapshot of all running processes.\n"
	echo -e "view [date]\t\tView processes at certain date.\n\t\t\tIf there is no argument, simply view all dates that were snapped.\n"
	echo -e "diff [date1] [date2]\tCompare snaps from now to latest snap.\n\t\t\tIf first argument given only, compare date to current processes.\n\t\t\tIf both arguments are given, compare snaps of both dates."
}

function create_snap() {
	echo Creating snap at $(date)

	#Get all commands that are running
	ps -e | egrep -o "(\w|[-:\/_\(\)])*$" 1> $DIR/$DATE 2>> $DIR/error.log
}

function list_snaps() {
	echo "Snaps created at:"
	ls $DIR | grep -o "[1234567890]*" | sort | while IFS= read -r line; do
		echo $line | sed "s/^\(.\{3\}\)/\1 /"
	done
}

function view_snap() {
	echo v	
}



case $1 in
"help" | "HELP" ) 
	display_help
	;;
"snap" | "SNAP" ) 
	create_snap
	;;
"view" | "VIEW" ) 
	if [ $2 = "" ]; then
		list_snaps
	else
		view_snap $2
	fi
	;;
"diff" | "diff" ) view_diff $2 $3
	;;
esac

#ps -e | egrep -o "(\w|[-:\/_\(\)])*$"
