#!/bin/bash

OUTFILE="MTLOG3.txt"
DATADIR="LOG/"
NETCONF="sample.csv"
TILE="8x4"
VIDEO="V1"
USER="U2"

for LOG in `ls -1 $DATADIR` ; do
        tiles720z1=`tail -17 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles1080z1=`tail -16 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles4kz1=`tail -15 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles720z2=`tail -14 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles1080z2=`tail -13 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles4kz2=`tail -12 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles720z3=`tail -11 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles1080z3=`tail -10 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        tiles4kz3=`tail -9 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        qualityswitch1=`tail -5 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        qualityswitch2=`tail -4 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        qualityswitch3=`tail -3 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        stall=`tail -2 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        startuptime=`tail -1 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        #nrChunk720=`tail -3 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        #nrChunk1080=`tail -2 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        #nrChunk4k=`tail -1 ${DATADIR}/$LOG | head -1 |cut -d " " -f 2`
        REQ=$(echo $LOG |cut -d "_" -f 1)
        AUX=$(echo $LOG |cut -d "." -f 1)
        CONF=$(echo $AUX | cut -d "_" -f 4)

        AUX2="@"
        AUX2+=$CONF
        AUX2+="@"
        bandwidth=`cat $NETCONF | grep $AUX2 | cut -d "_" -f 2`
        delay=`cat $NETCONF | grep $AUX2 | cut -d "_" -f 3`
        loss=`cat $NETCONF | grep $AUX2 | cut -d "_" -f 4`

        echo  ${VIDEO}_${USER}_${TILE}_${CONF}_${REQ}_${bandwidth}_${delay}_${loss}_${tiles720z1}_${tiles1080z1}_${tiles4kz1}_${tiles720z2}_${tiles1080z2}_${tiles4kz2}_${tiles720z3}_${tiles1080z3}_${tiles4kz3}_${qualityswitch1}_${qualityswitch2}_${qualityswitch3}_${stall}_${startuptime} >> $OUTFILE

done
