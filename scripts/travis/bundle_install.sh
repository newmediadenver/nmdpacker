#!/bin/sh -x
if [ ! -f ~/vendor/bundle/packer/packer ]; then
  wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/0.5.1_linux_amd64.zip && unzip -d packer 0.5.1_linux_amd64.zip
  pwd
  echo 'look here'
  ls -al
  mkdir -p ~/vendor/bundle
  mv packer ~/vendor/bundle
  rm -f 0.5.1_linux_amd64.zip
fi

exit 0
