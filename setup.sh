#!/bin/bash
#simple script to setup AutoRecon

#only tested on kali 2020.x - error checking/input validation is not thorough

# check if running with sudo
if [[ $EUID -ne 0 ]]; then
	echo -e "Script will need sudo/root privs for portions of the install actions. You may be prompted for your password if installs need to be made.\n\n"
	SUDO='sudo'
fi

echo -e "Checking your system against requirements for AutoRecon. Installing only what you don't have.\n\n"

#enum4linux-ng
mkdir enum4linux-ng && cd enum4linux-ng
#grab necessary files
wget https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/enum4linux-ng.py
wget https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/requirements.txt

#install deps
$SUDO apt install smbclient python3-ldap3 python3-yaml python3-impacket
/usr/bin/pip3 install -r requirements.txt

#set to $PATH (vs trying to find where user installed & sourcing that dir)
$SUDO cp enum4linux-ng.py /usr/bin/enum4linux-ng

#cleanup
rm -rf enum4linux

#general AR setup

# search for req pkgs on the system

if which python3 &> /dev/null ; then
	echo -e "python3 detected installed, moving on.\n"
else
	echo -e "python3 not detected, installing.\n"
	yes | $SUDO apt install python3 &> /dev/null && echo -e "python3 installed.\n"
fi

if which pip3 &> /dev/null ; then
	echo -e "pip3 detected installed, moving on.\n"
else
	echo -e "pip3 not detected, installing.\n"
	yes | $SUDO apt install python3-pip &> /dev/null && echo -e "pip3 installed.\n"
fi

while IFS='' read -r LINE || [ -n "${LINE}" ]; do
	if which ${LINE} &> /dev/null ; then
		echo -e "${LINE} detected installed, moving on.\n"
	else
		echo -e "${LINE} not detected, installing.\n"
		yes | $SUDO apt install ${LINE} &> /dev/null && echo -e "${LINE} installed.\n"
	fi
done < AR-reqs.txt

echo -e "Prerequisiste install checks done, installing autorecon.\n"

PS3='Please select your install method for AutoRecon: '
options=("pipx - recommended but requires config" "pip3" "manual as script" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "pipx - recommended but requires config"
            echo -e "\nInstalling via pipx\n"
	    #pipx setup
	    python3 -m pip install --user pipx
	    python3 -m pipx ensurepath
	    echo ''''alias autorecon='sudo env "PATH=$PATH" autorecon'''' >> ~/.bash_aliases && source ~/.bashrc

	    #install main autorecon using pipx
	    pipx install git+https://github.com/Tib3rius/AutoRecon.git && echo -e "\nAutoRecon installed using pipx. Complete!\n"
            ;;
        "pip3")
            echo -e "\nInstalling via pip3"
	    #install main autorecon using pip3
	    python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git && echo -e "\nAutoRecon installed using pip3. Complete!\n"
            ;;
        "manual as script")
            echo -e "\nInstalling as a manual script"
	    #install main autorecon using manual/script method
	    python3 -m pip install -r requirements.txt
	    echo "alias autorecon='sudo $PWD/src/autorecon.py'" >> ~/.bash_aliases && source ~/.bashrc
	    echo -e "\nAutoRecon installed as a script. Complete!\n"
            ;;
         "Quit")
	    echo "Exiting..."
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo -e "AutoRecon by Tib3rius installed! \n"
echo -e "It's like bowling with bumpers. - @ippsec\n\n"
