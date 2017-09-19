#!/bin/bash

image=vxlan-testnode

if [ -z "$role" ]; then
	printf "do you want to run a node or a hub? [node/hub] "
	read role
	if ! egrep 'node|hub' <<< "$role"; then
		echo "invalid choice."
		exit 1
	fi
	printf "\nthank you. you can specify that as \$role as well.\n\n"
fi
docker run \
	--link sd:sd \
	--privileged \
	-e role="$role" \
	-ti --rm \
	$image bash
