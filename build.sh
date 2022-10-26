#!/usr/bin/env bash

bundle install

curl -s https://fastapi.metacpan.org/v1/download_url/Image::ExifTool > Image-ExifTool.json
download_url=$(ruby -r json -e 'puts JSON.parse($stdin.read)["download_url"]' < Image-ExifTool.json)
archive=$(basename "$download_url")
directory=$(basename "$download_url" .tar.gz)
echo ==========
if [ ! -f "$archive" ]
then
    curl -O "$download_url"
fi
if [ ! -d "$directory" ]
then
    tar -xf "$archive"
fi
