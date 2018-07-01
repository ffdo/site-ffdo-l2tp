#!/bin/bash

TARGETS="1 2 3 4 5 6 7 8 9 10 11"


for target in $TARGETS
do
	bash ./make-site-conf.sh $target > site$target.conf
done
