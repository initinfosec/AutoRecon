#!/bin/bash
#simple script to setup AutoRecon

#only tested on kali 2020.x - error checking/input validation is not thorough

# check if running with sudo
if [[ $EUID -ne 0 ]]; then
	echo -e "Script will need sudo/root privs for portions of the install actions. You may be prompted for your password if installs need to be made.\n\n"
	SUDO='sudo'
fi

echo -e "Checking your system against requirements for AutoRecon. Installing only what you don't have.\n\n"


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
		echo -e "${LINE} not detected, installing. Output is silcenced - installation may take a moment, please be patient...\n"
		yes | $SUDO apt install ${LINE} &> /dev/null && echo -e "${LINE} installed.\n"
	fi
done < AR-reqs.txt

echo -e "Prerequisiste install checks done, installing autorecon.\n"

PS3='Please select your install method for AutoRecon: '
options=("pipx - recommended" "pip3" "manual as script" "Quit")
select opt in "${options[@]}"
do
    case $opt in
	    "pipx - recommended")
            echo -e "\nInstalling via pipx\n"
	    #pipx setup
	    python3 -m pip install --user pipx
	    python3 -m pipx ensurepath
	    echo '''alias autorecon='sudo env "PATH=$PATH" autorecon'''' >> ~/.bash_aliases && source ~/.bashrc
	    #install main autorecon using pipx
	    pipx install --spec "git+https://github.com/Tib3rius/AutoRecon.git" autorecon 
	    python3 -m pipx ensurepath && echo -e "\nAutoRecon installed using pipx. Complete!\n"
	    break
            ;;

        "pip3")
            echo -e "\nInstalling via pip3"
	    #install main autorecon using pip3
	    python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git && echo -e "\nAutoRecon installed using pip3. Complete!\n"
	    break
            ;;

        "manual as script")
            echo -e "\nInstalling as a manual script"
	    #install main autorecon using manual/script method
	    python3 -m pip install -r requirements.txt
	    echo "alias autorecon='sudo python3 $PWD/src/autorecon.py'" >> ~/.bash_aliases && source ~/.bashrc
	    echo -e "\nAutoRecon installed as a script. Complete!\n"
	    break
            ;;

         "Quit")
	    echo "Exiting..."
            exit 
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

PS3='Install optional/extended (etc) tools for autorecon? (enum4linux-ng & dirsearch)'
options=("install etc tools" "do not install etc tools" "Quit")
select opt in "${options[@]}"
do
    case $opt in
	    "install etc tools")
            echo -e "\nInstalling enum4linx-ng\n"
	    #enum4linux-ng installation
	    mkdir enum4linux-ng && cd enum4linux-ng
	    #grab necessary files
	    wget https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/enum4linux-ng.py
	    wget https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/requirements.txt

	    #install deps
	    $SUDO apt install smbclient python3-ldap3 python3-yaml python3-impacket
	    /usr/bin/pip3 install -r requirements.txt

	    #set to $PATH (vs trying to find where user installed & sourcing that dir)
	    $SUDO cp enum4linux-ng.py /usr/bin/enum4linux-ng
	    $SUDO chmod +x /usr/bin/enum4linux-ng
	    #cleanup
	    rm -rf enum4linux
	    echo -e "\nenum4linux-ng installed.\n"

	    #dirsearch installation
	    echo -e "\nInstalling dirsearch\n"
	    git clone https://github.com/maurosoria/dirsearch.git
	    cd dirsearch
	    dirsearchPath=$(PWD)
	    echo "alias dirsearch='python3 $dirsearchPATH/direarch.py'" >> ~/.bash_aliases && source ~/.bashrc
	    echo -e "\nDirsearch installed\n"
            ;;

        "do not install etc tools")
            echo -e "skipping install of extra/non-required tools\n"
	    ;;

         "Quit")
	    echo "Exiting..."
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


echo -e "AutoRecon by Tib3rius installed! install script/wrapper by @initinfosec\n"
echo -e "It's like bowling with bumpers. - @ippsec\n\n"
