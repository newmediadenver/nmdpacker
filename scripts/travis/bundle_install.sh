#!/bin/sh

ARCHITECTURE=`uname -m`
FILE_NAME="$BUNDLE_ARCHIVE-$ARCHITECTURE.tgz"

cd ~
wget -O "remote_$FILE_NAME" "https://$AWS_S3_BUCKET.s3.amazonaws.com/$FILE_NAME" && tar -xf "remote_$FILE_NAME"
wget -O "remote_$FILE_NAME.sha2" "https://$AWS_S3_BUCKET.s3.amazonaws.com/$FILE_NAME.sha2"
wget --no-check-certificate https://dl.bintray.com/mitchellh/packer/$PACKER_FILENAME && unzip -d packer $PACKER_FILENAME
ls -la .bundle
ls -la
mv packer .bundle
ls -la .bundle

exit 0