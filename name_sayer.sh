#!/bin/bash

#Make newlines the only seperator
IFS=$'\n'


###### FUNCTIONS ######

# This function displays a line of equals signs
equals(){
	echo "====================================================="

}

# This function returns how many files with the .mkv extension are in the directory
number_of_creations(){

	#Count creations by piping ls output to grep then piping that output to wc	
	numOfCreations=$(ls | grep "\.mkv$" | wc -l);
	return $numOfCreations
}


# This function displays and lists all files in current directory with the .mkv file extension
list_creations() {

	#Display how many creations exist
	number_of_creations;
	numOfCreations=$?
       	if [ "$numOfCreations" = "0" ]; then
		echo "There are no creations"
	elif [ "$numOfCreations" = "1" ]; then
		echo "There is 1 creation:"
	else
		echo "There are $numOfCreations creations:"
	fi

	#List all files in the directory ending with .mkv without the file extension
	ls | grep "\.mkv$" | sed -e 's/\.mkv$//'

	equals;
}


# This function returns 1 if the input file exists
creation_exists() {

	if [ -f $1.mkv ]; then
		return 1
	else
		return 0
	fi
}


# This function plays the input file
play_creation() {
	ffplay -autoexit $1.mkv 2> /dev/null
	
}


# This function deletes the input file
delete_creation() {
	rm $1.mkv
	echo "Deleted creation '$1'"
}


# This function prompts the user to record the entered name until they are happy with the result
create_creation() {

	#Create video that displays input name
	ffmpeg -i blank.mp4 -vf "drawtext=text='$1':x=(main_w/2-text_w/2):y=(main_h/2-text_h/2):fontsize=40" $1.mp4 2> /dev/null
	
	echo "Please record audio for the creation by saying the name"

	#Keep recording until user is happy with product
	record=1
	while [ "$record" = "1" ]
	do
		echo "Press any key to record the microphone for 5 seconds"
		read -n1
		echo ""
		echo "Recording..."		
		#Record microphone for 5 seconds
		ffmpeg -f alsa -i default -t 5 $1.wav 2> /dev/null
		echo "Recording complete"
		echo ""
                echo "Do you want to hear the recording?"
                echo "Y/N"
                read yesOrNo
                echo ""
                       
		#Check if first letter of input is 'Y' or 'y
                if ([ "${yesOrNo:0:1}" = "Y" ] || [ "${yesOrNo:0:1}" = "y" ]); then
			listen=1
                else
                	listen=0
                fi
		
		#Keep asking to play recording until user doesn't want to hear it again
		while [ "$listen" = "1" ]
		do
			ffplay -autoexit $1.wav 2> /dev/null
			echo ""
			echo "Do you want to hear the recording again?"
			echo "Y/N"
	                read yesOrNo
			echo ""

             		#Check if first letter of input is 'Y' or 'y
                	if ([ "${yesOrNo:0:1}" = "Y" ] || [ "${yesOrNo:0:1}" = "y" ]); then
				listen=1
			else
				listen=0
			fi
		done

		#Keep asking for input until 'k' or 'r' is entered
		valid=0
		while [ "$valid" = "0" ]
		do
			echo "Please select one of the following options:"
			echo "  (k)eep the recording"
			echo "  (r)edo the recording"
			read selection
			echo ""

			if [ "$selection" = "k" ]; then
				#Keep was selected so break out of record while loop
				record=0
				valid=1
			elif [ "$selection" = "r" ]; then
				#Redo was selected so delete last recording and go through record while loop again
				rm $1.wav
				record=1
				valid=1
			else
				echo "Please enter a valid selection"
			fi
		done
	done

	#Merge sound file and video into one
	ffmpeg -i $1.mp4 -i $1.wav -c copy $1.mkv 2> /dev/null

	#Delete the temporary files that have been created
	rm $1.wav $1.mp4

	echo "Creation '$1' was successfully created"
}


# This function creates a sub-directory to store the creations and a blank
# background video as the base for the creations if none exists in the directory
setup_application(){
	
	echo "Setting up application...."

	#Make sub-directory for creations if none exists
	if [ ! -d "creations" ]; then
		mkdir "creations"
	fi
	
	#Change to creations sub-directory
	cd creations

	#Create blank video if none exists
	if [ ! -f blank.mp4 ]; then
		ffmpeg -t 5 -f lavfi -i color=c=white:s=640x480 -c:v libx264 -tune stillimage -pix_fmt yuv420p blank.mp4 2> /dev/null
	fi

	echo "Setup complete"
	equals;
	echo "Welcome to NameSayer"
}


###### MAIN SCRIPT ######
clear;
# Initial Setup
setup_application;

#Loop through forever
while [ true ]
do
	#Selection screen
	equals;
	echo "Please select from one of the following options:"
	echo
	echo "	(l)ist existing creations"
	echo "	(p)lay an existing creation"
	echo "	(d)elete an existing creation"
	echo "	(c)reate a new creation"
	echo "	(q)uit authoring tool"
	echo
	echo "Enter a selection [l/p/d/c/q]:"
	read selection 
        equals; 


	case $selection in
		#Quit was selected
		"q")
		
			echo "Are you sure you want to quit?"
			echo "Y/N"
               		read yesOrNo

	               	#Check if first letter of input is 'Y' or 'y
			if ([ "${yesOrNo:0:1}" = "Y" ] || [ "${yesOrNo:0:1}" = "y" ]); then
				#Break out of main loop if yes is entered
				break
			else
				echo "Did not quit"
			fi
		;;


		#List creations was selected
		"l")
		
			list_creations;
		;;


		#Play creation was selected
		"p")

			#Check if there are any creations
			number_of_creations;
			if [ "$?" -ge "1" ]; then
				echo "Which creation would you like to play?"
				echo ""
			fi
			list_creations;
		
			#Check again if there are any creations as list_creations always needs to be called
			number_of_creations;
			if [ "$?" -ge "1" ]; then
				read creation

				#Check if input creation exists
				creation_exists $creation;
				if [ "$?" = "1" ]; then
					play_creation $creation;
				else
					echo "ERROR: Creation '$creation' does not exist"
				fi
			fi
		;;


		#Delete creation was selected
		"d")

			#Check if there are any creations
			number_of_creations;
			if [ "$?" -ge "1" ]; then
				echo "Which creation would you like to delete?"
				echo "(Leave selection blank to cancel deletion)"
				echo ""
			fi
			list_creations;
	
			#Check again if there are any creations as list_creations always needs to be called		
			number_of_creations;
			if [ "$?" -ge "1" ]; then
				read creation
			
				#Check if input creation exists
				creation_exists $creation;
				if [ "$?" = "1" ]; then

					echo ""
					echo "Are you sure you want to delete creation '$creation'?"
					echo "Y/N"
					read yesOrNo
					echo ""

					#Check if first letter of input is 'Y' or 'y'
					if ([ "${yesOrNo:0:1}" = "Y" ] || [ "${yesOrNo:0:1}" = "y" ]); then
		
						delete_creation $creation;
				
					else
						echo "Did not delete creation '$creation'"
					fi
				else
					#Check if user didn't just press enter to cancel deletion
					if [ "$creation" != "" ]; then
						echo "ERROR: Creation '$creation' does not exist"
					fi
	
				fi
			fi
		;;


		#Create new creation was selected
		"c")
		
			#Run loop forever
			while [ true ]
			do
				echo "Please enter a full name for the new creation:"
				echo "(Leave name blank to cancel creation)"
				read newName
				equals;
				
				#Check if input name already exists
				creation_exists $newName;
				if [ "$?" = "1" ]; then 
					echo "ERROR: Name already exists"
				else
					#Break out of while loop when new name is entered
					break
				fi
			done
			
			if [ "$newName" != "" ]; then
				create_creation $newName;
			fi
		;;


		#Invalid input
		*)
		
			echo "Please enter a valid selection"

	esac

	echo ""

	#Makes sure user sees previous outputs no matter what selection they make
	echo "Press any key to continue...."
	read -n1
	clear

done

echo ""
echo "Quitting NameSayer...."
equals;
