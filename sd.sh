#!/usr/bin/env bash

TRASH_PATH="$HOME/trash" # trash path
TRASH_FILES_PATH="$TRASH_PATH/files"
TRASH_INFO_PATH="$TRASH_PATH/info"

# buffers
STRING_BUFFER=''

if [ ! -d $TRASH_FILES_PATH ]; then
    mkdir -p $TRASH_FILES_PATH
fi
if [ ! -d $TRASH_INFO_PATH ]; then
    mkdir -p $TRASH_INFO_PATH
fi

# show usage
function Info() {
    echo "A simple soft delete script"
    echo "Usage: $0 [FILE]"
    echo "   or: $0 [OPTION] [FILE]"
    echo
    echo "  -d            delete file in the trash"
    echo "  -D            empty the trash"
    echo "  -h -? --help  show this message and exit"
    echo "  -l            list files in the trash"
    echo "  -r            recover file"
}

# format datetime string
function FormatDatetime() {
    STRING_BUFFER="${1:0:4}-${1:4:2}-${1:6:2} ${1:8:2}:${1:10:2}:${1:12:2}"
}

# list files in the trash
function List() {
    if [ -z "`ls $TRASH_INFO_PATH`" ]; then # skip when trash is empty
        return
    fi
    echo ' TYPE | DELETION-TIME       | FILENAME'
    echo '------+---------------------+----------'
    for file in `ls -rt $TRASH_INFO_PATH`; do
        type="FILE"
        if [ -d "$TRASH_FILES_PATH/$file" ]; then
            type=" DIR"
        fi
        read line < "$TRASH_INFO_PATH/$file" 
        FormatDatetime ${line:5}
        time=$STRING_BUFFER
        originName=${file:`expr index $file .`}
        echo " $type | $time | $originName"
    done
}

# move file into trash
function Delete()
{
    if [ ! -e $1 ]; then
        echo "No such file or directory"
        exit 1
    fi
    file=`basename $1`
    path=`dirname $1`
    if [ $path == '.' ]; then
        path=`pwd`
    fi
    declare -i i=0
    while [ -e "$TRASH_FILES_PATH/$i.$file" ]; do
        ((++i))
    done
    mv "$path/$file" "$TRASH_FILES_PATH/$i.$file"
    info_file="$TRASH_INFO_PATH/$i.$file"
    time=`date +%Y%m%d%H%M%S`
    echo "time=$time" > $info_file
    echo "path=$path/$file" >> $info_file
}

# remove file in the trash
function Remove() {
    if [ ! -e "$TRASH_INFO_PATH/0.$1" ]; then
        echo "No such file or directory in the trash"
        exit 1
    fi
    if [ ! -e "$TRASH_INFO_PATH/1.$1" ]; then # only one file
        rm -rf $TRASH_FILES_PATH/0.$1 $TRASH_INFO_PATH/0.$1
        return
    fi
    echo ' #  | TYPE | DELETION-TIME       | PATH'
    echo '----+------+---------------------+------'
    declare -i i
    for ((i=0; ; ++i)); do
        if [ ! -e "$TRASH_INFO_PATH/$i.$1" ]; then
            break
        fi
        type='FILE'
        if [ -d "$TRASH_FILES_PATH/$i.$1" ]; then
            type=' DIR'
        fi
        while read line; do
            eval "$line"
        done < "$TRASH_INFO_PATH/$i.$1"
        FormatDatetime $time
        time=$STRING_BUFFER
        printf " %2d | $type | $time | $path\n" $i
    done
    i=$i-1
    declare -i max=$i
    c=''
    echo $c
    read -p 'Which one you want to delete: ' c
    for ((; i >= 0; --i)); do
        if [ "$c" == "$i" ]; then
            rm -r $TRASH_FILES_PATH/$c.$1 $TRASH_INFO_PATH/$c.$1
            for ((; i < max; ++i)); do
                declare -i t=$i+1
                mv $TRASH_FILES_PATH/$t.$1 $TRASH_FILES_PATH/$i.$1
                mv $TRASH_INFO_PATH/$t.$1 $TRASH_INFO_PATH/$i.$1
            done
            return
        fi
    done
    echo "Delete canceled"
}

# recover file in the trash
function Recover() {
    if [ ! -e "$TRASH_INFO_PATH/0.$1" ]; then
        echo "No such file or directory in the trash"
        exit 1
    fi
    if [ ! -e "$TRASH_INFO_PATH/1.$1" ]; then # only one file
        while read line; do
            eval "$line"
        done < "$TRASH_INFO_PATH/0.$1"
        if [ -e $path ]; then
            echo "$path already exists"
            exit 1
        else
            mv $TRASH_FILES_PATH/0.$1 $path
            rm -rf $TRASH_INFO_PATH/0.$1
        fi
        return
    fi
    echo ' #  | TYPE | DELETION-TIME       | PATH'
    echo '----+------+---------------------+------'
    declare -i i
    for ((i=0; ; ++i)); do
        if [ ! -e "$TRASH_INFO_PATH/$i.$1" ]; then
            break
        fi
        type='FILE'
        if [ -d "$TRASH_FILES_PATH/$i.$1" ]; then
            type=' DIR'
        fi
        while read line; do
            eval "$line"
        done < "$TRASH_INFO_PATH/$i.$1"
        FormatDatetime $time
        time=$STRING_BUFFER
        printf " %2d | $type | $time | $path\n" $i
    done
    i=$i-1
    declare -i max=$i
    c=''
    echo $c
    read -p 'Which one you want to recover: ' c
    for ((; i >= 0; --i)); do
        if [ "$c" == "$i" ]; then
            if [ -e $path ]; then
                echo "$path already exists"
                exit 1
            else
                mv $TRASH_FILES_PATH/$c.$1 $path
                rm -rf $TRASH_INFO_PATH/$c.$1
            fi
            for ((; i < max; ++i)); do
                declare -i t=$i+1
                mv $TRASH_FILES_PATH/$t.$1 $TRASH_FILES_PATH/$i.$1
                mv $TRASH_INFO_PATH/$t.$1 $TRASH_INFO_PATH/$i.$1
            done
            return
        fi
    done
    echo "Recover canceled"
}

# empty the trash
function Empty() {
    ans=''
    read -p 'Would you want to empty the trash? (y/N): ' ans
    if [ $ans == "y" ] || [ $ans == "Y" ]; then
        rm -rf $TRASH_PATH/files/*
        rm -rf $TRASH_PATH/info/*
    fi
    # case $ans in
    #     y);&
    #     Y)
    #         rm -rf $TRASH_PATH/files/*
    #         rm -rf $TRASH_PATH/info/*
    #         ;;
    # esac
}

if [ $# -ge 1 ]; then
    case $1 in
        -l)
            List;;
        -d)
            if [ $# -ne 2 ]; then
                Info
                exit 1
            fi
            Remove $2;;
        -\?)
            Info;;
        --help)
            Info;;
        -D)
            Empty;;
        -r)
            if [ $# -ne 2 ]; then
                Info
                exit 1
            fi
            Recover $2;;
        *)
            Delete $1;;
    esac
    exit 0
fi

Info
