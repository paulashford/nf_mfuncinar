#!/usr/bin/sed -Ef
s/([M|R|K][1])-(cpdb|humanbase|string)-([0-9].[0-9]).dat:([0-9].*)*/\1-\2\t\3\t\4/g
