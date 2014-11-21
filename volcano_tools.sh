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
        echo "lancement du script"

    elif [ $1 == "stop" ];
        then
        echo "arret du script"

    elif [ $1 == "restart" ];
        then
        echo "restart du script"
    else
        usage=1
    fi
fi

if [ $usage == 1 ];
    then
    echo "usage affiche"
fi
