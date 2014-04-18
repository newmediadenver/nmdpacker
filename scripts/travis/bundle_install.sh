#!/bin/sh -x
if [ ! -f ~/vendor/bundle/packer/packer ]; then
  wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/0.5.1_linux_amd64.zip && unzip -d packer 0.5.1_linux_amd64.zip
  pwd
  mkdir -p ~/vendor/bundle
  ls -al ~/vendor/bundle
  mv packer ~/vendor/bundle/
  rm -f 0.5.1_linux_amd64.zip
fi

exit 0
