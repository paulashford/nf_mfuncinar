#!/usr/bin/sed -Ef
s/^.*\_\_([M|R|K][1])\_\_.*(cpdb|humanbase|string).*([0-9].[0-9]).dat/network-modules-\1-\2-\3.dat/g
