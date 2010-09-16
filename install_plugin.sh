#!/bin/bash
# install.sh -- created 2010-09-15, Tom Link
# @Last Change: 2010-09-16.
# @Revision:    0.83

if [ -e $HOME/vimfiles ]; then
    VIMFILES=$HOME/vimfiles
else
    VIMFILES=$HOME/.vim
fi
PRE=
CMD=cp


function usage {
    echo "`basename $0` [OPTIONS] DIR1 DIR2 ..."
    echo "If no directories are given, use the directories in \$VIMPLUGINS"
    echo " "
    echo "Options:"
    echo "  -d|--dir DIR ... Destination directory (default: $VIMFILES)"
    echo "  --dry        ... Show which files would be copied"
    echo "  -u|--update  ... Copy only newer files"
    echo "  -v|--verbose ... Show messages"
    echo "  -h|--help    ... Show help"
    exit 1
}


function findfiles {
    find $1 -type f \
        -not -wholename "*/.*" \
        -not -name "_*" \
        -not -name "Makefile" \
        -not -wholename "*/doc/tags" \
        -not -name README \
        -print
}


while [ -n $1 ]; do
    case $1 in
    -d|--dir)
        VIMFILES=$2
        shift 2
        ;;
    -n|--dry)
        PRE=echo
        shift
        ;;
    -u|--update)
        CMD="$CMD -u"
        shift
        ;;
    -v|--verbose)
        CMD="$CMD -v"
        shift
        ;;
    -h|--help)
        usage
        ;;
    *)
        break
        ;;
    esac
done

if [ ! -d "$VIMFILES" ]; then
    echo "Error: Destination directory does not exist: $VIMFILES"
    usage
fi


if [ -z $1 ]; then
    if [ -z $VIMPLUGINS ]; then
        DIRS=`find $VIMPLUGINS -maxdepth 1 -type d -not -name "."`
    else
        echo "Error: \$VIMPLUGINS is undefined and no directories are given"
        usage
    fi
else
    DIRS=$@
fi


for DIR in $DIRS; do
    if [ -d $DIR ]; then
        cd $DIR
        FILES=`findfiles .`
        cd - > /dev/null
        for FILE in $FILES; do
            DDIR=`dirname ${VIMFILES}/$FILE`
            if [ ! -e $DDIR ]; then
                $PRE mkdir -p $DDIR
            fi
            $PRE $CMD $DIR/$FILE ${VIMFILES}/$FILE
        done
    fi
done


# vi: ft=sh:tw=72:ts=4
