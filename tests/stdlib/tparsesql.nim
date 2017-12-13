discard """
  file: "tparsesql.nim"
  output: '''select
  foo
from
  table;
select
  foo
from
  table;
select
  foo
from
  table
limit
  10;
select
  foo,
  bar,
  baz
from
  table
limit
  10;
select
  foo as bar
from
  table;
select
  foo as foo_prime,
  bar as bar_prime,
  baz as baz_prime
from
  table;
select
  *
from
  table;
select
  *
from
  table
where
  ((a = b) and (c = d));
select
  *
from
  table
where
  (not b);
select
  *
from
  table
where
  (a and (not b));
select
  *
from
  table
where
  (((a = b) and (c = d)) or ((n is null) and (((not b) + 1) = 3)));
select
  *
from
  table
having
  ((a = b) and (c = d));
select
  a,
  b
from
  table
group by
  a;
select
  a,
  b
from
  table
group by
  1, 2;
select
  t.a
from
  t as t;
select
  a,
  b
from
  (
    select
      *
    from
      t
  );
select
  a,
  b
from
  (
    select
      *
    from
      t
  ) as foo;
select
  a,
  b
from
  (
    select
      *
    from
      (
        select
          *
        from
          (
            select
              *
            from
              (
                select
                  *
                from
                  inner as inner1
              ) as inner2
          ) as inner3
      ) as inner4
  ) as inner5;
select
  a,
  b
from
  (
    select
      *
    from
      a
  ), (
    select
      *
    from
      b
  ), (
    select
      *
    from
      c
  );
select
  *
from
  Products
where
  (Price BETWEEN (10 AND 20));
select
  id
from
  a
join
  b
on
  (a.id == b.id);
select
  id
from
  a
join
  (
    select
      id
    from
      c
  ) as b
on
  (a.id == b.id);
select
  id
from
  a
INNER join
  b
on
  (a.id == b.id);
select
  id
from
  a
OUTER join
  b
on
  (a.id == b.id);
select
  id
from
  a
CROSS join
  b
on
  (a.id == b.id);
create type happiness as enum ('happy', 'very happy', 'ecstatic');
create table holidays(
  num_weeks int,
  happiness happiness);
create index table1_attr1 on table1(attr1);
select
  *
from
  myTab
where
  (col1 = 'happy');

insert into Customers (CustomerName, ContactName, Address, City, PostalCode, Country)
values ('Cardinal', 'Tom B. Erichsen', 'Skagen 21', 'Stavanger', '4006', 'Norway');
insert into TableName default values;

update
  Customers
set
  ContactName = 'Alfred Schmidt', City = 'Frankfurt'
where
  (CustomerID = 1);
delete from table_name;
delete from table_name;
select
  *
from
  Customers;
select
  *
from
  Customers
where
  ((((CustomerName LIKE 'L%') OR (CustomerName LIKE 'R%')) OR (CustomerName LIKE 'W%')) AND (Country = 'USA'))
order by
  CustomerName;

'''
"""

import parsesql

echo $parseSQL "SELECT foo FROM table;"
echo $parseSQL "SELECT foo FROM table"
echo $parseSQL "SELECT foo FROM table limit 10"
echo $parseSQL "SELECT foo, bar, baz FROM table limit 10"
echo $parseSQL "SELECT foo AS bar FROM table"
echo $parseSQL "SELECT foo AS foo_prime, bar AS bar_prime, baz AS baz_prime FROM table"
echo $parseSQL "SELECT * FROM table"
#TODO add count(*)
#echo $parseSQL "SELECT COUNT(*) FROM table"
echo $parseSQL """
SELECT * FROM table
WHERE a = b and c = d
"""
echo $parseSQL """
SELECT * FROM table
WHERE not b
"""
echo $parseSQL """
SELECT
  *
FROM
  table
WHERE
  a and not b
"""
echo $parseSQL """
SELECT * FROM table
WHERE a = b and c = d or n is null and not b + 1 = 3
"""
echo $parseSQL """
SELECT * FROM table
HAVING a = b and c = d
"""
echo $parseSQL """
SELECT a, b FROM table
GROUP BY a
"""
echo $parseSQL """
SELECT a, b FROM table
GROUP BY 1, 2
"""
echo $parseSQL "SELECT t.a FROM t as t"
echo $parseSQL """
SELECT a, b FROM (
  SELECT * FROM t
)
"""
echo $parseSQL """
SELECT a, b FROM (
  SELECT * FROM t
) as foo
"""
echo $parseSQL """
SELECT a, b FROM (
  SELECT * FROM (
    SELECT * FROM (
      SELECT * FROM (
        SELECT * FROM inner as inner1
      ) as inner2
    ) as inner3
  ) as inner4
) as inner5
"""
echo $parseSQL """
SELECT a, b FROM
  (SELECT * FROM a),
  (SELECT * FROM b),
  (SELECT * FROM c)
"""
echo $parseSQL """
SELECT * FROM Products
WHERE Price BETWEEN 10 AND 20;
"""
echo $parseSQL """
SELECT id FROM a
JOIN b
ON a.id == b.id
"""
echo $parseSQL """
SELECT id FROM a
JOIN (SELECT id from c) as b
ON a.id == b.id
"""
echo $parseSQL """
SELECT id FROM a
INNER JOIN b
ON a.id == b.id
"""
echo $parseSQL """
SELECT id FROM a
OUTER JOIN b
ON a.id == b.id
"""
echo $parseSQL """
SELECT id FROM a
CROSS JOIN b
ON a.id == b.id
"""
echo $parseSQL """
CREATE TYPE happiness AS ENUM ('happy', 'very happy', 'ecstatic');
CREATE TABLE holidays (
  num_weeks int,
  happiness happiness
);
CREATE INDEX table1_attr1 ON table1(attr1);
SELECT * FROM myTab WHERE col1 = 'happy';
"""
echo $parseSQL """
INSERT INTO Customers (CustomerName, ContactName, Address, City, PostalCode, Country)
VALUES ('Cardinal', 'Tom B. Erichsen', 'Skagen 21', 'Stavanger', '4006', 'Norway');
"""
echo $parseSQL """
INSERT INTO TableName DEFAULT VALUES
"""
echo $parseSQL """
UPDATE Customers
SET ContactName = 'Alfred Schmidt', City= 'Frankfurt'
WHERE CustomerID = 1;
"""
echo $parseSQL "DELETE FROM table_name;"
echo $parseSQL "DELETE * FROM table_name;"
echo $parseSQL """
--Select all:
SELECT * FROM Customers;
"""
echo $parseSQL """
SELECT * FROM Customers WHERE (CustomerName LIKE 'L%'
OR CustomerName LIKE 'R%' /*OR CustomerName LIKE 'S%'
OR CustomerName LIKE 'T%'*/ OR CustomerName LIKE 'W%')
AND Country='USA'
ORDER BY CustomerName;
"""
