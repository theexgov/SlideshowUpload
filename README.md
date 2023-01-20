# SlideshowUpload
captures image files, or creates tarballs and upload to b2 for storage

VM setup:
create a user account, add this to that user's crontab
sudo apt update
sudo apt upgrade
sudo apt install sudo ffmpegCancel changes
usermod -a -G sudo $USERNAME
parameter is capital o
wget -O b2 https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux
chmod +x b2
 
update this file to include the correct info in the $B2 variables ($B2KEYID, $B2APPKEY, $B2BUCKETNAME)

run this from crontab. 
once a minute, all day every day:
  */1 * * * * /home/$USERNAME/capture.sh -c
once a minute between 6am and 10pm daily:
  */1 06-22 * * * /home/$USERNAME/capture.sh -c
call once daily at midnight to backup (tar yesterday's files, resync with B2)
  0 0 * * * /home/$USERNAME/capture.sh -u

if in doubt, this is your friend for crontab times: https://crontab.guru
