# Постановка задачи

Цели лабораторной работы:

1.  Язык SQL. Операторы Insert. Update. Delete. Условная логика IF,
    CASE.

2.  Язык SQL. Подзапросы. Несвязанные подзапросы. Связанные подзапросы.
    Размерность подзапроса.

# Типы подзапросов

По месту нахождения:

1.  В блоке SELECT

2.  В блоке FROM

3.  В блоке WHERE

По типу связанности с внешним запросом:

1.  Связанные

2.  Несвязанные

# По месту нахождения

## Подзапросы в блоке SELECT

Получить все фильмы и описания их жанров.

``` sql
SELECT primaryTitle, 
       titleType,
       (SELECT GROUP_CONCAT(genre) FROM title_genre inner_title_genre WHERE inner_title_genre.titleID = title.titleID) as genres_description
FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
ORDER BY numVotes DESC, averageRating DESC
LIMIT 10;
```

    +---------------------------------------------------+-----------+-------------------------+
    | primaryTitle                                      | titleType | genres_description      |
    +---------------------------------------------------+-----------+-------------------------+
    | The Shawshank Redemption                          | movie     | Drama                   |
    | The Dark Knight                                   | movie     | Action,Crime,Drama      |
    | Inception                                         | movie     | Action,Adventure,Sci-Fi |
    | Fight Club                                        | movie     | Drama                   |
    | Pulp Fiction                                      | movie     | Crime,Drama             |
    | Forrest Gump                                      | movie     | Drama,Romance           |
    | Game of Thrones                                   | tvSeries  | Action,Adventure,Drama  |
    | The Matrix                                        | movie     | Action,Sci-Fi           |
    | The Lord of the Rings: The Fellowship of the Ring | movie     | Adventure,Drama,Fantasy |
    | The Lord of the Rings: The Return of the King     | movie     | Adventure,Drama,Fantasy |
    +---------------------------------------------------+-----------+-------------------------+
    10 rows in set (0.05 sec)

## Подзапросы в блоке FROM

Получить все фильмы и описания их жанров.

``` sql
SELECT title_genre_details.titleID, primaryTitle, genre_details, numVotes, averageRating
FROM (SELECT titleID, GROUP_CONCAT(genre) as genre_details FROM imdb_db_part.title_genre GROUP BY titleID) title_genre_details
INNER JOIN title ON title_genre_details.titleID  = title.titleID
INNER JOIN title_rating ON title.titleID = title_rating.titleID
ORDER BY numVotes DESC, averageRating DESC
```

    +-----------+---------------------------------------------------+-------------------------+----------+---------------+
    | titleID   | primaryTitle                                      | genre_details           | numVotes | averageRating |
    +-----------+---------------------------------------------------+-------------------------+----------+---------------+
    | tt0111161 | The Shawshank Redemption                          | Drama                   |  2149031 |           9.3 |
    | tt0468569 | The Dark Knight                                   | Action,Crime,Drama      |  2118625 |             9 |
    | tt1375666 | Inception                                         | Action,Adventure,Sci-Fi |  1883746 |           8.8 |
    | tt0137523 | Fight Club                                        | Drama                   |  1716980 |           8.8 |
    | tt0110912 | Pulp Fiction                                      | Crime,Drama             |  1686388 |           8.9 |
    | tt0109830 | Forrest Gump                                      | Drama,Romance           |  1653584 |           8.8 |
    | tt0944947 | Game of Thrones                                   | Action,Adventure,Drama  |  1596735 |           9.4 |
    | tt0133093 | The Matrix                                        | Action,Sci-Fi           |  1546559 |           8.7 |
    | tt0120737 | The Lord of the Rings: The Fellowship of the Ring | Adventure,Drama,Fantasy |  1542044 |           8.8 |
    | tt0167260 | The Lord of the Rings: The Return of the King     | Adventure,Drama,Fantasy |  1526805 |           8.9 |
    +-----------+---------------------------------------------------+-------------------------+----------+---------------+
    10 rows in set (0.44 sec)

## Подзапросы в блоке WHERE

Получить все фильмы у которых только 2 жанра.

``` sql
SELECT title.titleID, primaryTitle, averageRating, numVotes FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
WHERE 2 = (SELECT COUNT(*) FROM title_genre WHERE title.titleID = title_genre.titleID)
ORDER BY numVotes DESC, averageRating DESC
LIMIT 10
```

    +-----------+-----------------------+---------------+----------+
    | titleID   | primaryTitle          | averageRating | numVotes |
    +-----------+-----------------------+---------------+----------+
    | tt0110912 | Pulp Fiction          |           8.9 |  1686388 |
    | tt0109830 | Forrest Gump          |           8.8 |  1653584 |
    | tt0133093 | The Matrix            |           8.7 |  1546559 |
    | tt0068646 | The Godfather         |           9.2 |  1474927 |
    | tt1345836 | The Dark Knight Rises |           8.4 |  1415027 |
    | tt1853728 | Django Unchained      |           8.4 |  1243326 |
    | tt0372784 | Batman Begins         |           8.2 |  1219308 |
    | tt0120815 | Saving Private Ryan   |           8.6 |  1138073 |
    | tt0209144 | Memento               |           8.4 |  1048905 |
    | tt1130884 | Shutter Island        |           8.1 |  1031033 |
    +-----------+-----------------------+---------------+----------+
    10 rows in set (0.05 sec)

Получить все фильмы у которых жанр Comedy или Action.

``` sql
SELECT title.titleID, primaryTitle, averageRating, numVotes FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
WHERE EXISTS (SELECT 1 FROM title_genre WHERE title_genre.genre IN ('Comedy', 'Action') AND title_genre.titleID = title.titleID)
ORDER BY numVotes DESC, averageRating DESC
LIMIT 10
```

    +-----------+------------------------------------------------+---------------+----------+
    | titleID   | primaryTitle                                   | averageRating | numVotes |
    +-----------+------------------------------------------------+---------------+----------+
    | tt0468569 | The Dark Knight                                |             9 |  2118625 |
    | tt1375666 | Inception                                      |           8.8 |  1883746 |
    | tt0944947 | Game of Thrones                                |           9.4 |  1596735 |
    | tt0133093 | The Matrix                                     |           8.7 |  1546559 |
    | tt1345836 | The Dark Knight Rises                          |           8.4 |  1415027 |
    | tt0172495 | Gladiator                                      |           8.5 |  1240337 |
    | tt0372784 | Batman Begins                                  |           8.2 |  1219308 |
    | tt0848228 | The Avengers                                   |             8 |  1203436 |
    | tt0076759 | Star Wars: Episode IV - A New Hope             |           8.6 |  1142460 |
    | tt0080684 | Star Wars: Episode V - The Empire Strikes Back |           8.7 |  1073886 |
    +-----------+------------------------------------------------+---------------+----------+
    10 rows in set (0.05 sec)

# По типу связи с внешним запросов

## Связанные

Получить фильмы для которых нет информации о съемочной группе.

``` sql
SELECT title.titleID, primaryTitle, numVotes, averageRating FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
WHERE NOT EXISTS (
    SELECT 1 FROM title_principals_profession
    WHERE title_principals_profession.titleID = title.titleID
) AND titleType = 'movie'
ORDER BY numVotes DESC, averageRating DESC
LIMIT 5
```

    +-----------+-------------------------------------------+----------+---------------+
    | titleID   | primaryTitle                              | numVotes | averageRating |
    +-----------+-------------------------------------------+----------+---------------+
    | tt5013056 | Dunkirk                                   |   483948 |           7.9 |
    | tt5052448 | Get Out                                   |   424443 |           7.7 |
    | tt5463162 | Deadpool 2                                |   419898 |           7.7 |
    | tt4972582 | Split                                     |   377084 |           7.3 |
    | tt5027774 | Three Billboards Outside Ebbing, Missouri |   363790 |           8.2 |
    +-----------+-------------------------------------------+----------+---------------+
    5 rows in set (0.19 sec)

## Несвязанные

Получить фильмы для которых нет информации о съемочной группе.

``` sql
SELECT title.titleID, primaryTitle, numVotes, averageRating FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
WHERE title.titleID NOT IN (SELECT titleID FROM title_principals_profession) AND titleType = 'movie'
ORDER BY numVotes DESC, averageRating DESC
LIMIT 5
```

    +-----------+-------------------------------------------+----------+---------------+
    | titleID   | primaryTitle                              | numVotes | averageRating |
    +-----------+-------------------------------------------+----------+---------------+
    | tt5013056 | Dunkirk                                   |   483948 |           7.9 |
    | tt5052448 | Get Out                                   |   424443 |           7.7 |
    | tt5463162 | Deadpool 2                                |   419898 |           7.7 |
    | tt4972582 | Split                                     |   377084 |           7.3 |
    | tt5027774 | Three Billboards Outside Ebbing, Missouri |   363790 |           8.2 |
    +-----------+-------------------------------------------+----------+---------------+
    5 rows in set (0.18 sec)

# Примеры запросов

Получить деятелей киноиндустрии отсортированных по количеству фильмов в
которых они принимали участия и которые находятся в топ 100000 по
рейтингу.

``` sql
SELECT nameID, primaryName, (
    SELECT COUNT(*) FROM title_principals_profession
    INNER JOIN (SELECT titleID FROM title_rating ORDER BY numVotes DESC, averageRating DESC LIMIT 10000) as title_rating_ordered
    ON title_principals_profession.titleID = title_rating_ordered.titleID
    WHERE title_principals_profession.nameID = name.nameID
) as count_of_films
FROM name
ORDER BY count_of_films DESC
LIMIT 10
```

``` 
+-----------+---------------------+----------------+
| nameID    | primaryName         | count_of_films |
+-----------+---------------------+----------------+
| nm0186505 | Bryan Cranston      |             75 |
| nm0000134 | Robert De Niro      |             74 |
| nm0666739 | Aaron Paul          |             71 |
| nm0319213 | Vince Gilligan      |             68 |
| nm1125275 | David Benioff       |             68 |
| nm0606487 | Dean Norris         |             67 |
| nm0000025 | Jerry Goldsmith     |             65 |
| nm0348152 | Anna Gunn           |             63 |
| nm0006133 | James Newton Howard |             61 |
| nm0748784 | Scott Rudin         |             61 |
+-----------+---------------------+----------------+
10 rows in set (11.71 sec)    
```

Получить сериалы и отсортированные по количеству серий.

``` sql
SELECT title.titleID, primaryTitle, (
                SELECT COUNT(*) FROM title_episode
                WHERE parentTitleID = title.titleID
                ) as episode_count
FROM title
INNER JOIN title_rating ON title.titleID = title_rating.titleID
WHERE titleType = 'tvSeries'
ORDER BY numVotes DESC, averageRating DESC
LIMIT 10
```

    +-----------+-----------------------+---------------+
    | titleID   | primaryTitle          | episode_count |
    +-----------+-----------------------+---------------+
    | tt0944947 | Game of Thrones       |            73 |
    | tt0903747 | Breaking Bad          |            62 |
    | tt1520211 | The Walking Dead      |           133 |
    | tt1475582 | Sherlock              |            15 |
    | tt0108778 | Friends               |           236 |
    | tt4574334 | Stranger Things       |            25 |
    | tt0898266 | The Big Bang Theory   |           280 |
    | tt0773262 | Dexter                |            96 |
    | tt0460649 | How I Met Your Mother |           208 |
    | tt0411008 | Lost                  |           118 |
    +-----------+-----------------------+---------------+
    10 rows in set (0.16 sec)

Аналог с использованием JOIN.

``` sql
SELECT title.titleID, primaryTitle, COUNT(*) as episode_count FROM title
INNER JOIN title_episode ON title.titleID = title_episode.parentTitleID
INNER JOIN title_rating ON title.titleID = title_rating.titleID
GROUP BY titleID
ORDER BY numVotes DESC, averageRating DESC
LIMIT 10
```

    +-----------+-----------------------+---------------+
    | titleID   | primaryTitle          | episode_count |
    +-----------+-----------------------+---------------+
    | tt0944947 | Game of Thrones       |            73 |
    | tt0903747 | Breaking Bad          |            62 |
    | tt1520211 | The Walking Dead      |           133 |
    | tt1475582 | Sherlock              |            15 |
    | tt0108778 | Friends               |           236 |
    | tt4574334 | Stranger Things       |            25 |
    | tt0898266 | The Big Bang Theory   |           280 |
    | tt0773262 | Dexter                |            96 |
    | tt0460649 | How I Met Your Mother |           208 |
    | tt0411008 | Lost                  |           118 |
    +-----------+-----------------------+---------------+
    10 rows in set (0.16 sec)

# Используемые источники

1.  https://dev.mysql.com/doc/refman/8.0/en/select.html

2.  https://dev.mysql.com/doc/refman/8.0/en/select-into.html

3.  https://dev.mysql.com/doc/refman/8.0/en/join.html

4.  https://dev.mysql.com/doc/refman/8.0/en/union.html

5.  https://dev.mysql.com/doc/refman/8.0/en/subqueries.html
