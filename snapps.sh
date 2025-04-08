#!/bin/bash

#Create snapshot of processes.
#Later compare current processes for new processes.
#For security threats.

#Store files based on current current second.
DATE=$(date +"%Y%m%d%H%M")

DIR=~/.snapps
SNAPDIR=$DIR/snap

if [ ! -d $DIR ]; then
	mkdir $DIR
fi

if [ ! -d $SNAPDIR ]; then
	mkdir $SNAPDIR
fi

function error_log() {
	echo "$(whoami) $(date) Error: $1" >> $DIR/error.log
	echo $1
}	

function display_help() {
	echo "Usage: ./snapps.sh (help|snap|view|diff) [id1] [id2]"
	echo ""
	echo "Description: Take snapshots of processes to compare at a later time."
	echo ""
	echo "Commands:"
	echo -e "help\t\t\tDisplay this help message.\n"
	echo -e "snap\t\t\tTake snapshot of all running processes.\n"
	echo -e "view [id]\t\tView processes at certain date.\n\t\t\tIf there is no argument, simply view all dates that were snapped.\n"
	echo -e "diff [id1] [id2]\tCompare snaps from now to latest snap.\n\t\t\tIf first argument given only, compare date to current processes.\n\t\t\tIf both arguments are given, compare snaps of both dates."
}

function create_snap() {
	#Get all commands that are running
	ps -e | egrep -o "(\w|[-:\/_\(\)])*$" 1> $SNAPDIR/$DATE 2>> $DIR/error.log
}

#Create a readable list of snaps with associated id and process count.
#If 1 is passed, will display view to stdout.
#All calculated data is stored in $DIR/view.
function list_snaps() {
	echo "Snaps" > $DIR/view
	echo -e "ID\tDate\t\t\t\tProcesses" >> $DIR/view
	ID=0

	ls $SNAPDIR | grep -o "[1234567890]*" | sort | while IFS= read -r line; do
		#Formatting so the date command can interpreted.
		FDATE=$(echo $line | sed "s/^\(.\{8\}\)/\1 /")

		echo -e "$ID\t\c" >> $DIR/view
		echo -e "$(date -d "$FDATE")\t\c" >> $DIR/view
		echo -e "$(cat $SNAPDIR/$line | wc -l)" >> $DIR/view

		ID=$(expr $ID + 1)
	done

	if [ "$1" = "1" ]; then
		cat $DIR/view
	fi
}

#Read snap given by arg1=ID. If arg2=1 then output to stdout.
function view_snap() {
	#History will be stored in $DIR/view
	list_snaps	

	if [ "$(echo $1 | grep -o "[1234567890]*")" = "" ]; then
		error_log "Invalid-ID"
		exit 1
	fi
	
	LINE=$(cat $DIR/view | grep "^$1")

	if [ "$LINE" = "" ]; then
		error_log "ID-Does-Not-Exist"
		exit 1
	fi
	
	#Read particular line using head | tail method
	cat $SNAPDIR/$(ls $SNAPDIR | sort | head -$(expr $1 + 1) | tail -1) > $DIR/prev
	
	if [ "$2" = "1" ]; then
		cat $DIR/prev
	fi
}



case $1 in
"help" | "HELP" ) 
	display_help
	;;
"snap" | "SNAP" ) 
	create_snap
	;;
"view" | "VIEW" ) 
	if [ "$2" = "" ]; then
		list_snaps 1
	else
		view_snap $2 1
	fi
	;;
"diff" | "diff" ) 
	view_diff $2 $3
	;;
* )
	error_log "Invalid-Command"
	display_help
	;;
esac

