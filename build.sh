#!/bin/bash

git add *
git commit -m "$(cat snapps.log)"
echo "" > snapps.log
git push

sudo cp snapps.sh /bin/snapps
sudo chmod u+x /bin/snapps
