#!/bin/bash

echo "Update apt"
sudo apt update > /dev/null 2>&1 #Removing any extraneous output that I do not believe is neccesary This is seens everal times 
dpkg --list | grep -i openjdk-11 > /dev/null 2>&1
isjava11installed=$?
if [ $isjava11installed == 0 ]
then
  echo "java exists not updating java incase this causes an issue with Jenkins"
elif [ $isjava11installed == 1 ]
then
  echo "Installing java"
  sudo apt install openjdk-11-jdk -y > /dev/null 2>&1
fi
echo "Adding keys to apt and new repo."
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add - #Idempotent will not keep adding  same key
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list' #idempotent will rewrite repo but does not matter
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9B7D32F2D50582E6 > /dev/null 2>&1 #idempotent will not keep adding same key
sudo apt update > /dev/null 2>&1
test -e /etc/default/jenkins
doesjenkinsconfigexist=$?
if [ $doesjenkinsconfigexist == 1 ]
then
  echo "Installing Jenkins"
  sudo apt install jenkins -y > /dev/null 2>&1
elif [ $doesjenkinsconfigexist == 0 ]
then
  echo "Jenkins is already installed not reinstalling jenkins"
fi
grep "HTTP_PORT=8000" /etc/default/jenkins > /dev/null 2>&1 #this is the port we want it to be set to so we are checking to see if its true
didgrepsucceed=$?
if [ $didgrepsucceed == 1 ]
then
  sudo sed -E -i s/HTTP\_PORT\=[0-9]+/HTTP\_PORT\=8000/ /etc/default/jenkins # This paired with the if command will replace any port number that isnt 8000
  echo "Updating listening port to 8000 and restarting Jenkins"
  sleep 60 #honestly instead of doing a cheesey sleep command here I should check if the program is running and wait for it to be running then restart Easy fix to a restart for port change
  sudo systemctl restart jenkins #restarting jenkins here to make sure the config is imported into the app
elif [ $didgrepsucceed == 0 ] #If the port is already do not restart to avoid any interruptions
then
  echo "Jenkins listening port is already set to 8000 not modifying config" 
fi
