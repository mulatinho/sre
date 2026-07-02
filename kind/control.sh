#!/bin/bash
		
help() {
	echo "$0 <start|stop>";
	exit 1
}

if [ ! "$1 " ] ; then
	help
fi

case "$1" in
	"start")
		docker start $(docker ps -aq --filter "name=kind-")
		;;
	"stop")
		docker stop $(docker ps -q --filter "name=kind-")
		docker stop $(docker ps -q --filter "name=(batman|robin)-")
		;;
	*)
		help
		;;
esac
