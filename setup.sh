#!/bin/bash
#simple script to setup AutoRecon

#only tested on kali 2020.x - error checking/input validation is not thorough
setupScript=$(find $PWD -name setup.sh 2>/dev/null)
ARdir="$(dirname -- "$setupScript")"
scriptReqs="$ARdir/AR-reqs.txt"

# check if running with sudo
if [[ $EUID -ne 0 ]]; then
	echo -e "Script will need sudo/root privs for portions of the install actions. You may be prompted for your password if installs need to be made.\n\n"
	SUDO='sudo'
fi

echo -e "Checking your system against requirements for AutoRecon. Installing only what you don't have.\n\n"
sleep 2

#general AR setup

# search for req pkgs on the system

if which python3 &> /dev/null ; then
	echo -e "python3 detected installed, moving on.\n"
else
	echo -e "python3 not detected, installing...\n"
	yes | $SUDO apt install python3 &> /dev/null && echo -e "python3 installed.\n"
fi

if which pip3 &> /dev/null ; then
	echo -e "pip3 detected installed, moving on.\n"
else
	echo -e "pip3 not detected, installing...\n"
	yes | $SUDO apt install python3-pip &> /dev/null && echo -e "pip3 installed.\n"
fi

if which svwar &> /dev/null ; then
	echo -e "svwar detected installed, moving on.\n"
else
	echo -e "svwar not detected, installing (from sipvicious)...\n"
	yes | $SUDO apt install sipvicious &> /dev/null && echo -e "svwar installed (from sipvicous.)\n"
fi

while IFS='' read -r LINE || [ -n "${LINE}" ]; do
	if which ${LINE} &> /dev/null ; then
		echo -e "${LINE} detected installed, moving on.\n"
	else
		echo -e "${LINE} not detected, installing...\n"
		yes | $SUDO apt install ${LINE} &> /dev/null && echo -e "${LINE} installed.\n"
	fi
done < $scriptReqs

echo -e "Prerequisiste install checks done, starting autorecon install.\n\n"

PS3='Install optional tools/extended tool chest, "etc," for autorecon? (The etc toolset currently includes seclists, enum4linux-ng, dirsearch, ffuf, & golang.) : '
options=("install etc tools" "do not install etc tools" "Quit")
select opt in "${options[@]}"
do
    case $opt in
	    "install etc tools")

	    #install seclists if not already there
	    sleep 1
	    if which seclists &> /dev/null ; then
	    	echo -e "\n\nseclists detected installed, moving on.\n\n"
	    else
	    	echo -e "\n\nseclists not detected, installing...\n(this make take a moment, so please be patient)...\n"
		yes | $SUDO apt install seclists &> /dev/null && echo -e "\nseclists installed.\n"
            fi

	    #install golang if not already there
	    if which go &> /dev/null ; then
	    	echo -e "golang detected installed, moving on.\n"
	    else
	    	echo -e "golang not detected, installing...\n(this make take a moment, so please be patient)...\n"
		yes | $SUDO apt install golang &> /dev/null && echo -e "\ngolang installed.\n"
            fi
	    
	    #install ffuf if not on system
	    if which ffuf &> /dev/null ; then 
	    	echo -e "\nfuff detected installed, moving on.\n"
	    else
	    	echo -e "\nffuf not detected, installing...\n"
	        ffufDir="$ARdir/ffuf"
		mkdir $ffufDir && cd $ffufDir
		LATEST_VER="$(curl -sI "https://github.com/ffuf/ffuf/releases/latest" | grep -Po 'tag\/\K(v\S+)')"
		relNum="${LATEST_VER:1}"
		binURL="https://github.com/ffuf/ffuf/releases/download/${LATEST_VER}/ffuf_${relNum}_linux_amd64.tar.gz"
		ffufBin="ffuf_${relNum}_linux_amd64.tar.gz"
		wget -q "$binURL"
		tar xvzf "$ffufBin" &> /dev/null && rm "$ffufBin"
		$SUDO mv $ffufDir /usr/share/ && $SUDO ln -s /usr/share/ffuf/ffuf /usr/bin/ffuf && echo -e "\nffuf installed.\n"
		cd $ARdir
	    fi
	    
	    #enum4linux-ng installation if not on system
	    if which enum4linux-ng &> /dev/null ; then 
	    	echo -e "\nenum4linux-ng detected installed, moving on.\n"
	    else
	        echo -e "\nenum4linx-ng not detected, installing...\n(this make take a moment, so please be patient)...\n"
	        mkdir enum4linux-ng && cd enum4linux-ng
                #grab necessary files
	        wget -q https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/enum4linux-ng.py
                wget -q https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/requirements.txt
	    
	        #install deps
	        yes | $SUDO apt install smbclient python3-ldap3 python3-yaml python3-impacket  &> /dev/null
	        /usr/bin/pip3 install -r requirements.txt  &> /dev/null

	        #set to $PATH (vs trying to find where user installed & sourcing that dir)
	        $SUDO cp enum4linux-ng.py /usr/bin/enum4linux-ng
	        $SUDO chmod +x /usr/bin/enum4linux-ng
	        #cleanup
	        cd $ARdir
	        rm -rf enum4linux-ng*
	        echo -e "\nenum4linux-ng installed.\n"
	   fi

	    #dirsearch installation if not on system
	    if which dirsearch &> /dev/null ; then 
	    	echo -e "\ndirsearch detected installed, moving on.\n"
	    else
	        echo -e "\ndirsearch not detected, installing...\n"
	        git clone https://github.com/maurosoria/dirsearch.git &> /dev/null
	        $SUDO mv dirsearch /usr/share/
	        $SUDO ln -s /usr/share/dirsearch/dirsearch.py /usr/bin/dirsearch
	        echo -e "\nDirsearch installed\n"
                cd $ARDir
	    fi

	    break
	    ;;

        "do not install etc tools")
            echo -e "skipping install of extra/non-required tools\n"
	    
	    break
	    ;;

         "Quit")
	    echo "Exiting..."
            
	    exit 1
	    ;;
	    
        *) echo "invalid option $REPLY";;
    esac
done


pipxInstall () {
	    #function to take care of pipx setup & installation of AutoRecon via pipx
	    #install if pipx if it does not exist on sys
	    if which pipx &> /dev/null ; then
	    	echo -e "pipx detected installed, moving on.\n"
	    else
	    	echo -e "pipx not detected, installing...\n"
		yes | $SUDO apt install pipx &> /dev/null && echo -e "\npipx installed.\n"
	    fi
	    
	    python3 -m pip install --user pipx --no-warn-script-location &> /dev/null
	    python3 -m pipx ensurepath
	    
	    #source .bashrc to propagate PATH updates
	    source ~/.bashrc
	    
	    #install autorecon using pipx
	    pipx install --spec git+https://github.com/initinfosec/AutoRecon.git autorecon &> /dev/null
	    echo="alias autorecon='sudo \$(which autorecon)'" >> ~/.bash_aliases && source ~/.bashrc	#have alias look for location of AR at runtime using sudo
	    #N.B. if using sudo, may desire to run scans in the following fashion: $autorecon <opts> <target> && sudo chown -R $USER:$USER <ouput_dir>
	    echo -e "\n\nAutoRecon installed using pipx. Complete!\n" ; echo -e "AutoRecon location: $(which autorecon)\n"'
}


PS3='Please select your install method for AutoRecon: '
options=("pipx - recommended" "pip3" "manual as script" "Quit")
select opt in "${options[@]}"
do
    case $opt in
	    "pipx - recommended")
            echo -e "\nInstalling via pipx\n"
	    #pipx AR installation
	    pipxInstall	 	#call to function to install/configure AR in new login shell so changes are properly applied
	    source ~/.bashrc
	    echo -e "\nWith pipx, you may need to launch a new shell or re-login after script completion before you start using AutoRecon.\n"
	    break
            ;;

        "pip3")
            echo -e "\nInstalling via pip3"
	    #install main autorecon using pip3
	    python3 -m pip install git+https://github.com/initinfosec/AutoRecon.git &> /dev/null && echo -e "\nAutoRecon installed using pip3. Complete!\n"
	    break
            ;;

        "manual as script")
            echo -e "\nInstalling as a manual script"
	    #install main autorecon using manual/script method
	    python3 -m pip install -r requirements.txt &> /dev/null
	    echo "alias autorecon='sudo python3 $PWD/src/autorecon.py'" >> ~/.bash_aliases && source ~/.bashrc
	    echo -e "\nAutoRecon installed as a script. Complete!\n"
	    break
            ;;

         "Quit")
	    echo "Exiting..."
            exit 1
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

#Finish banner
printf '\n%.s' {1..3}
printf '========================================================================================='
printf '\n%.s' {1..3}
echo -e "AutoRecon by Tib3rius installed!   more info at: https://github.com/Tib3rius/AutoRecon\n"
echo -e "install script/wrapper by @initinfosec\n\n"
echo "'It's like bowling with bumpers.' - @ippsec"
printf '\n%.s' {1..2}
printf '========================================================================================='
printf '\n%.s' {1..3}
