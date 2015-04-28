#!/bin/bash

# author: zhangbo
# email: zhangbo3@yy.com
# time: 2015/04/28
# This file be used to call the Cloud-MySQL backend API, verbose document bellow:
# http://wiki.dev.game.yy.com/moin/CloudMySQL/BackendAPI

usage() {
    echo "Cloud-MySQL backend API manager"
    echo "[-s|--service SERVICE] the backend API service url"
    echo "[-a|--action ACTION] the action is api interfaces"
    echo "[-p|--port PORT] the port is mysql port"
    echo "[-e|--engine ENGINE] innodb or myisam, default is innodb"
    echo "[-m|--memory MEMORY] the memory should be 1G, 2G, 4G, 8G"
    echo "[-d|--device DEVICE] should be ssd or non-ssd"
    echo "[-t|--toekn TOKEN] the token of api"
    echo "[-h|--help] it's me"
    echo "[-v|--verbose] show verbose infomation"
    echo "example:"
    echo "mysql_client.sh -s http://113.107.161.240:3000 -p 4201 --token xxxxx --action create_instance --debug --verbose"
    echo "mysql_client.sh -s http://113.107.161.240:3000 -p 4201 --token xxxxx --action show_master_status --debug"
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

TEMP=`getopt -o s:p:a:e:m:d:t:v,h \
    --long service:,port:,action:,engine:,memory:,device:,token:,debug,verbose,help -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true ; do
    case $1 in
        -s|--service)
            SERVICE=$2; shift 2 ;;

        -p|--port)
            PORT=$2; shift 2 ;;

        -a|--action)
            ACTION=$2; shift 2 ;;

        -e|--engine)
            ENGINE=$2; shift 2 ;;

        -m|--memory)
            MEMORY=$2; shift 2 ;;

        -d|--device)
            DEVICE=$2; shift 2 ;;

        -t|--token)
            TOKEN=$2; shift 2 ;;

        --debug)
            DEBUG=1; shift ;;

        -v|--verbose)
            VERBOSE="v"; shift ;;

        -h|--help)
            HELP=1; shift ;;

        --)
            shift; break ;;

        *)
            echo "unknown argument $1"; exit 1 ;;
    esac
done

if [[ x"$HELP" = x"1" ]]; then
    usage
    exit 0
fi

if [[ $TOKEN = "" ]]; then
    echo "token argument must be include, use [--token youtoken]"
    exit 1;
fi

if [[ $ACTION = "" ]]; then
    echo "action argument must be include, use [-a action| --action action]"
    echo "the action is the interface of MySQL Backend which in document"
    exit 1;
fi

[[ `echo "$DEVICE" | grep -iE "ssd|non-ssd"` ]] || DEVICE="ssd"
[[ `echo "$ENGINE" | grep -iE "innodb|myisam"` ]] || ENGINE="innodb"
[[ `echo "$MEMORY" | grep -iE "[1,2,4,8]G"` ]] || MEMORY="1G"

gen_token=$(echo -n "$TOKEN$(date "+%Y%m%d%H")$PORT" | md5sum | awk -F ' ' '{print $1}' | tr -s ["\n"])

debug() {
    if [[ x"$DEBUG" = x"1" ]]; then
        echo "[DEBUG]service: "$SERVICE
        echo "[DEBUG]port: "$PORT
        echo "[DEBUG]action: "$ACTION
        echo "[DEBUG]engine: "$ENGINE
        echo "[DEBUG]memory: "$MEMORY
        echo "[DEBUG]device: "$DEVICE
        echo "[DEBUG]gen_token: "$gen_token
    fi
}


debug

if [[ x"$VERBOSE" = x"v" ]]; then
    CURL="curl -v"
else
    CURL="curl"
fi

create() {
    echo $"creating instance to $IPADDR with instance port $PORT"
    $CURL $VERBOSE $SERVICE/create_instance?"token=$gen_token&port=$PORT&device=$DEVICE&role=master&engine=$ENGINE&memory=$MEMORY"
}

drop() {
    echo $"droping instance to $IPADDR with instance port $PORT"
    $CURL $VERBOSE $SERVICE/drop_instance?"token=$gen_token&port=$PORT&device=ssd"
}

shutdown() {
    echo $"shutdown instance to $IPADDR with instance port $PORT"
    $CURL $SERVICE/shutdown_instance?"token=$gen_token&port=$PORT&device=ssd"
}

show() {
    echo $"$ACTION instance to $IPADDR with instance port $PORT"
    $CURL $SERVICE/"$ACTION""?token=$gen_token&port=$PORT&device=ssd"
}

case "$ACTION" in
    create_instance)
        create
        ;;
    drop_instance)
        shutdown
        drop
        ;;
    shutdown_instance)
        shutdown
        ;;
    *)
        show
        ;;
esac
