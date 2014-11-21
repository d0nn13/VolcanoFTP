#!/usr/bin/env bash

script_file="volcano_ftp.rb"
usage=0

if [ $# == 0 ]; then
    usage=1
fi

if [ $usage == 0 ];
    then
    if [ $1 == "start" ];
        then
        ./volcano_ftp.rb &

    elif [ $1 == "stop" ];
        then
        pkill -F .volcano.pid

    elif [ $1 == "restart" ];
        then
        pkill -F .volcano.pid; ./volcano_ftp.rb &
    else
        usage=1
    fi
fi

if [ $usage == 1 ];
    then
    echo "usage: volcano_tools <command>";
    echo ""
    echo "The available commands are:"
    echo "  restart"
    echo "  start"
    echo "  stop"
    echo ""
fi
