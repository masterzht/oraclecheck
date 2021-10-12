#!/bin/ksh
#
#################################################################################
#
# File name:   dstackprof.sh         v1.02 29-Aug-2008
# Purpose:     Samples target process stack using DTrace, strips the PC function 
#              offsets from output and re-aggregates 
#
# Author:      Tanel Poder
# Copyright:   (c) http://www.tanelpoder.com
#
# Usage:       dstackprof.sh <PID> [SECONDS] [STACKS] [FRAMES]
# 	        
#	        
# Other:       
#              
#              
#
#################################################################################

DEFAULT_SECONDS=5
DEFAULT_FRAMES=100
DEFAULT_STACKS=20

FREQUENCY=1001hz

[ $# -lt 1 ] && echo "  Usage: $0 <PID> [SECONDS] [STACKS] [FRAMES]\n" && exit 1
[ -z $2 ] && SECONDS=$DEFAULT_SECONDS || SECONDS=$2
[ -z $3 ] && STACKS=$DEFAULT_STACKS || STACKS=$3
[ -z $4 ] && FRAMES=$DEFAULT_FRAMES || FRAMES=$4
PROCESS=$1

echo
echo "DStackProf v1.02 by Tanel Poder ( http://www.tanelpoder.com )"
echo "Sampling pid $PROCESS for $SECONDS seconds with stack depth of $FRAMES frames..."
echo

dtrace -q -p $PROCESS -n '
profile-'$FREQUENCY'
/pid == $target/ { 
    @u[copyin(ustack('$FRAMES'))] = count();
} 
END { 
    printa(@u);
}
'
