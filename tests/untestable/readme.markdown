This directory contains integration tests which are not automatically executed
for various reasons:
- dependency on external services
- dependency on files / configuration / state of the local host
- tests that are extremely slow or require large amounts of memory or storage
- tests that spawn local daemons

Integration tests can become stale very quickly. Automated ./koch tests are
strongly recommended.
