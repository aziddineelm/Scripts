#!/bin/bash

git add .
read -p "What's the story behind this commit?: " desc
git commit -m "$desc"
git push
:x
