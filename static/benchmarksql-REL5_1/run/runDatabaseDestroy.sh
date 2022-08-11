#!/usr/bin/env bash

if [ $# -ne 1 ] ; then
    echo "usage: $(basename $0) PROPS" >&2
    exit 2
fi

PROPS="$1"
if [ ! -f "${PROPS}" ] ; then
    echo "${PROPS}: no such file or directory" >&2
    exit 1
fi

DB="$(grep '^db=' $PROPS | sed -e 's/^db=//')"
USER="$(grep '^user=' $PROPS | sed -e 's/^user=//' )"
PASSWORD="$(grep '^password=' $PROPS | sed -e 's/^password=//' )"

STEPS="tableDrops storedProcedureDrops"

for step in ${STEPS} ; do
    ./runSQL.sh "${PROPS}" $step
done
