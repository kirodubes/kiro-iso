#!/bin/bash

rm personal_repo*

echo "repo-add"
repo-add -n -R personal_repo.db.tar.gz *.pkg.tar.zst

sleep 1

rm personal_repo.db

rm personal_repo.files

mv personal_repo.db.tar.gz personal_repo.db

mv personal_repo.files.tar.gz personal_repo.files

echo "####################################"
echo "Repo Updated!!"
echo "####################################"
