# Постановка задачи

Цели лабораторной работы:

1.  Оптимизация запросов. Индексы. Типы индексов. B-Tree.

2.  Оптимизация запросов. Explain. Profiling.

# Типы индексов

1.  Primary, Unique, Index (B-Tree)

2.  Fulltext (InvertedList)

3.  Clustered/Non clustered

# Инструменты

## Explain

``` sql
EXPLAIN SELECT * FROM title; 
```

    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------+
    |  1 | SIMPLE      | title | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 5713325 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------+
    1 row in set, 2 warnings (0.00 sec)

``` sql
EXPLAIN SELECT * FROM title WHERE titleID = 'tt0468569';
```

    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
    | id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows | filtered | Extra |
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
    |  1 | SIMPLE      | title | NULL       | const | PRIMARY       | PRIMARY | 40      | const |    1 |   100.00 | NULL  |
    +----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
    1 row in set, 1 warning (0.00 sec)

``` sql
EXPLAIN
SELECT * FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
ORDER BY numVotes DESC
```

    +----+-------------+--------------+------------+--------+---------------+---------+---------+--------------------------------+--
    | id | select_type | table        | partitions | type   | possible_keys | key     | key_len | ref                            | r
    +----+-------------+--------------+------------+--------+---------------+---------+---------+--------------------------------+--
    |  1 | SIMPLE      | title_rating | NULL       | ALL    | PRIMARY       | NULL    | NULL    | NULL                           | 9
    |  1 | SIMPLE      | title        | NULL       | eq_ref | PRIMARY       | PRIMARY | 40      | imdb_full.title_rating.titleID |  
    +----+-------------+--------------+------------+--------+---------------+---------+---------+--------------------------------+--
    2 rows in set, 1 warning (0.00 sec)

``` sql
EXPLAIN
SELECT * FROM title
WHERE titleID IN (
    SELECT titleID FROM title_genre 
    WHERE title_genre.genre IN ("Comedy", "Action")
)    
```

    +----+-------------+-------------+------------+--------+---------------+---------+---------+-------------------------------+----
    | id | select_type | table       | partitions | type   | possible_keys | key     | key_len | ref                           | row
    +----+-------------+-------------+------------+--------+---------------+---------+---------+-------------------------------+----
    |  1 | SIMPLE      | title_genre | NULL       | index  | PRIMARY       | PRIMARY | 41      | NULL                          | 911
    |  1 | SIMPLE      | title       | NULL       | eq_ref | PRIMARY       | PRIMARY | 40      | imdb_full.title_genre.titleID |    
    +----+-------------+-------------+------------+--------+---------------+---------+---------+-------------------------------+----
    2 rows in set, 1 warning (0.00 sec)

``` sql
EXPLAIN
SELECT * FROM title
WHERE EXISTS(
    SELECT 1 FROM title_genre 
    WHERE title_genre.genre IN ("Comedy", "Action") 
    AND title.titleID = title_genre.titleID
)
```

    +----+--------------------+-------------+------------+------+---------------+---------+---------+-------------------------+-----
    | id | select_type        | table       | partitions | type | possible_keys | key     | key_len | ref                     | rows
    +----+--------------------+-------------+------------+------+---------------+---------+---------+-------------------------+-----
    |  1 | PRIMARY            | title       | NULL       | ALL  | NULL          | NULL    | NULL    | NULL                    | 5713
    |  2 | DEPENDENT SUBQUERY | title_genre | NULL       | ref  | PRIMARY       | PRIMARY | 40      | imdb_full.title.titleID |     
    +----+--------------------+-------------+------------+------+---------------+---------+---------+-------------------------+-----
    2 rows in set, 2 warnings (0.00 sec)

## Profile

``` sql
SET PROFILING=1;
SET profiling_history_size = 1;
```

``` sql
SHOW PROFILES;
```

    +----------+-------------+---------------------+
    | Query_ID | Duration    | Query               |
    +----------+-------------+---------------------+
    |        1 | 10.16626100 | SELECT * FROM title |
    +----------+-------------+---------------------+
    1 row in set, 1 warning (0.00 sec)

``` sql
SHOW PROFILE FOR QUERY 1;
```

    +----------------------+-----------+
    | Status               | Duration  |
    +----------------------+-----------+
    | starting             |  0.000857 |
    | checking permissions |  0.000005 |
    | Opening tables       |  0.000012 |
    | init                 |  0.000012 |
    | System lock          |  0.000005 |
    | optimizing           |  0.000003 |
    | statistics           |  0.000007 |
    | preparing            |  0.000006 |
    | executing            |  0.000002 |
    | Sending data         | 10.165251 |
    | end                  |  0.000011 |
    | query end            |  0.000007 |
    | closing tables       |  0.000008 |
    | freeing items        |  0.000059 |
    | cleaning up          |  0.000016 |
    +----------------------+-----------+
    15 rows in set, 1 warning (0.00 sec)

# Использование индексов

## Scan

Общее количество фильмов:

``` sql
SELECT COUNT(*) FROM title;
```

    +----------+
    | COUNT(*) |
    +----------+
    |  6243651 |
    +----------+
    1 row in set (1.82 sec)

## Key lookup

Без индекса по полю startYear:

``` sql
SELECT SQL_NO_CACHE * FROM title WHERE startYear = 2019 LIMIT 1000;
```

    +----------+------------+-------------------------------------------------------+
    | Query_ID | Duration   | Query                                                 |
    +----------+------------+-------------------------------------------------------+
    |        6 | 0.72669600 | SELECT * FROM title WHERE startYear = 2019 LIMIT 1000 |
    +----------+------------+-------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec)

``` sql
EXPLAIN SELECT SQL_NO_CACHE * FROM title WHERE startYear = 2019 LIMIT 1000;
```

    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra       |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    |  1 | SIMPLE      | title | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 5713325 |    10.00 | Using where |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+-------------+
    1 row in set, 1 warning (0.00 sec)

Добавление индекса:

``` sql
ALTER TABLE `title` ADD INDEX `startYearIndex` (`startYear` ASC);
```

С индексом по полю startYear:

    +----------+------------+-------------------------------------------------------+
    | Query_ID | Duration   | Query                                                 |
    +----------+------------+-------------------------------------------------------+
    |       14 | 0.00276400 | SELECT * FROM title WHERE startYear = 2019 LIMIT 1000 |
    +----------+------------+-------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec)

    +----+-------------+-------+------------+------+----------------+----------------+---------+-------+--------+----------+-------+
    | id | select_type | table | partitions | type | possible_keys  | key            | key_len | ref   | rows   | filtered | Extra |
    +----+-------------+-------+------------+------+----------------+----------------+---------+-------+--------+----------+-------+
    |  1 | SIMPLE      | title | NULL       | ref  | startYearIndex | startYearIndex | 5       | const | 439292 |   100.00 | NULL  |
    +----+-------------+-------+------------+------+----------------+----------------+---------+-------+--------+----------+-------+
    1 row in set, 1 warning (0.00 sec)

## Index range scan

``` sql
EXPLAIN SELECT SQL_NO_CACHE * FROM title_rating
WHERE averageRating BETWEEN 9 AND 10
```

До добавления индеса по полю averageRating:

    +----+-------------+--------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    | id | select_type | table        | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
    +----+-------------+--------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    |  1 | SIMPLE      | title_rating | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 981120 |    11.11 | Using where |
    +----+-------------+--------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
    1 row in set, 2 warnings (0.00 sec)

``` sql
ALTER TABLE `imdb_full`.`title_rating` 
ADD INDEX `averageRating` (`averageRating` ASC);
```

После добавления индекса по полю averageRating:

    +----+-------------+--------------+------------+-------+---------------+---------------+---------+------+-------+----------+-----------------------+
    | id | select_type | table        | partitions | type  | possible_keys | key           | key_len | ref  | rows  | filtered | Extra                 |
    +----+-------------+--------------+------------+-------+---------------+---------------+---------+------+-------+----------+-----------------------+
    |  1 | SIMPLE      | title_rating | NULL       | range | averageRating | averageRating | 8       | NULL | 72116 |   100.00 | Using index condition |
    +----+-------------+--------------+------------+-------+---------------+---------------+---------+------+-------+----------+-----------------------+
    1 row in set, 2 warnings (0.00 sec)

## Group by

До добавления индекса по полю genre:

``` sql
SELECT SQL_NO_CACHE genre, COUNT(titleID) FROM imdb_full.title_genre GROUP BY genre
```

    +----------+------------+-------------------------------------------------------------------------------------+
    | Query_ID | Duration   | Query                                                                               |
    +----------+------------+-------------------------------------------------------------------------------------+
    |        8 | 5.94673000 | SELECT SQL_NO_CACHE genre, COUNT(titleID) FROM imdb_full.title_genre GROUP BY genre |
    +----------+------------+-------------------------------------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec)

``` sql
EXPLAIN SELECT SQL_NO_CACHE genre, COUNT(titleID) FROM imdb_full.title_genre GROUP BY genre;
```

    +----+-------------+-------------+------------+-------+---------------+---------+---------+------+---------+----------+----------------------------------------------+
    | id | select_type | table       | partitions | type  | possible_keys | key     | key_len | ref  | rows    | filtered | Extra                                        |
    +----+-------------+-------------+------------+-------+---------------+---------+---------+------+---------+----------+----------------------------------------------+
    |  1 | SIMPLE      | title_genre | NULL       | index | PRIMARY       | PRIMARY | 41      | NULL | 9118175 |   100.00 | Using index; Using temporary; Using filesort |
    +----+-------------+-------------+------------+-------+---------------+---------+---------+------+---------+----------+----------------------------------------------+
    1 row in set, 2 warnings (0.00 sec)

``` sql
ALTER TABLE `imdb_full`.`title_genre` ADD INDEX `genreIndex` (`genre` ASC);
```

После добавления индекса по полю genre:

    +----------+------------+-------------------------------------------------------------------------------------+
    | Query_ID | Duration   | Query                                                                               |
    +----------+------------+-------------------------------------------------------------------------------------+
    |        9 | 1.78642400 | SELECT SQL_NO_CACHE genre, COUNT(titleID) FROM imdb_full.title_genre GROUP BY genre |
    +----------+------------+-------------------------------------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec

    +----+-------------+-------------+------------+-------+--------------------+------------+---------+------+---------+----------+-------------+
    | id | select_type | table       | partitions | type  | possible_keys      | key        | key_len | ref  | rows    | filtered | Extra       |
    +----+-------------+-------------+------------+-------+--------------------+------------+---------+------+---------+----------+-------------+
    |  1 | SIMPLE      | title_genre | NULL       | index | PRIMARY,genreIndex | genreIndex | 1       | NULL | 9118175 |   100.00 | Using index |
    +----+-------------+-------------+------------+-------+--------------------+------------+---------+------+---------+----------+-------------+
    1 row in set, 2 warnings (0.00 sec)

## Order by

До добавления индекса по полю numVotes.

``` sql
SELECT SQL_NO_CACHE titleID, numVotes FROM title_rating ORDER BY numVotes DESC LIMIT 1000;
```

    +----------+------------+-------------------------------------------------------------------------------------------+
    | Query_ID | Duration   | Query                                                                                     |
    +----------+------------+-------------------------------------------------------------------------------------------+
    |       21 | 0.30404600 | SELECT SQL_NO_CACHE titleID, numVotes FROM title_rating ORDER BY numVotes DESC LIMIT 1000 |
    +----------+------------+-------------------------------------------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec)

``` sql
EXPLAIN SELECT SQL_NO_CACHE titleID, numVotes FROM title_rating ORDER BY numVotes DESC LIMIT 1000;
```

    +----+-------------+--------------+------------+------+---------------+------+---------+------+--------+----------+----------------+
    | id | select_type | table        | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra          |
    +----+-------------+--------------+------------+------+---------------+------+---------+------+--------+----------+----------------+
    |  1 | SIMPLE      | title_rating | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 981120 |   100.00 | Using filesort |
    +----+-------------+--------------+------------+------+---------------+------+---------+------+--------+----------+----------------+
    1 row in set, 2 warnings (0.00 sec)

``` sql
ALTER TABLE `title_rating` ADD INDEX `numVotesIndex` (`numVotes` ASC);
```

После добавления индекса по полю numVotes.

    +----------+------------+-------------------------------------------------------------------------------------------+
    | Query_ID | Duration   | Query                                                                                     |
    +----------+------------+-------------------------------------------------------------------------------------------+
    |       22 | 0.00075700 | SELECT SQL_NO_CACHE titleID, numVotes FROM title_rating ORDER BY numVotes DESC LIMIT 1000 |
    +----------+------------+-------------------------------------------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec)

    +----+-------------+--------------+------------+-------+---------------+---------------+---------+------+------+----------+-------------+
    | id | select_type | table        | partitions | type  | possible_keys | key           | key_len | ref  | rows | filtered | Extra       |
    +----+-------------+--------------+------------+-------+---------------+---------------+---------+------+------+----------+-------------+
    |  1 | SIMPLE      | title_rating | NULL       | index | NULL          | numVotesIndex | 4       | NULL | 1000 |   100.00 | Using index |
    +----+-------------+--------------+------------+-------+---------------+---------------+---------+------+------+----------+-------------+
    1 row in set, 2 warnings (0.00 sec)

## Join

``` sql
EXPLAIN SELECT * FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
```

    +----+-------------+--------------+------------+--------+---------------+---------+---------+--------------------------------+--------+----------+-------+
    | id | select_type | table        | partitions | type   | possible_keys | key     | key_len | ref                            | rows   | filtered | Extra |
    +----+-------------+--------------+------------+--------+---------------+---------+---------+--------------------------------+--------+----------+-------+
    |  1 | SIMPLE      | title_rating | NULL       | ALL    | PRIMARY       | NULL    | NULL    | NULL                           | 981120 |   100.00 | NULL  |
    |  1 | SIMPLE      | title        | NULL       | eq_ref | PRIMARY       | PRIMARY | 40      | imdb_full.title_rating.titleID |      1 |   100.00 | NULL  |
    +----+-------------+--------------+------------+--------+---------------+---------+---------+--------------------------------+--------+----------+-------+
    2 rows in set, 1 warning (0.00 sec)

## Subqueries

``` sql
EXPLAIN
SELECT * FROM title
WHERE titleID IN (
    SELECT titleID FROM title_genre 
    WHERE title_genre.genre IN ("Comedy", "Action")
    )
```

    +----+-------------+-------------+------------+--------+---------------+---------+---------+-------------------------------+---------+----------+------------------------------------
    | id | select_type | table       | partitions | type   | possible_keys | key     | key_len | ref                           | rows    | filtered | Extra                              
    +----+-------------+-------------+------------+--------+---------------+---------+---------+-------------------------------+---------+----------+------------------------------------
    |  1 | SIMPLE      | title_genre | NULL       | index  | PRIMARY       | PRIMARY | 41      | NULL                          | 9118175 |    12.50 | Using where; Using index; LooseScan
    |  1 | SIMPLE      | title       | NULL       | eq_ref | PRIMARY       | PRIMARY | 40      | imdb_full.title_genre.titleID |       1 |   100.00 | NULL                               
    +----+-------------+-------------+------------+--------+---------------+---------+---------+-------------------------------+---------+----------+------------------------------------
    2 rows in set, 1 warning (0.00 sec)

# Примеры оптимизации запросов

Вывести список людей и количество людей с такой же датой рождения.

``` sql
EXPLAIN
SELECT F.primaryName, COUNT(F.nameID) FROM name F, name S
WHERE F.nameID != S.nameID AND F.birthYear = S.birthYear
GROUP BY F.nameID
```

    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+----------------------------------------------------+
    | id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra                                              |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+----------------------------------------------------+
    |  1 | SIMPLE      | F     | NULL       | ALL  | PRIMARY       | NULL | NULL    | NULL | 9371346 |   100.00 | Using temporary; Using filesort                    |
    |  1 | SIMPLE      | S     | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9371346 |     9.00 | Using where; Using join buffer (Block Nested Loop) |
    +----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+----------------------------------------------------+
    2 rows in set, 1 warning (0.00 sec)

``` sql
ALTER TABLE `name` ADD INDEX `birthYearIndex` (`birthYear` ASC);
```

    +----+-------------+-------+------------+-------+-------------------+-----------+---------+-----------------------+---------+----------+--------------------------+
    | id | select_type | table | partitions | type  | possible_keys     | key       | key_len | ref                   | rows    | filtered | Extra                    |
    +----+-------------+-------+------------+-------+-------------------+-----------+---------+-----------------------+---------+----------+--------------------------+
    |  1 | SIMPLE      | F     | NULL       | index | PRIMARY,birthYear | PRIMARY   | 40      | NULL                  | 9371346 |   100.00 | Using where              |
    |  1 | SIMPLE      | S     | NULL       | ref   | birthYear         | birthYear | 5       | imdb_full.F.birthYear |   65533 |    90.00 | Using where; Using index |
    +----+-------------+-------+------------+-------+-------------------+-----------+---------+-----------------------+---------+----------+--------------------------+
    2 rows in set, 1 warning (0.00 sec)

    +----------+------------+-------------------------------------------------------------------------------------------------------------------------------------------------+
    | Query_ID | Duration   | Query                                                                                                                                           |
    +----------+------------+-------------------------------------------------------------------------------------------------------------------------------------------------+
    |       38 | 2.14287300 | SELECT F.primaryName, COUNT(F.nameID) FROM name F, name S WHERE F.nameID != S.nameID AND F.birthYear = S.birthYear GROUP BY F.nameID LIMIT 1000 |
    +----------+------------+-------------------------------------------------------------------------------------------------------------------------------------------------+
    1 row in set, 1 warning (0.00 sec)

Получить список фильмов отсортированных по рейтингу:

``` sql
EXPLAIN SELECT SQL_NO_CACHE * FROM title
JOIN title_rating ON title.titleID = title_rating.titleID
ORDER BY title_rating.numVotes DESC
LIMIT 1000
```

    +----------+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
    | Query_ID | Duration   | Query                                                                                                                                                      
    +----------+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
    |       43 | 0.57302600 | SELECT title.titleID, title.primaryTitle, numVotes FROM title INNER JOIN title_rating ON title.titleID = title_rating.titleID ORDER BY numVotes DESC LIMIT 
    +----------+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
    1 row in set, 1 warning (0.00 sec)

``` sql
ALTER TABLE `title_rating` ADD INDEX `numVotes` (`numVotes` DESC);
```

``` sql
EXPLAIN SELECT SQL_NO_CACHE * FROM title
JOIN title_rating ON title.titleID = title_rating.titleID
ORDER BY title_rating.numVotes DESC
LIMIT 1000
```

    +----------+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
    | Query_ID | Duration   | Query                                                                                                                                                      
    +----------+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
    |       44 | 0.00314300 | SELECT title.titleID, title.primaryTitle, numVotes FROM title INNER JOIN title_rating ON title.titleID = title_rating.titleID ORDER BY numVotes DESC LIMIT 
    +----------+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
    1 row in set, 1 warning (0.00 sec)

# Используемые источники

1.  https://dev.mysql.com/doc/refman/8.0/en/execution-plan-information.html

2.  https://dev.mysql.com/doc/refman/8.0/en/explain-output.htmlv

3.  https://dev.mysql.com/doc/refman/8.0/en/optimization.html

4.  https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html
