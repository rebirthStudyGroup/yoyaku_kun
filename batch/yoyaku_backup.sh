#!/bin/sh

# このスクリプト(db_init.sh)のディレクトリの絶対パスを取得
DIR=$(cd $(dirname $0); pwd)
NOWDATETIME=`date '+%Y%m%d%H%M%S'`
LOGDIR=$DIR/log/yoyaku_kun_backup_${NOWDATETIME}.log

echo ${NOWDATETIME} >> $LOGDIR

#ログフォルダをmkdir
mkdir -p $DIR/log

#ダンプファイルのフォルダをmkdir
mkdir -p $DIR/dump


# MySQLをバッチモードで実行するコマンド
mysqldump -h 127.0.0.1 -u root -p'gf!$eeP58/_UQv%bgxSiRq,C' --default-character-set=binary --routines res_system | gzip > $DIR/dump/yoyaku_dump_sql_${NOWDATETIME}.gz

echo $DIR/dump/yoyaku_dump_sql_${NOWDATETIME}.gz >> $LOGDIR
echo "バックアップ終了" >> $LOGDIR

echo "過去ファイル削除" >> $LOGDIR
find $DIR/dump/ -name '*.gz' -mtime +10 >> $LOGDIR
find $DIR/dump/ -name '*.gz' -mtime +10 -delete
echo "過去ファイル削除完了" >> $LOGDIR
