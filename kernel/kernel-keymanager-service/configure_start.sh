#!/bin/bash

#installs the pkcs11 libraries.
set -e

sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt-get update
sudo apt-get install libc6-dev=2.34-0ubuntu0.21.10.1 -y 

DEFAULT_ZIP_PATH=artifactory/libs-release-local/hsm/client.zip
[ -z "$hsm_zip_file_path" ] && zip_path="$DEFAULT_ZIP_PATH" || zip_path="$hsm_zip_file_path"

echo "Download the client from $artifactory_url_env"
echo "Zip File Path: $zip_path"

wget -q --show-progress "$artifactory_url_env/$zip_path"
echo "Downloaded $artifactory_url_env/$zip_path"

FILE_NAME=${zip_path##*/}

DIR_NAME=$hsm_local_dir_name

has_parent=$(zipinfo -1 "$FILE_NAME" | awk '{split($NF,a,"/");print a[1]}' | sort -u | wc -l)
if test "$has_parent" -eq 1; then
  echo "Zip has a parent directory inside"
  dirname=$(zipinfo -1 "$FILE_NAME" | awk '{split($NF,a,"/");print a[1]}' | sort -u | head -n 1)
  echo "Unzip directory"
  unzip $FILE_NAME
  echo "Renaming directory"
  mv -v $dirname $DIR_NAME
else
  echo "Zip has no parent directory inside"
  echo "Creating destination directory"
  mkdir "$DIR_NAME"
  echo "Unzip to destination directory"
  unzip -d "$DIR_NAME" $FILE_NAME
fi

echo "Attempting to install"
cd ./$DIR_NAME && chmod +x install.sh && sudo ./install.sh
echo "Installation complete"
cd $work_dir

exec "$@"
