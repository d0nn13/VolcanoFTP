#!/usr/bin/env bash

pid=0
pid_file=".volcano.pid"
server_log_file="volcano.log"
server_name="VolcanoFTP"
server_script_file="volcano_ftp.rb"
usage=0

start()
{
    if [ ! -f $pid_file ]; then
        ./$server_script_file -s -l $server_log_file &
    else
        pid="`cat $pid_file`"
        echo "$server_name: Server already started (PID: $pid)"
    fi
}
stop()
{
    if [ -f $pid_file ]; then
        pkill -F $pid_file
        rm $pid_file
    else
        echo "$server_name: Server already stopped"
    fi
}
restart()
{
    stop
    start
}
usage()
{
    echo "Usage: $server_name Tools <command>";
    echo ""
    echo "The available commands are:"
    echo "  restart"
    echo "  start"
    echo "  stop"
    echo ""
}

if [ $# == 0 ]; then
    usage=1
fi

if [ $usage == 0 ]; then

    if [ $1 == "start" ]; then
        start
    elif [ $1 == "stop" ]; then
        stop
    elif [ $1 == "restart" ]; then
        restart
    else
        usage=1
    fi
fi

if [ $usage == 1 ]; then
    usage
fi
