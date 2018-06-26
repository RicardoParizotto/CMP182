#!/bin/bash

OUTFILE="MT3_quality.txt"
INFILE="/LOG/MTLOG3.txt"
QV1=1.5
QV2=3
QV3=6

echo "VIDEO_USER_TILEFORMAT_CONF_REQ_BW_DELAY_LOSS_720Z1_1080Z1_4KZ1_720Z2_1080Z2_4KZ2_720Z3_1080Z3_4KZ3_QSWITCHZ1_QSWITCHZ2_QSWITCHZ3_STALL_STARTUPTIME_ERROR_QUALITYZ1_QUALITYZ2_QUALITYZ3" > $OUTFILE

for LOG in `cat $INFILE` ; do

        TILE=`echo $LOG |cut -d "_" -f3`
        VID=`echo $LOG |cut -d "_" -f1`

        if [ "$VID" = "V1" ]; then
                if [ "$TILE" = "12x4" ]; then
                        ####### V1 #######
                        #12x4
                        nExpectedTilesZ1=60
                        nExpectedTilesZ2=480
                        nExpectedTilesZ3=2340
                else
                        #8x4
                        nExpectedTilesZ1=60
                        nExpectedTilesZ2=480
                        nExpectedTilesZ3=1380
                fi;
        fi;

        if [ "$VID" = "V2" ]; then
                if [ "$TILE" = "12x4" ]; then
                        ####### V2 #######
                        #12x4
                        nExpectedTilesZ1=60
                        nExpectedTilesZ2=480
                        nExpectedTilesZ3=2340
                else
                        #8x4
                        nExpectedTilesZ1=60
                        nExpectedTilesZ2=480
                        nExpectedTilesZ3=1380
                fi;
        fi;
  #ZONE 1
        TC1=`echo $LOG |cut -d "_" -f9`
        TC2=`echo $LOG |cut -d "_" -f10`
        TC3=`echo $LOG |cut -d "_" -f11`
        qz1=$(echo "scale=2; ($QV1*$TC1)+($QV2*$TC2)+($QV3*$TC3)" | bc)
        qz1f=$(echo "scale=2; $qz1/$nExpectedTilesZ1" | bc)

        #ZONE 2
        TC4=`echo $LOG |cut -d "_" -f12`
        TC5=`echo $LOG |cut -d "_" -f13`
        TC6=`echo $LOG |cut -d "_" -f14`
        qz2=$(echo "scale=2; ($QV1*$TC4)+($QV2*$TC5)+($QV3*$TC6)" | bc)
        qz2f=$(echo "scale=2; $qz2/$nExpectedTilesZ2" | bc)

        #ZONE 3
        TC7=`echo $LOG |cut -d "_" -f15`
        TC8=`echo $LOG |cut -d "_" -f16`
        TC9=`echo $LOG |cut -d "_" -f17`
        qz3=$(echo "scale=2; ($QV1*$TC7)+($QV2*$TC8)+($QV3*$TC9)" | bc)
        qz3f=$(echo "scale=2; $qz3/$nExpectedTilesZ3" | bc)

        #echo ${LOG}_${qz1}_${qz2}_${qz3}_${qz1f}_${qz2f}_${qz3f} >> $OUTFILE
        echo ${LOG}_${qz1f}_${qz2f}_${qz3f} >> $OUTFILE

done

