#!/bin/bash
#script to setup AutoRecon - @initinfosec June 2020
#it's not pretty but it [mostly] works. iterative improvements will probably be made at some point.

#only tested on kali 2020.x - error checking/input validation is not thorough
setupScript=$(find $PWD -name setup.sh 2>/dev/null)
ARdir="$(dirname -- "$setupScript")"
scriptReqs="$ARdir/AR-reqs.txt"
ARscript="$ARdir/src/autorecon/autorecon.py"
etcTools="seclists, dirsearch, ffuf, golang, enum4linux-ng"

# check if running with sudo
if [[ $EUID -ne 0 ]]; then
	echo -e "\nYou're not running as sudo or root. This script will need sudo/root privs for portions of the install actions.\nYou may be prompted for your password if installs need to be made.\n\n"
	SUDO='sudo'
	sleep 1
fi

echo -e "\nChecking your system against requirements for AutoRecon. Installing only what you don't have.\n\n"
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
	yes | $SUDO apt install sipvicious &> /dev/null && echo -e "svwar installed (from sipvicous).\n"
fi

while IFS='' read -r LINE || [ -n "${LINE}" ]; do
	if which ${LINE} &> /dev/null ; then
		echo -e "${LINE} detected installed, moving on.\n"
	else
		echo -e "${LINE} not detected, installing...\n"
		yes | $SUDO apt install ${LINE} &> /dev/null && echo -e "${LINE} installed.\n"
	fi
done < $scriptReqs

echo -e "\n\nInstall optional tools/extended tool chest ['etc'] for autorecon?\n"
echo -e "\n(The etc toolset currently includes: ${etcTools}.)\n"
echo -e "\nThese tools are not strictly required for AutoRecon operation, but some commands may fail without them (especially commands in manual_commands.txt).\n\n"

PS3='Install optional tools/extended tool chest ["etc"] for autorecon? : '
options=("install etc tools" "do not install etc tools" "Quit")
select opt in "${options[@]}"
do
    case $opt in
	    "install etc tools")

	    echo -e "\n\nInstalling extended tool chest ['etc'] for autorecon...\n"
	    
	    #install seclists if not already there
	    sleep 1
	    if which seclists &> /dev/null ; then
	    	echo -e "\nseclists detected installed, moving on.\n\n"
	    else
	    	echo -e "\nseclists not detected, installing...\n(this make take a moment, so please be patient)...\n"
		yes | $SUDO apt install seclists &> /dev/null && echo -e "\nseclists installed.\n"
            fi

	    #install golang if not already there
	    if which go &> /dev/null ; then
	    	echo -e "\ngolang detected installed, moving on.\n"
	    else
	    	echo -e "\ngolang not detected, installing...\n(this make take a moment, so please be patient)...\n"
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
		pkgURL="https://github.com/ffuf/ffuf/releases/download/${LATEST_VER}/ffuf_${relNum}_linux_amd64.tar.gz"
		ffufPkg="ffuf_${relNum}_linux_amd64.tar.gz"
		wget -q "$binURL"
		tar xvzf "$ffufPkg" &> /dev/null && rm "$ffufPkg"
		$SUDO mv $ffufDir /usr/share/ && $SUDO ln -s /usr/share/ffuf/ffuf /usr/bin/ffuf && echo -e "\nffuf installed.\n"
		cd $ARdir
	    fi
	    
	    #enum4linux-ng installation if not on system
	    if which enum4linux-ng &> /dev/null ; then 
	    	echo -e "\nenum4linux-ng detected installed, moving on.\n"
	    else
	        echo -e "\nenum4linux-ng not detected, installing...\n(this make take a moment, so please be patient)...\n"
	        e4lngDir="$ARdir/enum4linux-ng"
		mkdir $e4lngDir && cd $e4lngDir
                #grab necessary files
	        wget -q https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/enum4linux-ng.py
                wget -q https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/requirements.txt
	    
	        #install deps
	        yes | $SUDO apt install smbclient python3-ldap3 python3-yaml python3-impacket  &> /dev/null
	        /usr/bin/pip3 install -r requirements.txt  &> /dev/null
		$SUDO /usr/bin/pip3 install -r requirements.txt  &> /dev/null	#install as sudo in case needed when running sudo autorecon
	        #set to $PATH (vs trying to find where user installed & sourcing that dir)
	        $SUDO cp enum4linux-ng.py /usr/bin/enum4linux-ng
	        $SUDO chmod +x /usr/bin/enum4linux-ng
	        #cleanup
	        cd $ARdir && rm -rf $e4lngDir
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
                cd $ARdir
	    fi

	    break
	    ;;

        "do not install etc tools")
            echo -e "\nskipping install of extra/non-required tools\n"
	    
	    break
	    ;;

         "Quit")
	    echo -e "\nExiting...\n"
            
	    exit 1
	    ;;
	    
        *) echo "invalid option $REPLY";;
    esac
done

echo -e "\nPrerequisiste install checks done, starting autorecon install.\n\n" && sleep 1

pipxInstall () {
	    #function to take care of pipx setup & installation of AutoRecon via pipx
	    #install if pipx if it does not exist on sys
	    if which pipx &> /dev/null ; then
	    	echo -e "\n\npipx detected installed, moving on.\n"
	    else
	    	echo -e "\n\npipx not detected, installing...\n"
		yes | $SUDO apt install pipx &> /dev/null && echo -e "\npipx installed.\n"
	    fi
	    
	    python3 -m pip install --user pipx --no-warn-script-location &> /dev/null
	    #start another bash interactive shell to ensure PATH updates for pipx propogate before continuing further install/config (for some reason source ~/.bashrc doesn't work)
	    #!/bin/bash -li
	    python3 -m pipx ensurepath &> /dev/null
	    #install autorecon using pipx
	    echo -e "\nInstalling AutoRecon using pipx, please be patient...\n"
	    pipx install --spec git+https://github.com/initinfosec/AutoRecon.git autorecon &> /dev/null
	    echo "alias ars='sudo $(which autorecon)'" >> ~/.bash_aliases && source ~/.bashrc	#have alias look for location of AR at runtime using sudo
	    #N.B. if using sudo, may desire to run scans in the following fashion: $sudo autorecon <opts> <target> && sudo chown -R $USER:$USER <ouput_dir>
	    printf '\n%.s' {1..3}
	    echo -e "\n     * * * * *     \n"
	    echo -e "\n\nAutoRecon installed using pipx. Complete!\n" ; echo -e "AutoRecon location: $(which autorecon) - you can run from anywhere simply using 'autorecon'"
	    echo -e "\n\nThe script is also installed with & aliased to run with sudo as 'ars', e.g. 'ars <options> <host>', or can also be run simply as 'sudo autorecon'\n"
}


pip3Install () {
	    echo -e "\nInstalling AutoRecon using pip3, please be patient...\n"
	    python3 -m pip install git+https://github.com/initinfosec/AutoRecon.git --no-warn-script-location &> /dev/null
	    $SUDO python3 -m pip install git+https://github.com/initinfosec/AutoRecon.git --no-warn-script-location &> /dev/null	#install as sudo tooo in case user wants to run AR with sudo privs
	    export PATH=$PATH:~/.local/bin
	    source ~/.bashrc
	    #start another bash interactive shell to ensure PATH updates for pip3 propogate before continuing further install/config (for some reason source ~/.bashrc doesn't work)
	    #!/bin/bash -li
	    echo "alias ars='sudo $(which autorecon)'" >> ~/.bash_aliases && source ~/.bashrc	#have alias look for location of AR at runtime using sudo
	    #N.B. if using sudo, may desire to run scans in the following fashion: $sudo autorecon <opts> <target> && sudo chown -R $USER:$USER <ouput_dir>
	    printf '\n%.s' {1..3}
	    echo -e "\n     * * * * *     \n"
	    echo -e "\n\nAutoRecon installed using pip3. Complete!\n" ; echo -e "AutoRecon location: $(which autorecon) - you can run from anywhere simply using 'autorecon'"
	    echo -e "\n\nThe script is also installed with & aliased to run with sudo as 'ars', e.g. 'ars <options> <host>', or can also be run simply as 'sudo autorecon'\n"
}

standaloneInstall () {
	    echo -e "\n\nInstalling AutoRecon a manual/standalone script, please be patient...\n"
	    #install AutoRecon using manual/standalone script method
	    python3 -m pip install -r $ARdir/requirements.txt &> /dev/null
	    $SUDO python3 -m pip install -r $ARdir/requirements.txt &> /dev/null	#run as sudo too in case want to run AR with root privs
	    echo "alias autorecon='python3 ${ARscript}'" >> ~/.bash_aliases && source ~/.bashrc
	    echo "alias ars='sudo python3 ${ARscript}'" >> ~/.bash_aliases && source ~/.bashrc	#alias with sudo in case user wants to run AR as sudo
	    printf '\n%.s' {1..3}
	    echo -e "\n     * * * * *     \n"	
	    echo -e "\nScript installed at ${ARscript}\n"
	    echo -e "\nThe script is also installed with & aliased to run with sudo as 'ars', e.g. 'ars <options> <host>', or can also be run simply as 'sudo autorecon'\n"
	    echo -e "\n\nAutoRecon installed as a manual/standalone script. Complete!\n\n"
}


PS3='Please select your install method for AutoRecon: '
options=("pipx - *recommended*" "pip3" "manual/standalone script" "Quit")
select opt in "${options[@]}"
do
    case $opt in
	    "pipx - *recommended*")
	    #install AutoRecon using pipx
	    pipxInstall	 	#call to function to install/configure AR in fresh shell so changes are properly applied
	    break
            ;;

        "pip3")
	    #install autorecon using pip3
	    pip3Install		#call to function to install/configure AR in fresh shell so changes are properly applied
	    break
            ;;

        "manual/standalone script")
            standaloneInstall	#call to function to install/configure AR the 'manual' way as a standalone script
	    break
            ;;

         "Quit")
	    echo -e "\nExiting...\n"
            exit 1
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

finishUp () {
	#spawn new shell in case user wants to use the tool right away. Give message about relogin/new shell if any issues.
	echo -e "\nAutorecon has been installed. Loading you into a fresh new shell so updates are [hopefully] applied immediately =).\n"
	echo -e "You can run autorecon from here now if 'autorecon' or 'ars' show proper script output.\n"
	echo -e "If the commands do not seem to work properly or you have issues, exit the entire TTY/terminal instance and open a new shell to ensure updates from the script are applied.\n\n"
	
	#Completion banner
	printf '\n%.s' {1..3}
	printf '============================================================================================='
	printf '\n%.s' {1..3}
	echo -e "AutoRecon by Tib3rius installed!   ::   more info at: https://github.com/Tib3rius/AutoRecon\n"
	echo -e "install script/wrapper by @initinfosec\n\n"
	echo "'It's like bowling with bumpers.' - @ippsec"
	printf '\n%.s' {1..2}
	printf '============================================================================================='
	printf '\n%.s' {1..3}

	/bin/bash -li		#spawn new interactive login shell in hopes changes propagate.
}

finishUp
