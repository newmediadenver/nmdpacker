#!/bin/sh
if [ ! -f ~/.bundle/packer/packer ]; then
  wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/0.5.1_linux_amd64.zip && unzip -d packer 0.5.1_linux_amd64.zip
  mv packer .bundle
  rm -f 0.5.1_linux_amd64.zip
fi

exit 0
