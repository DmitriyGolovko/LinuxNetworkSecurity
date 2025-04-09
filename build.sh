#!/bin/bash

git add *
git commit -m "$(cat snapps.log)"
echo "" > snapps.log
git push

