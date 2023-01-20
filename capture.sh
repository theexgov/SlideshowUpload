#!/usr/bin/bash
#
# captures image files, or creates tarballs and upload to b2 for storage
#
# VM setup:
# create a user account, add this to that user's crontab
# sudo apt update
# sudo apt upgrade
# sudo apt install sudo ffmpeg
# usermod -a -G sudo $USERNAME
# # parameter is capital o
# wget -O b2 https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux
# chmod +x b2
# 
# update this file to include the correct info in the $B2 variables ($B2KEYID, $B2APPKEY, $B2BUCKETNAME)
#
# run this from crontab. 
# once a minute, all day every day:
# */1 * * * * /home/$USERNAME/capture.sh -c
# once a minute between 6am and 10pm daily:
# */1 06-22 * * * /home/$USERNAME/capture.sh -c
# call once daily at midnight to backup (tar yesterday's files, resync with B2)
# 0 0 * * * /home/$USERNAME/capture.sh -u
#
# if in doubt, this is your friend for crontab times: https://crontab.guru

#some variables
B2KEYID="1234"
B2APPKEY="asdf"
B2BUCKETNAME="Bucket"
basepath="$HOME/"

captureimage()
{
	dirname=`date +%Y%m%d`
	# ugh, ffmpeg insists on receiving a full path. no ~ here :/
	imagepath="${basepath}images/$dirname/"
	if [ ! -d "$dirpath" ]
	then
		mkdir -p $dirpath
	fi

	imagename="${imagepath}`date '+img-%Y%m%d-%H%M%S.jpg'`" 

	# this will obviously change with the camera specific IP... 
	ffmpeg -i rtsp://admin:password@127.0.0.1/image.jpg -qscale:v 3 -frames 1 "$imagename"
	exit $?
}

displayusage()
{
	echo "Capture and upload files to Backblaze B2."
	echo
	echo "Options:"
	echo "    -c : Capture an image file (also the default action if no parameter provided)."
	echo "    -h : Display this help message."
	echo "    -s : Setup the Backblaze B2 API keys."
	echo "    -u : Tar and upload yesterday's files."
	exit 0
}

setupapi()
{
	/home/mike/b2 authorize-account $B2KEYID $B2APPKEY
}

uploadfiles()
{
	# sometimes the upload fails, guess the authorization doesn't last long. just call authorize-account again
	setupapi

	# assuming that we were called by cron at midnight, so we want to tar and upload yesterday's files
	dirname=`date +%Y%m%d -d yesterday`
	imagepath="${basepath}images/${dirname}"
	tarpath="${basepath}images/tar/"
	tarfilename="${tarpath}${dirname}.tar"

	# make sure $tarpath exists, create it if not
	if [ ! -d "$tarpath" ]
	then
		mkdir -p $tarpath
	fi
	# make sure the directory is there, but the file that we want to create is not 
	if [ -d "$dirpath" ] && [ ! -f "$tarfilename" ]
	then
		# cd to the directory below where the images are, to get a short relative path in archive
		cd "${basepath}images/"
		# z will compress, JPG doesn't compress well though... 
		tar -cf "$tarfilename" "$dirname"

		${basepath}b2 sync "$tarpath" "b2://z1254-FMSCSlideshow/"
		exit $?
	fi
	# we don't want to be here... 
	exit 1
}

# parse command line args
while getopts "chsu" options; do
	case "${options}" in
		c)
			captureimage
			exit
			;;
		h)
			displayusage
			exit
			;;
		s)
			setupapi
			exit
			;;
		u)
			uploadfiles
			exit
			;;
		*)
			echo "Unknown option on commandline."
			displayusage
			exit
			;;
	esac
done

# run the default option (in case we fell out of while above)
captureimage
