#!/bin/bash

if [ -z "$1" ]; then
        echo
        echo usage: $0 network-interface
        echo
        echo e.g. $0 eth0
        echo
        exit
fi

IF=$1

fout="intflogs/$1.speed.txt"

echo "\"time\",\"tx_b\",\"rx_b\"" >> $fout
cont=1
step=1

while true
do
        if ! [ -f "/sys/class/net/$1/statistics/rx_bytes" ]
	then 
		exit
	fi

        R1=`cat /sys/class/net/$1/statistics/rx_bytes`
        T1=`cat /sys/class/net/$1/statistics/tx_bytes`
        sleep $step

        if ! [ -f "/sys/class/net/$1/statistics/rx_bytes" ]
	then 
		exit
	fi

        R2=`cat /sys/class/net/$1/statistics/rx_bytes`
        T2=`cat /sys/class/net/$1/statistics/tx_bytes`
        TBPS=`expr $T2 - $T1`
        RBPS=`expr $R2 - $R1`
        echo "$cont,$TBPS,$RBPS" >> $fout
        cont=$(expr $cont + $step)
done
