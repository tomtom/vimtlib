#!/bin/bash
# install.sh -- created 2010-09-15, Tom Link
# @Last Change: 2010-09-26.
# @Revision:    0.140

if [ -e $HOME/vimfiles ]; then
    VIMFILES=$HOME/vimfiles
else
    VIMFILES=$HOME/.vim
fi

VIM=vim
PRE=
CP=cp
MKDIR=mkdir
HELPTAGS=false
VERBOSE=false

if [ -e $VIMFILES/install_plugin.rc ]; then
    . $VIMFILES/install_plugin.rc
fi


function usage {
    echo "`basename $0` [OPTIONS] DIR1 DIR2 ..."
    echo "If no directories are supplied, use the directories in \$VIMPLUGINS"
    echo " "
    echo "Options:"
    echo "  -d|--dir DIR  ... Destination directory (default: $VIMFILES)"
    echo "  -n|--dry      ... Show which files would be copied"
    echo "  -t|--helptags ... Create helptags"
    echo "  -u|--update   ... Copy only newer files"
    echo "  --vim CMD     ... VIM command (default: ${VIM})"
    echo "  -v|--verbose  ... Show messages"
    echo "  -h|--help     ... Show help"
    echo " "
    echo "Configuration file: $VIMFILES/install_plugin.rc"
    exit 1
}


function findfiles {
    find $1 -type f \
        -not -wholename "*/.*" \
        -not -wholename "*/_*" \
        -not -name "Makefile" \
        -not -wholename "*/doc/tags" \
        -not -name README \
        -print
}


function log {
    if [ "$VERBOSE" == true ]; then
        echo $@
    fi
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
    -t|--helptags)
        HELPTAGS=true
        shift
        ;;
    -u|--update)
        CP="$CP -u"
        shift
        ;;
    --vim)
        VIM=$2
        shift 2
        ;;
    -v|--verbose)
        CP="$CP -v"
        MKDIR="$MKDIR -v"
        VERBOSE=true
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
        echo "No directory is given and \$VIMPLUGINS is not set."
        read -p "Copy files from '$PWD' to '$VIMFILES'? (y/N) " yesno
        if [ "$yesno" != 'y' ]; then
            echo "Cancel!"
            exit 5
        fi
    fi
    if [ -n $VIMPLUGINS ]; then
        DIRS=`find $VIMPLUGINS -maxdepth 1 -type d -not -name ".*" -not -name "_*"`
    else
        echo "Error: \$VIMPLUGINS is undefined and no directories are given"
        usage
    fi
else
    DIRS=$@
fi


for DIR in $DIRS; do
    if [ -d $DIR ]; then
        log Plugin: $DIR
        cd $DIR
        FILES=`findfiles .`
        cd - > /dev/null
        for FILE in $FILES; do
            DDIR=`dirname ${VIMFILES}/$FILE`
            if [ ! -e $DDIR ]; then
                $PRE $MKDIR -p $DDIR
            fi
            $PRE $CP $DIR/$FILE ${VIMFILES}/$FILE
        done
    fi
done


if [ "$HELPTAGS" == true ]; then
    if [ -d $VIMFILES/doc ]; then
        cd $VIMFILES
        log Create helptags ...
        $VIM -u NONE -U NONE -c "helptags doc|q"
        cd - > /dev/null
    fi
fi
        
log Done!


# vi: ft=sh:tw=72:ts=4
