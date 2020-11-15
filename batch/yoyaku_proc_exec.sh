#!/bin/sh

# このスクリプト(db_init.sh)のディレクトリの絶対パスを取得
DIR=$(cd $(dirname $0); pwd)

LOGDIR=$DIR/log/yoyaku_kun_`date '+%Y%m%d%H%M%S'`.log

#ログフォルダをmkdir
mkdir -p $DIR/log

#引数なしの場合、システム日付の翌月を抽選の対象月として実行
#引数ありの場合は、"YYYY-MM-DD"を受け付ける前提として、受けっとった日付の月を対象月とする。

if [ $# -eq 0 ]; then
    targetdate=`date '+%Y-%m-%d' -d "1 months"`
fi
if [ $# -eq 1 ]; then
    targetdate=$1
fi

echo $targetdate >> $LOGDIR

# MySQLをバッチモードで実行するコマンド
CMD_MYSQL="mysql -h 127.0.0.1 -u root -p'gf!$eeP58/_UQv%bgxSiRq,C' res_system" >> $LOGDIR


# INSERT文を直接実行
$CMD_MYSQL -e "call chusen_pro('${targetdate}');"  >> $LOGDIR





