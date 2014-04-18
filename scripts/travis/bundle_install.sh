#!/bin/sh -x
if [ ! -f ~/vendor/bundle/packer/packer ]; then
  wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/0.5.1_linux_amd64.zip && unzip -d packer 0.5.1_linux_amd64.zip
  pwd
  mkdir -p $BUNDLE_PATH
  ls -al $BUNDLE_PATH
  mv packer $BUNDLE_PATH/
  rm -f 0.5.1_linux_amd64.zip
fi

exit 0
