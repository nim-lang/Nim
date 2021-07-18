discard """
  targets: "c js"
"""
import parsesql, unittest

resetOutputFormatters()
addOutputFormatter(newConsoleOutputFormatter(OutputLevel.PRINT_FAILURES))

suite "select":
  test "select single":
    check $parseSQL("SELECT foo FROM table;") == "select foo from table;"
  test "select mutiple":
    check $parseSQL("""
    SELECT
      CustomerName,
      ContactName,
      Address,
      City,
      PostalCode,
      Country,
      CustomerName,
      ContactName,
      Address,
      City,
      PostalCode,
      Country
    FROM table;""") == "select CustomerName, ContactName, Address, City, PostalCode, Country, CustomerName, ContactName, Address, City, PostalCode, Country from table;"
  test "select with limit":
    check $parseSQL("SELECT foo FROM table limit 10") == "select foo from table limit 10;"
  test "select multiple with limit":
    check $parseSQL("SELECT foo, bar, baz FROM table limit 10") == "select foo, bar, baz from table limit 10;"
  test "select as":
    check $parseSQL("SELECT foo AS bar FROM table") == "select foo as bar from table;"
  test "select multiple as":
    check $parseSQL("SELECT foo AS foo_prime, bar AS bar_prime, baz AS baz_prime FROM table") == "select foo as foo_prime, bar as bar_prime, baz as baz_prime from table;"
  test "select *":
    check $parseSQL("SELECT * FROM table") == "select * from table;"
  test "select count(*)":
    check $parseSQL("SELECT count(*) FROM table") == "select count(*) from table;"
  test "select count(*) as":
    check $parseSQL("SELECT count(*) as 'Total' FROM table") == "select count(*) as 'Total' from table;"
  test "select count(*),sum(a) as":
    check $parseSQL("SELECT count(*) as 'Total', sum(a) as 'Aggr' FROM table") == "select count(*) as 'Total', sum(a) as 'Aggr' from table;"
  test "select where":
    check $parseSQL("""
    SELECT * FROM table
    WHERE a = b and c = d
    """) == "select * from table where a = b and c = d;"
  test "where not":
    check $parseSQL("""
    SELECT * FROM table
    WHERE not b
    """) == "select * from table where not b;"
  test "where not":
    check $parseSQL("""
    SELECT
      *
    FROM
      table
    WHERE
      a and not b
    """) == "select * from table where a and not b;"
  test "order by":
    check $parseSQL("""
    SELECT * FROM table
    ORDER BY 1
    """) == "select * from table order by 1;"
  test "group by":
    check $parseSQL("""
    SELECT * FROM table
    GROUP BY 1
    ORDER BY 1
    """) == "select * from table group by 1 order by 1;"
  test "order by limit":
    check $parseSQL("""
    SELECT * FROM table
    ORDER BY 1
    LIMIT 100
    """) == "select * from table order by 1 limit 100;"
  test "complex":
    check $parseSQL("""
    SELECT * FROM table
    WHERE a = b and c = d or n is null and not b + 1 = 3
    """) == "select * from table where a = b and c = d or n is null and not b + 1 = 3;"
  test "complex2":
    check $parseSQL("""
    SELECT * FROM table
    WHERE (a = b and c = d) or (n is null and not b + 1 = 3)
    """) == "select * from table where(a = b and c = d) or (n is null and not b + 1 = 3);"
  test "having":
    check $parseSQL("""
    SELECT * FROM table
    HAVING a = b and c = d
    """) == "select * from table having a = b and c = d;"

  test "group by a":
    check $parseSQL("""
    SELECT a, b FROM table
    GROUP BY a
    """) == "select a, b from table group by a;"
  test "group by 1,2":
    check $parseSQL("""
    SELECT a, b FROM table
    GROUP BY 1, 2
    """) == "select a, b from table group by 1, 2;"
  test "select t.a":
    check $parseSQL("SELECT t.a FROM t as t") == "select t.a from t as t;"
  test "nest select":
    check $parseSQL("""
    SELECT a, b FROM (
      SELECT * FROM t
    )
    """) == "select a, b from(select * from t);"
  test "nest select as":
    check $parseSQL("""
    SELECT a, b FROM (
      SELECT * FROM t
    ) as foo
    """) == "select a, b from(select * from t) as foo;"
  test "nest select inner":
    check $parseSQL("""
    SELECT a, b FROM (
      SELECT * FROM (
        SELECT * FROM (
          SELECT * FROM (
            SELECT * FROM innerTable as inner1
          ) as inner2
        ) as inner3
      ) as inner4
    ) as inner5
    """) == "select a, b from(select * from(select * from(select * from(select * from innerTable as inner1) as inner2) as inner3) as inner4) as inner5;"
  test "sub select":
    check $parseSQL("""
    SELECT a, b FROM
      (SELECT * FROM a),
      (SELECT * FROM b),
      (SELECT * FROM c)
    """) == "select a, b from(select * from a),(select * from b),(select * from c);"
  test "between and":
    check $parseSQL("""
    SELECT * FROM Products
    WHERE Price BETWEEN 10 AND 20;
    """) == "select * from Products where Price between 10 and 20;"
  test "join on":
    check $parseSQL("""
    SELECT id FROM a
    JOIN b
    ON a.id == b.id
    """) == "select id from a join b on a.id == b.id;"
  test "sub select with join on":
    check $parseSQL("""
    SELECT id FROM a
    JOIN (SELECT id from c) as b
    ON a.id == b.id
    """) == "select id from a join(select id from c) as b on a.id == b.id;"
  test "inner join on":
    check $parseSQL("""
    SELECT id FROM a
    INNER JOIN b
    ON a.id == b.id
    """) == "select id from a inner join b on a.id == b.id;"
  test "outer join on":
    check $parseSQL("""
    SELECT id FROM a
    OUTER JOIN b
    ON a.id == b.id
    """) == "select id from a outer join b on a.id == b.id;"
  test "cross join":
    check $parseSQL("""
    SELECT id FROM a
    CROSS JOIN b
    ON a.id == b.id
    """) == "select id from a cross join b on a.id == b.id;"
  test "where string":
    check $parseSQL("SELECT * FROM myTab WHERE col1 = 'happy';") == "select * from myTab where col1 = 'happy';"

suite "create":
  test "type":
    check $parseSQL("CREATE TYPE happiness AS ENUM ('happy', 'very happy', 'ecstatic');") == "create type happiness as enum ('happy' , 'very happy' , 'ecstatic' );"
  
  test "int and unkown data type":
    check $parseSQL("""CREATE TABLE holidays (
        num_weeks int,
        happiness happiness
      );""") == "create table holidays(num_weeks  int , happiness  happiness );"
  test "index":
    check $parseSQL("CREATE INDEX table1_attr1 ON table1(attr1);") == "create index table1_attr1 on table1(attr1 );"

suite "insert":
  test "values":
    check $parseSQL("""
    INSERT INTO Customers (CustomerName, ContactName, Address, City, PostalCode, Country)
    VALUES ('Cardinal', 'Tom B. Erichsen', 'Skagen 21', 'Stavanger', '4006', 'Norway');
    """) == "insert into Customers (CustomerName , ContactName , Address , City , PostalCode , Country ) values ('Cardinal' , 'Tom B. Erichsen' , 'Skagen 21' , 'Stavanger' , '4006' , 'Norway' );"
  test "default":
    check $parseSQL("""
    INSERT INTO TableName DEFAULT VALUES
    """) == "insert into TableName default values;"

suite "update":
  test "update set where":
    check $parseSQL("""
    UPDATE Customers
    SET ContactName = 'Alfred Schmidt', City= 'Frankfurt'
    WHERE CustomerID = 1;
    """) == "update Customers set ContactName  = 'Alfred Schmidt' , City  = 'Frankfurt' where CustomerID = 1;"

suite "delete":
  test "delete from":
    check $parseSQL("DELETE FROM table_name;") == "delete from table_name;"
  test "delete * from":
    check $parseSQL("DELETE * FROM table_name;") == "delete from table_name;"

test "comment start":
  check $parseSQL("""
  --Select all:
  SELECT * FROM Customers;
  """) == "select * from Customers;"

test "select like":
  check $parseSQL("""
  SELECT * FROM Customers WHERE (CustomerName LIKE 'L%'
  OR CustomerName LIKE 'R%' /*OR CustomerName LIKE 'S%'
  OR CustomerName LIKE 'T%'*/ OR CustomerName LIKE 'W%')
  AND Country='USA'
  ORDER BY CustomerName;
  """) == "select * from Customers where(CustomerName like 'L%' or CustomerName like 'R%' or CustomerName like 'W%') and Country = 'USA' order by CustomerName;"

test "parse quoted keywords as identifires":
  check $parseSQL("""
  SELECT `SELECT`, `FROM` as `GROUP` FROM `WHERE`;
  """) == """select "SELECT", "FROM" as "GROUP" from "WHERE";"""
  check $parseSQL("""
  SELECT "SELECT", "FROM" as "GROUP" FROM "WHERE";
  """) == """select "SELECT", "FROM" as "GROUP" from "WHERE";"""
