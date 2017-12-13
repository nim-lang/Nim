import unittest

import sequtils
import strutils
import parsesql

proc fold(str: string): string =
  var
    lines = str.split("\L")
    minCount = 1000
  while lines.len > 0 and lines[0].strip().len == 0:
    lines.delete(0, 0)
  while lines.len > 0 and lines[lines.len-1].strip().len == 0:
    lines.delete(lines.len, lines.len)
  for line in lines:
    var count = 0
    while line[count] == ' ':
      inc count
    if minCount > count:
      minCount = count
  for i, line in lines:
    lines[i] = line[minCount..^1]
  return lines.join("\L")

proc parseCheck(have: string, need: string) =
  var
    sql = parseSQL(have)
    sqlHave = renderSQL(sql, true).strip()
    sqlNeed = need.fold().strip()
  var
    haveLines = sqlHave.split("\L")
    needLines = sqlNeed.split("\L")
  for i in 0..<haveLines.len:
    if haveLines[i] != needLines[i]:
      echo ""
      echo " --- have --- "
      echo sqlHave
      #echo repr(sql)
      echo " --- need --- "
      echo sqlNeed
      echo " --- lines --- "
      echo repr haveLines[i]
      echo repr needLines[i]
      echo "line: ", i
      raise newException(Exception, "Two don't equal.")


suite "sql":

  test "basic":
    parseCheck "SELECT foo FROM table;", """
      SELECT
        foo
      FROM
        table;
    """

  test "dont require ; at the end":
    parseCheck "SELECT foo FROM table", """
      SELECT
        foo
      FROM
        table;
    """

  test "limit":
    parseCheck "SELECT foo FROM table limit 10", """
      SELECT
        foo
      FROM
        table
      LIMIT
        10;
    """

  test "fields":
    parseCheck "SELECT foo, bar, baz FROM table limit 10", """
      SELECT
        foo,
        bar,
        baz
      FROM
        table
      LIMIT
        10;
    """

  test "as_field":
    parseCheck "SELECT foo AS bar FROM table", """
      SELECT
        foo AS bar
      FROM
        table;
    """

    parseCheck "SELECT foo AS foo_prime, bar AS bar_prime, baz AS baz_prime FROM table", """
      SELECT
        foo AS foo_prime,
        bar AS bar_prime,
        baz AS baz_prime
      FROM
        table;
    """

  test "select *":
    parseCheck "SELECT * FROM table", """
      SELECT
        *
      FROM
        table;
    """
    # TODO: COUNT(*)
    #parseCheck "SELECT COUNT(*) FROM table", """
    #  SELECT *
    #  FROM table;
    #"""

  test "where":
    parseCheck """
      SELECT * FROM table
      WHERE a = b and c = d
    """, """
      SELECT
        *
      FROM
        table
      WHERE
        ((a = b) and (c = d));
    """

    parseCheck """
      SELECT * FROM table
      WHERE not b
    """, """
      SELECT
        *
      FROM
        table
      WHERE
        (not b);
    """

    parseCheck """
      SELECT
        *
      FROM
        table
      WHERE
        a and not b
    """, """
      SELECT
        *
      FROM
        table
      WHERE
        (a and (not b));
    """

    parseCheck """
      SELECT *
      FROM table
      WHERE not a and not b
    """, """
      SELECT
        *
      FROM
        table
      WHERE
        ((not a) and (not b));
    """

    parseCheck """
      SELECT * FROM table
      WHERE a = b and c = d or n is null and not b + 1 = 3
    """, """
      SELECT
        *
      FROM
        table
      WHERE
        (((a = b) and (c = d)) or ((n is null) and (((not b) + 1) = 3)));
    """

  test "having":
    parseCheck """
      SELECT * FROM table
      HAVING a = b and c = d
    """, """
      SELECT
        *
      FROM
        table
      HAVING
        ((a = b) and (c = d));
    """

  test "group by":
    parseCheck """
      SELECT a, b FROM table
      GROUP BY a
    """, """
      SELECT
        a,
        b
      FROM
        table
      GROUP BY
        a;
    """

    parseCheck """
      SELECT a, b FROM table
      GROUP BY 1, 2
    """, """
      SELECT
        a,
        b
      FROM
        table
      GROUP BY
        1, 2;
    """

  test "as table":
    parseCheck """
      SELECT t.a FROM t as t
    """, """
      SELECT
        t.a
      FROM
        t AS t;
    """

  test "subselects":
    parseCheck """
      SELECT a, b FROM (
        SELECT * FROM t
      )
    """, """
      SELECT
        a,
        b
      FROM
        (
          SELECT
            *
          FROM
            t
        );
    """

    parseCheck """
      SELECT a, b FROM (
        SELECT * FROM t
      ) as foo
    """, """
      SELECT
        a,
        b
      FROM
        (
          SELECT
            *
          FROM
            t
        ) AS foo;
    """

    parseCheck """
      SELECT a, b FROM (
        SELECT * FROM (
          SELECT * FROM (
            SELECT * FROM (
              SELECT * FROM inner as inner1
            ) as inner2
          ) as inner3
        ) as inner4
      ) as inner5
    """, """
      SELECT
        a,
        b
      FROM
        (
          SELECT
            *
          FROM
            (
              SELECT
                *
              FROM
                (
                  SELECT
                    *
                  FROM
                    (
                      SELECT
                        *
                      FROM
                        inner AS inner1
                    ) AS inner2
                ) AS inner3
            ) AS inner4
        ) AS inner5;
    """

    parseCheck """
      SELECT a, b FROM
        (SELECT * FROM a),
        (SELECT * FROM b),
        (SELECT * FROM c)
    ""","""
      SELECT
        a,
        b
      FROM
        (
          SELECT
            *
          FROM
            a
        ), (
          SELECT
            *
          FROM
            b
        ), (
          SELECT
            *
          FROM
            c
        );
    """

  test "original test":
    parseCheck """
      CREATE TYPE happiness AS ENUM ('happy', 'very happy', 'ecstatic');
      CREATE TABLE holidays (
         num_weeks int,
         happiness happiness
      );
      CREATE INDEX table1_attr1 ON table1(attr1);

      SELECT * FROM myTab WHERE col1 = 'happy';
    """, """
      CREATE TYPE happiness AS ENUM ('happy', 'very happy', 'ecstatic');
      CREATE TABLE holidays(
        num_weeks int,
        happiness happiness);
      CREATE INDEX table1_attr1 ON table1(attr1);
      SELECT
        *
      FROM
        myTab
      WHERE
        (col1 = 'happy');
    """

  test "joins":
    parseCheck """
      SELECT id FROM a
      JOIN b
      ON a.id == b.id
    """, """
      SELECT
        id
      FROM
        a
      JOIN
        b
      ON
        (a.id == b.id);
    """

    parseCheck """
      SELECT id FROM a
      JOIN (SELECT id from c) as b
      ON a.id == b.id
    """, """
      SELECT
        id
      FROM
        a
      JOIN
        (
          SELECT
            id
          FROM
            c
        ) AS b
      ON
        (a.id == b.id);
    """

    parseCheck """
      SELECT id FROM a
      INNER JOIN b
      ON a.id == b.id
    """, """
      SELECT
        id
      FROM
        a
      INNER JOIN
        b
      ON
        (a.id == b.id);
    """

    parseCheck """
      SELECT id FROM a
      OUTER JOIN b
      ON a.id == b.id
    """, """
      SELECT
        id
      FROM
        a
      OUTER JOIN
        b
      ON
        (a.id == b.id);
    """

    parseCheck """
      SELECT id FROM a
      CROSS JOIN b
      ON a.id == b.id
    """, """
      SELECT
        id
      FROM
        a
      CROSS JOIN
        b
      ON
        (a.id == b.id);
    """
