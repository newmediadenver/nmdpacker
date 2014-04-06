#!/bin/sh

ARCHITECTURE=`uname -m`
FILE_NAME="$BUNDLE_ARCHIVE-$ARCHITECTURE.tgz"

cd ~
echo "DEBUG: wget -O \"remote_$FILE_NAME\" \"https://$AWS_S3_BUCKET.s3.amazonaws.com/$FILE_NAME\" && tar -xf \"remote_$FILE_NAME\""
wget -O "remote_$FILE_NAME" "https://$AWS_S3_BUCKET.s3.amazonaws.com/$FILE_NAME" && tar -xf "remote_$FILE_NAME"
echo "DEBUG: wget -O \"remote_$FILE_NAME.sha2\" \"https://$AWS_S3_BUCKET.s3.amazonaws.com/$FILE_NAME.sha2\""
wget -O "remote_$FILE_NAME.sha2" "https://$AWS_S3_BUCKET.s3.amazonaws.com/$FILE_NAME.sha2"
echo "DEBUG: pwd"
pwd
echo "DEBUG: ls -la $PWD"
ls -la $PWD
if [ ! -f $PWD/.bundle/packer/packer ]; then
  wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/$PACKER_FILENAME && unzip -d packer $PACKER_FILENAME
  mv packer .bundle
fi

exit 0
