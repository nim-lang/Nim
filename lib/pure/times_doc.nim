##[
The ``times`` module contains routines and types for dealing with time using
the `proleptic Gregorian calendar<https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar>`_.
It's also available for the
`JavaScript target <backends.html#backends-the-javascript-target>`_.

Although the ``times`` module support nanosecond time resolution, the
resolution used by ``getTime()`` depends on the platform and backend
(JS is limited to millisecond precision).

Examples:

.. code-block:: nim
  import times, os
  # Simple benchmarking
  let time = cpuTime()
  sleep(100)   # Replace this with something to be timed
  echo "Time taken: ", cpuTime() - time

  # Current date & time
  let now1 = now()     # Current timestamp as a DateTime in local time
  let now2 = now().utc # Current timestamp as a DateTime in UTC
  let now3 = getTime() # Current timestamp as a Time

  # Arithmetic using Duration
  echo "One hour from now      : ", now() + initDuration(hours = 1)
  # Arithmetic using TimeInterval
  echo "One year from now      : ", now() + 1.years
  echo "One month from now     : ", now() + 1.months

Parsing and Formatting Dates
----------------------------

The ``DateTime`` type can be parsed and formatted using the different
``parse`` and ``format`` procedures.

.. code-block:: nim

  let dt = parse("2000-01-01", "yyyy-MM-dd")
  echo dt.format("yyyy-MM-dd")

The different format patterns that are supported are documented below.

=============  =================================================================================  ================================================
Pattern        Description                                                                        Example
=============  =================================================================================  ================================================
``d``          Numeric value representing the day of the month,                                   | ``1/04/2012 -> 1``
                it will be either one or two digits long.                                          | ``21/04/2012 -> 21``
``dd``         Same as above, but is always two digits.                                           | ``1/04/2012 -> 01``
                                                                                                  | ``21/04/2012 -> 21``
``ddd``        Three letter string which indicates the day of the week.                           | ``Saturday -> Sat``
                                                                                                  | ``Monday -> Mon``
``dddd``       Full string for the day of the week.                                               | ``Saturday -> Saturday``
                                                                                                  | ``Monday -> Monday``
``h``          The hours in one digit if possible. Ranging from 1-12.                             | ``5pm -> 5``
                                                                                                  | ``2am -> 2``
``hh``         The hours in two digits always. If the hour is one digit 0 is prepended.           | ``5pm -> 05``
                                                                                                  | ``11am -> 11``
``H``          The hours in one digit if possible, ranging from 0-23.                             | ``5pm -> 17``
                                                                                                  | ``2am -> 2``
``HH``         The hours in two digits always. 0 is prepended if the hour is one digit.           | ``5pm -> 17``
                                                                                                  | ``2am -> 02``
``m``          The minutes in 1 digit if possible.                                                | ``5:30 -> 30``
                                                                                                  | ``2:01 -> 1``
``mm``         Same as above but always 2 digits, 0 is prepended if the minute is one digit.      | ``5:30 -> 30``
                                                                                                  | ``2:01 -> 01``
``M``          The month in one digit if possible.                                                | ``September -> 9``
                                                                                                  | ``December -> 12``
``MM``         The month in two digits always. 0 is prepended.                                    | ``September -> 09``
                                                                                                  | ``December -> 12``
``MMM``        Abbreviated three-letter form of the month.                                        | ``September -> Sep``
                                                                                                  | ``December -> Dec``
``MMMM``       Full month string, properly capitalized.                                           | ``September -> September``
``s``          Seconds as one digit if possible.                                                  | ``00:00:06 -> 6``
``ss``         Same as above but always two digits. 0 is prepended.                               | ``00:00:06 -> 06``
``t``          ``A`` when time is in the AM. ``P`` when time is in the PM.                        | ``5pm -> P``
                                                                                                  | ``2am -> A``
``tt``         Same as above, but ``AM`` and ``PM`` instead of ``A`` and ``P`` respectively.      | ``5pm -> PM``
                                                                                                  | ``2am -> AM``
``yy``         The last two digits of the year. When parsing, the current century is assumed.     | ``2012 AD -> 12``
``yyyy``       The year, padded to atleast four digits.                                           | ``2012 AD -> 2012``
                Is always positive, even when the year is BC.                                      | ``24 AD -> 0024``
                When the year is more than four digits, '+' is prepended.                          | ``24 BC -> 00024``
                                                                                                  | ``12345 AD -> +12345``
``YYYY``       The year without any padding.                                                      | ``2012 AD -> 2012``
                Is always positive, even when the year is BC.                                      | ``24 AD -> 24``
                                                                                                  | ``24 BC -> 24``
                                                                                                  | ``12345 AD -> 12345``
``uuuu``       The year, padded to atleast four digits. Will be negative when the year is BC.     | ``2012 AD -> 2012``
                When the year is more than four digits, '+' is prepended unless the year is BC.    | ``24 AD -> 0024``
                                                                                                  | ``24 BC -> -0023``
                                                                                                  | ``12345 AD -> +12345``
``UUUU``       The year without any padding. Will be negative when the year is BC.                | ``2012 AD -> 2012``
                                                                                                  | ``24 AD -> 24``
                                                                                                  | ``24 BC -> -23``
                                                                                                  | ``12345 AD -> 12345``
``z``          Displays the timezone offset from UTC.                                             | ``UTC+7 -> +7``
                                                                                                  | ``UTC-5 -> -5``
``zz``         Same as above but with leading 0.                                                  | ``UTC+7 -> +07``
                                                                                                  | ``UTC-5 -> -05``
``zzz``        Same as above but with ``:mm`` where *mm* represents minutes.                      | ``UTC+7 -> +07:00``
                                                                                                  | ``UTC-5 -> -05:00``
``zzzz``       Same as above but with ``:ss`` where *ss* represents seconds.                      | ``UTC+7 -> +07:00:00``
                                                                                                  | ``UTC-5 -> -05:00:00``
``g``          Era: AD or BC                                                                      | ``300 AD -> AD``
                                                                                                  | ``300 BC -> BC``
``fff``        Milliseconds display                                                               | ``1000000 nanoseconds -> 1``
``ffffff``     Microseconds display                                                               | ``1000000 nanoseconds -> 1000``
``fffffffff``  Nanoseconds display                                                                | ``1000000 nanoseconds -> 1000000``
=============  =================================================================================  ================================================

Other strings can be inserted by putting them in ``''``. For example
``hh'->'mm`` will give ``01->56``.  The following characters can be
inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]``
``,``. A literal ``'`` can be specified with ``''``.

However you don't need to necessarily separate format patterns, an
unambiguous format string like ``yyyyMMddhhmmss`` is valid too (although
only for years in the range 1..9999).

Duration vs TimeInterval
----------------------------
The ``times`` module exports two similiar types that are both used to
represent some amount of time: ``Duration`` and ``TimeInterval``.
This section explains how they differ and when one should be prefered over the
other (short answer: use ``Duration`` unless support for months and years is
needed).

Duration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
A ``Duration`` represents a duration of time stored as seconds and
nanoseconds. A ``Duration`` is always fully normalized, so
``initDuration(hours = 1)`` and ``initDuration(minutes = 60)`` are equivilant.

Arithmetics with a ``Duration`` is very fast, especially when used with the
``Time`` type, since it only involves basic arithmetic. Because ``Duration``
is more performant and easier to understand it should generally prefered.

TimeInterval
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
A ``TimeInterval`` represents some amount of time expressed in calendar
units, for example "1 year and 2 days". Since some units cannot be
normalized (the length of a year is different for leap years for example),
the ``TimeInterval`` type uses seperate fields for every unit. The
``TimeInterval``'s returned form the this module generally don't normalize
**anything**, so even units that could be normalized (like seconds,
milliseconds and so on) are left untouched.

Arithmetics with a ``TimeInterval`` can be very slow, because it requires
timezone information.

Since it's slower and more complex, the ``TimeInterval`` type should be
avoided unless the program explicitly needs the features it offers that
``Duration`` doesn't have.

How long is a day?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
It should be especially noted that the handling of days differs between
``TimeInterval`` and ``Duration``. The ``Duration`` type always treats a day
as exactly 86400 seconds. For ``TimeInterval``, it's more complex.

As an example, consider the amount of time between these two timestamps, both
in the same timezone:

  - 2018-03-25T12:00+02:00
  - 2018-03-26T12:00+01:00

If only the date & time is considered, it appears that exatly one day has
passed. However, the UTC offsets are different, which means that the
UTC offset was changed somewhere between. This happens twice each year for
timezones that use daylight savings time. Because of this change, the amount
of time that has passed is actually 25 hours.

The ``TimeInterval`` type uses calendar units, and will say that exactly one
day has passed. The ``Duration`` type on the other hand normalizes everything
to seconds, and will therefore say that 90000 seconds has passed, which is
the same as 25 hours.
]##
