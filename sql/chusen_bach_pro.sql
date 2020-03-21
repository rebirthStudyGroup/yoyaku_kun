DROP PROCEDURE IF EXISTS `chusen_pro`;
DELIMITER //
CREATE PROCEDURE chusen_pro(IN start_date date)
BEGIN
  -- DECLARE 変数

  -- DECLARE CURSOR
  
  
  -- エラー時にロールバックする。
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        SELECT @sqlstate, @errno, @text;
        ROLLBACK;
    END;

    -- 途中で使用するテーブルを用意(基本一時テーブル)
    -- 終了時は削除せず、次回実行時に削除する。（調査用に）
    DROP TABLE IF EXISTS accounts_lottery_pool_tmp;
    CREATE TABLE accounts_lottery_pool_tmp LIKE accounts_lottery_pool;
    ALTER TABLE accounts_lottery_pool_tmp ADD rand_lottery double;
    
    DROP TABLE IF EXISTS lottery_tmp;
    CREATE TABLE `lottery_tmp` (
      `reservation_id` int(11) NOT NULL DEFAULT '0',
      `lodging_date` date NOT NULL,
      `number_of_rooms` smallint(6) NOT NULL,
      `rand_lottery` double DEFAULT NULL,
      `sum_number` bigint(21) DEFAULT NULL,
      `tmp_lodging_date` varchar(10) NOT NULL DEFAULT '',
      Primary key (reservation_id, lodging_date)
    );
    
    DROP TABLE IF EXISTS ng_list;
    CREATE TABLE `ng_list` (
      `reservation_id` int(11) NOT NULL DEFAULT '0',
      Primary key (reservation_id)
    );
    
    DROP TABLE IF EXISTS ok_list;
    CREATE TABLE `ok_list` (
      `reservation_id` int(11) NOT NULL DEFAULT '0',
      Primary key (reservation_id)
    );


  START TRANSACTION;

  -- トランザクション処理。
  
        -- 抽選テーブルに乱数を付与したテーブルを作成する。
        -- 抽出条件は渡された日付～月末まで
        INSERT accounts_lottery_pool_tmp
        SELECT 
            reservation_id,
            user_id,
            username,
            check_in_date,
            check_out_date,
            number_of_rooms,
            number_of_guests,
            priority,
            purpose,
            is_defeated,
            RAND() + 0.0000001 AS rand_lottery
        FROM
            accounts_lottery_pool
        WHERE
            check_in_date BETWEEN DATE_FORMAT(start_date, '%Y-%m-01') AND LAST_DAY(start_date) AND
            is_defeated = 0
        UNION ALL    
        SELECT 
            acc_res.reservation_id,
            acc_res.user_id,
            acc_res.username,
            acc_res.check_in_date,
            acc_res.check_out_date,
            acc_res.number_of_rooms,
            acc_res.number_of_guests,
            0,
            0,
            0,
            0 AS rand_lottery
        FROM
            accounts_reservations acc_res
        WHERE
            EXISTS (
                SELECT 1 FROM accounts_lodging acc_lod
                WHERE 
                    acc_res.reservation_id = acc_lod.reservation_id AND
                    acc_lod.lodging_date BETWEEN DATE_FORMAT(start_date, '%Y-%m-01') AND LAST_DAY(start_date)
            ) 
        ;
        
        SELECT * FROM accounts_lottery_pool_tmp;
        
        
        -- 抽選テーブルと宿泊テーブルを結合、宿泊日ごとにブレイクして、部屋数を足し上げて、sum_numberにいれる。
        -- 宿泊日→乱数でソートしているので、乱数が小さいものが上にくる。乱数が大きいものが下になってて結果的にsum_numberが大きくなる
        set @no:=0;
        set @lodging_date_tmp:=null;
        INSERT INTO lottery_tmp 
        SELECT 
            lottery.reservation_id,
            lottery.lodging_date,
            lottery.number_of_rooms,
            lottery.rand_lottery,
            if(@lodging_date_tmp <> lottery.lodging_date, @no:=lottery.number_of_rooms, @no:=@no+lottery.number_of_rooms) AS sum_number,
            @lodging_date_tmp:=lottery.lodging_date AS tmp_lodging_date    
        FROM (
            SELECT 
                lot_pool.reservation_id,
                lot_pool.check_in_date,
                lod.lodging_date,
                lot_pool.number_of_rooms,
                lot_pool.rand_lottery
            FROM 
                accounts_lottery_pool_tmp AS lot_pool
            INNER JOIN
                accounts_lodging AS lod
            ON
                lot_pool.reservation_id = lod.reservation_id
            ORDER BY lod.lodging_date, lot_pool.rand_lottery
        ) AS lottery;
        
        SELECT * FROM lottery_tmp;
        
        DELETE FROM lottery_tmp WHERE rand_lottery = 0;
        
        -- 落選ＩＤ
        -- sum_numberが４を超えている場合はその予約はＮＧとみなす
        
        INSERT INTO ng_list
        SELECT reservation_id FROM lottery_tmp 
        WHERE 
            sum_number > 4 OR 
            EXISTS (
                SELECT * FROM calendar_master
                WHERE lottery_tmp.lodging_date = calendar_master.ng_date
            )
        ;
        
        -- 落選ＩＤをもとに、落選フラグを落選に設定
        UPDATE accounts_lottery_pool
        INNER JOIN ng_list
        ON ng_list.reservation_id = accounts_lottery_pool.reservation_id
        SET is_defeated = 1
        ;
        
        
        
        -- 落選になった宿泊日を削除する
        DELETE FROM accounts_lodging
        WHERE
            EXISTS (
                SELECT * FROM accounts_lottery_pool
                WHERE 
                    accounts_lodging.reservation_id = accounts_lottery_pool.reservation_id AND
                    accounts_lottery_pool.is_defeated = 1
                
            );
        
        -- ＯＫリストを作る。→当選
        -- 一つでもＮＧあったらその予約は全部ＮＧ。ＮＧの予約リストを除外したものがＯＫリスト
        INSERT INTO ok_list
        SELECT distinct reservation_id FROM lottery_tmp AS tbl1 
        WHERE 
            NOT EXISTS (
                SELECT * FROM ng_list AS tbl2
                WHERE tbl1.reservation_id = tbl2.reservation_id
        );
        
        -- 抽選テーブル→予約テーブルへ
        INSERT INTO accounts_reservations
        SELECT
            lot_pool.reservation_id,
            lot_pool.user_id,
            lot_pool.username,
            lot_pool.check_in_date,
            lot_pool.check_out_date,
            lot_pool.number_of_rooms,
            lot_pool.number_of_guests,
            lot_pool.purpose,
            1,
            0,
            sysdate()
        FROM
            accounts_lottery_pool AS lot_pool
        INNER JOIN
             ok_list
        ON
            lot_pool.reservation_id = ok_list.reservation_id
        ;
        
        
        -- 移動した予約ＩＤの抽選テーブルを削除
        DELETE
        FROM
            accounts_lottery_pool
        WHERE
            EXISTS (
                SELECT * FROM ok_list WHERE ok_list.reservation_id = accounts_lottery_pool.reservation_id
            )
        ;


  COMMIT;
  SELECT "start_date", start_date AS result FROM DUAL UNION ALL
  SELECT "OK_LIST", reservation_id AS result FROM ok_list UNION ALL
  SELECT "NG_LIST", reservation_id AS result FROM ng_list UNION ALL
  SELECT "result", 'Success!' AS result FROM DUAL;
END//
DELIMITER ;
