#!/usr/bin/env bash

if ! [[ "$OSTYPE" == "darwin"* ]] && ! [[ "$OSTYPE" == "linux"* ]]; then
    echo "You are not using Mac or Linux";
    exit 1
fi

declare -a deps=("jq" "curl" "openssl" "base64")

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "MacOS was detected ..."

  if ! which brew > /dev/null; then
    echo "install brew ;) https://brew.sh/"
    exit 1
  fi

  for dep in "${deps[@]}"; do
    echo "checking if $dep is installed... "
    
    if ! brew ls --versions "$dep" > /dev/null; then
      echo "installing $dep ..."
      brew install "$dep"
    fi
  done
fi

# echo ‘export PATH=“/usr/local/opt/mysql-client/bin:$PATH”’ >> ~/.zshrc

if [[ "$OSTYPE" == "linux"* ]]; then
  echo "Linux was detected ..."
  
  if ! which apt-get > /dev/null; then
    echo "install apt-get (debian/ubuntu)"
    exit 1
  fi

  for dep in "${deps[@]}"; do
    echo "checking if $dep is installed..."
    
    if ! dpkg-query -l | grep "$dep" > /dev/null; then
      echo "installing $dep ..."
      sudo apt-get install -y "$dep"
    fi
  done
fi

