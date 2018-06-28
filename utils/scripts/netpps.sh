#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] ; then
        echo
        echo "usage: $0 network-interface timeout (seconds)"
        echo
        echo "e.g. $0 eth0 60"
        exit
fi

IF=$1

fout="intflogs/$1.pps.txt"

echo "\"time\",\"tx_pkts\",\"rx_pkts\"">> $fout
cont=0

while true
do

        if ! [ -f "/sys/class/net/$1/statistics/rx_packets" ]
	then 
		exit
	fi

        R1=`cat /sys/class/net/$1/statistics/rx_packets`
        T1=`cat /sys/class/net/$1/statistics/tx_packets`
        sleep 1

        if ! [ -f "/sys/class/net/$1/statistics/rx_packets" ]
	then 
		exit
	fi
        R2=`cat /sys/class/net/$1/statistics/rx_packets`
        T2=`cat /sys/class/net/$1/statistics/tx_packets`
        TXPPS=`expr $T2 - $T1`
        RXPPS=`expr $R2 - $R1`
        echo "$cont,$TXPPS,$RXPPS" >> $fout
        cont=$(expr $cont + 1)

done
