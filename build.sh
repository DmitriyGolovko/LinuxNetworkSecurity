#!/bin/bash

git add *
git commit -m "$(cat snapps.log)"
echo "" > snapps.log
git push

cp snapps.sh /bin/snapps
chmod u+x /bin/snapps
