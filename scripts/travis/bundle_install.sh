#!/bin/sh -x
if [ ! -f nmdpacker/vendor/bundle/packer/packer ]; then
  wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/0.5.1_linux_amd64.zip && unzip -d packer 0.5.1_linux_amd64.zip
  pwd
  mkdir -p nmdpacker/vendor/bundle
  ls -al nmdpacker/vendor/bundle
  mv packer nmdpacker/vendor/bundle/
  ls -al nmdpacker/vendor/bundle/packer
  rm -f 0.5.1_linux_amd64.zip
fi

exit 0
