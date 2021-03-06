#!/bin/bash
# script to bootstrap setting up a mac with ansible 

function uninstall {

echo "WARNING : This will remove homebrew and all applications installed through it"
echo -n "are you sure you want to do that? [y/n] : "
read confirmation

if [ $confirmation == "y" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
    exit 0
else
  echo "keeping everything intact"
  exit 0
fi

}

if [[ $1 == "uninstall" ]]; then
    uninstall
fi

echo "Setting up your mac"

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
sudo pip install ansible --quiet

export PATH="$HOME/Library/Python/3.8/bin/:$PATH"

installdir="/tmp/setup"
mkdir $installdir

git clone https://github.com/jonioliveira/dotfiles.git $installdir 
if [ ! -d $installdir ]; then
    echo "failed to find setupmac."
    echo "git cloned failed"
    exit 1
else
    cd $installdir 
    ansible-playbook -i ./hosts playbook.yml --verbose
fi

echo "cleaning up..."

rm -Rfv /tmp/$installdir

echo "and we are done! Enjoy!"

exit 0
