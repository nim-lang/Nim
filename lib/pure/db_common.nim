#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Common datatypes and definitions for all `db_*.nim` (
## `db_mysql <db_mysql.html>`_, `db_postgres <db_postgres.html>`_,
## and `db_sqlite <db_sqlite.html>`_) modules.

type
  DbError* = object of IOError ## exception that is raised if a database error occurs

  SqlQuery* = distinct string ## an SQL query string


  DbEffect* = object of IOEffect ## effect that denotes a database operation
  ReadDbEffect* = object of DbEffect ## effect that denotes a read operation
  WriteDbEffect* = object of DbEffect ## effect that denotes a write operation

  DbTypeKind* = enum ## a superset of datatypes that might be supported.
    dbUnknown,       ## unknown datatype
    dbSerial,        ## datatype used for primary auto-increment keys
    dbNull,          ## datatype used for the NULL value
    dbBit,           ## bit datatype
    dbBool,          ## boolean datatype
    dbBlob,          ## blob datatype
    dbFixedChar,     ## string of fixed length
    dbVarchar,       ## string datatype
    dbJson,          ## JSON datatype
    dbXml,           ## XML datatype
    dbInt,           ## some integer type
    dbUInt,          ## some unsigned integer type
    dbDecimal,       ## decimal numbers (fixed-point number)
    dbFloat,         ## some floating point type
    dbDate,          ## a year-month-day description
    dbTime,          ## HH:MM:SS information
    dbDatetime,      ## year-month-day and HH:MM:SS information,
                     ## plus optional time or timezone information
    dbTimestamp,     ## Timestamp values are stored as the number of seconds
                     ## since the epoch ('1970-01-01 00:00:00' UTC).
    dbTimeInterval,  ## an interval [a,b] of times
    dbEnum,          ## some enum
    dbSet,           ## set of enum values
    dbArray,         ## an array of values
    dbComposite,     ## composite type (record, struct, etc)
    dbUrl,           ## a URL
    dbUuid,          ## a UUID
    dbInet,          ## an IP address
    dbMacAddress,    ## a MAC address
    dbGeometry,      ## some geometric type
    dbPoint,         ## Point on a plane   (x,y)
    dbLine,          ## Infinite line ((x1,y1),(x2,y2))
    dbLseg,          ## Finite line segment   ((x1,y1),(x2,y2))
    dbBox,           ## Rectangular box   ((x1,y1),(x2,y2))
    dbPath,          ## Closed or open path (similar to polygon) ((x1,y1),...)
    dbPolygon,       ## Polygon (similar to closed path)   ((x1,y1),...)
    dbCircle,        ## Circle   <(x,y),r> (center point and radius)
    dbUser1,         ## user definable datatype 1 (for unknown extensions)
    dbUser2,         ## user definable datatype 2 (for unknown extensions)
    dbUser3,         ## user definable datatype 3 (for unknown extensions)
    dbUser4,         ## user definable datatype 4 (for unknown extensions)
    dbUser5          ## user definable datatype 5 (for unknown extensions)

  DbType* = object              ## describes a database type
    kind*: DbTypeKind           ## the kind of the described type
    notNull*: bool              ## does the type contain NULL?
    name*: string               ## the name of the type
    size*: Natural              ## the size of the datatype; 0 if of variable size
    maxReprLen*: Natural        ## maximal length required for the representation
    precision*, scale*: Natural ## precision and scale of the number
    min*, max*: BiggestInt      ## the minimum and maximum of allowed values
    validValues*: seq[string]   ## valid values of an enum or a set

  DbColumn* = object   ## information about a database column
    name*: string      ## name of the column
    tableName*: string ## name of the table the column belongs to (optional)
    typ*: DbType       ## type of the column
    primaryKey*: bool  ## is this a primary key?
    foreignKey*: bool  ## is this a foreign key?
  DbColumns* = seq[DbColumn]

template sql*(query: string): SqlQuery =
  ## constructs a SqlQuery from the string `query`. This is supposed to be
  ## used as a raw-string-literal modifier:
  ## `sql"update user set counter = counter + 1"`
  ##
  ## If assertions are turned off, it does nothing. If assertions are turned
  ## on, later versions will check the string for valid syntax.
  SqlQuery(query)

proc dbError*(msg: string) {.noreturn, noinline.} =
  ## raises an DbError exception with message `msg`.
  var e: ref DbError
  new(e)
  e.msg = msg
  raise e
