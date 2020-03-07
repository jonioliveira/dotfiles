#Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

#Run brew file
sh brew.sh

#Install ZSH
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

#Configure ZSH
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
cp .p10k.zsh ~/.
cp .zshrc ~/.
source ~/.zshrc

#Install npm global
sh npm.sh

#Install RUST
curl https://sh.rustup.rs -sSf | sh

#Copy Fonts
cp ./fonts/. ~/Library/Fonts

#Copy vscode settings
cp settings.json ~/Library/Application\ Support/Code/User/

#Run mac optimization
sh .macos



