#!/bin/bash

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew tap caskroom/versions
brew update

brew install ccache
brew install fish
brew install cmake
brew install htop
brew install node
brew install python@2
brew install ruby
brew install jq
brew install git

brew cask install java8

gem install rspec
gem install httparty
gem install persistent_httparty

brew upgrade
brew link --overwrite python@2

echo import .p12 manually
#sudo security import ./MacBuildCertificates.p12 -k "/Library/Keychains/System.keychain" -P #PASS#