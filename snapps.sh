#!/bin/bash

#Create snapshot of processes.
#Later compare current processes for new processes.
#For security threats.

#Store files based on current current second.
DATE=$(date +"%Y%m%d%H%M")

DIR=~/.snapps
SNAPDIR=$DIR/snap
WK=/tmp/snapps

if [ ! -d $DIR ]; then
	mkdir $DIR
fi

if [ ! -d $SNAPDIR ]; then
	mkdir $SNAPDIR
fi

if [ ! -d $WK ]; then
	mkdir $WK
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

#Create snapshot of processes
#If arg1=1 store the snap in snaps
function create_snap() {
	#Get all commands that are running
	ps ax | grep -o "[0-9]:.*$" | cut -c 6- 1> $WK/last_snap 2>> $DIR/error.log
	#WC=$(cat $WK/last_snap | wc -l)

	if [ "$1" = "1" ]; then
		cp $WK/last_snap $SNAPDIR/$DATE
	fi 
}

#Create a readable list of snaps with associated id and process count.
#If 1 is passed, will display view to stdout.
#All calculated data is stored in $DIR/view.
function list_snaps() {
	echo "Snaps" > $WK/view
	echo -e "ID\tDate\t\t\t\tProcesses" >> $WK/view
	ID=0

	ls $SNAPDIR | grep -o "[0-9]*" | sort | while IFS= read -r line; do
		#Formatting so the date command can interpreted.
		FDATE=$(echo $line | sed "s/^\(.\{8\}\)/\1 /")

		echo -e "$ID\t\c" >> $WK/view
		echo -e "$(date -d "$FDATE")\t\c" >> $WK/view
		echo -e "$(cat $SNAPDIR/$line | wc -l)" >> $WK/view

		ID=$(expr $ID + 1)
	done

	if [ "$1" = "1" ]; then
		cat $WK/view
	fi
}

#Read snap given by arg1=ID.
#If arg2=1 then output to stdout.
#If arg3=1 then don't invoke list_snaps to update $WK/view 
function view_snap() {
	#History will be stored in $DIR/view
	if [ ! "$3" = 1 ]; then
		list_snaps
	fi	

	if [ "$(echo $1 | grep -o "[0-9]*")" = "" ]; then
		error_log "Invalid-ID"
		exit 1
	fi
	
	LINE=$(cat $WK/view | grep "^$1")

	if [ "$LINE" = "" ]; then
		error_log "ID-Does-Not-Exist"
		exit 1
	fi
	
	#Read particular line using head | tail method
	cat $SNAPDIR/$(ls $SNAPDIR | sort | head -$(expr $1 + 1) | tail -1) > $WK/prev
	
	if [ "$2" = "1" ]; then
		cat $WK/prev
	fi
}

#Find differene between 2 snap files given by arg1=id1, arg2=id2
function find_difference() {
	if [ "$1" = "" ]; then
		#No arguments given
		list_snaps
		LID=$(cat $WK/view | tail -1 | grep -o "^[0-9]*") 
		view_snap $LID 0 1
		cp $WK/prev $WK/snap1

		create_snap
		cp $WK/last_snap $WK/snap2	
		cat $WK/snap2 | head -3	
	elif [ "$2" = "" ]; then
		#First argument given
		view_snap $1 0
		cp $WK/prev $WK/snap1

		create_snap
		cp $WK/last_snap $WK/snap2
	else
		#Both arguments given
		view_snap $1 0
		cp $WK/prev $WK/snap1

		view_snap $2 0 1
		cp $WK/prev $WK/snap2
	fi

	print_difference
}

function print_difference() {
	cat $WK/snap1 | sort | uniq > $WK/snap1
	cat $WK/snap2 | sort | uniq > $WK/snap2
	
	echo -n > $WK/killed
	
	cat $WK/snap1 | while IFS= read -r line; do
		if [ "$(cat $WK/snap2 | sed 's/^\-/\\\-/g' | grep -F "$line")" = "" ]; then
			echo $line
			#echo $line >> $WK/killed
			#NU="$(cat $WK/snap2 | grep -nF "$line" | grep -o "^[0123456789]*")"		
		fi
	done

	#cat $WK/killed	
}



case $1 in
"help" | "HELP" ) 
	display_help
	;;
"snap" | "SNAP" ) 
	create_snap 1
	;;
"view" | "VIEW" ) 
	if [ "$2" = "" ]; then
		list_snaps 1
	else
		view_snap $2 1
	fi
	;;
"diff" | "diff" ) 
	find_difference $2 $3
	;;
* )
	error_log "Invalid-Command"
	display_help
	;;
esac

