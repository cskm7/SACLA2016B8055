#!/bin/bash

if [ $# -eq 0 ];
then
    echo "Pre-process run using DataConvert4, including background subtraction"
    echo ""
    echo "USAGE: pre_process_run.sh <RUN_NUMBER> <BG_NUMBER> [<RUN_NUMBER2> <BG_NUMBER2> ...]"
else
    for (( i=1; i<=$#/2; i++ )); do
        ((j=2*i-1))
        eval RUNNUMBER=\${$j}
        ((j=2*i))
        eval BGNUMBER=\${$j}
	WORKDIR="/UserData/fperakis/2016_10/"
	SRCDIR=$WORKDIR"codes/"
	TAGDIR=$SRCDIR"tags/"
	LOGDIR=$SRCDIR"logs/"
	
        if test ! -e $WORKDIR; then
            mkdir $WORKDIR
            echo "Created "$WORKDIR
        fi
        if test ! -e $SRCDIR; then
            mkdir $SRCDIR
            echo "Created "$SRCDIR
        fi
        if test ! -e $TAGDIR; then
            mkdir $TAGDIR
            echo "Created "$TAGDIR
        fi
        if test ! -e $LOGDIR; then
            mkdir $LOGDIR
            echo "Created "$LOGDIR
        fi
	
	RUNDIR=$WORKDIR"run"$RUNNUMBER"/"
	echo 'Run directory: '$RUNDIR
	BGDIR=$WORKDIR"run"$BGNUMBER"/"
	echo 'Background directory: '$BGDIR

        if test ! -e $RUNDIR; then
            mkdir $RUNDIR
            echo "Created "$RUNDIR
        fi
        if test ! -e $BGDIR; then
            mkdir $BGDIR
            echo "Created "$BGDIR
        fi
        CURRDIR=`pwd`

	cd $SRCDIR

	echo 'Making tag lists...'
	MakeTagList -b 3 -r $RUNNUMBER -det 'MPCCD-8-2-002' -out $TAGDIR/tag_$RUNNUMBER.list
	MakeTagList -b 3 -r $BGNUMBER -det 'MPCCD-8-2-002' -out $TAGDIR/tag_$BGNUMBER.list

	echo 'Converting background run'$BGNUMBER'...'
	DataConvert4 -l $TAGDIR/tag_$BGNUMBER.list -dir $BGDIR -o $BGNUMBER.h5 > $LOGDIR/log_$BGNUMBER

        #cd $BGDIR

	echo 'Averaging background run'$BGNUMBER'...'
	ImgAvg -inp $BGDIR/$BGNUMBER.h5 -out $BGDIR/$BGNUMBER'_avg.h5' > $LOGDIR/log_$BGNUMBER'_avg'

	echo 'Converting BG-subtracted run'$RUNNUMBER'...'
	DataConvert4 -l $TAGDIR/tag_$RUNNUMBER.list -dir $RUNDIR -o $RUNNUMBER'_corrected.h5' -bkg $BGDIR/$BGNUMBER'_avg.h5' > $LOGDIR/log_$RUNNUMBER'_corrected'
	#
        #echo "Submitting "$CONF" to "$RUNDIR"..."
        #echo '#!/bin/bash' > emc.sh
        #echo '' >> emc.sh
        #echo '#SBATCH -o emc.out' >> emc.sh
        #echo '#SBATCH -e emc.err' >> emc.sh
        #echo '#SBATCH --gres=gpu:1' >> emc.sh
        #echo '' >> emc.sh
        #echo 'HOST=`hostname`' >> emc.sh
        #echo 'echo "Node: $HOST"' >> emc.sh
        #echo 'emc' >> emc.sh
	#
        #sbatch emc.sh
	
        cd $CURRDIR
	echo 'Done!'
    done
fi