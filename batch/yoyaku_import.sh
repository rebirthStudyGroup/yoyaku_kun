#!/bin/sh

# gz形式で圧縮されたDumpファイルをインポートするバッチ、引数にファイルのパスを指定してください。

DIR=$(cd $(dirname $0); pwd)

LOGDIR=$DIR/log/yoyaku_kun_import_`date '+%Y%m%d%H%M%S'`.log

mkdir -p $DIR/log


if [ $# -eq 0 ]; then
    echo "specify dump file"
    exit
fi
if [ $# -eq 1 ]; then
    targetfile=$1
fi

echo $targetfile >> $LOGDIR


echo "zcat ${targetfile} | mysql -h 127.0.0.1 -u root -p'gf!$eeP58/_UQv%bgxSiRq,C' res_system" >> $LOGDIR
zcat ${targetfile} | mysql -h 127.0.0.1 -u root -p'gf!$eeP58/_UQv%bgxSiRq,C' res_system







