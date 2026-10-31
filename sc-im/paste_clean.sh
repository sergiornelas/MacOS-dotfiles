#!/bin/sh
# Strip thousands separators (55,000 -> 55000) so sc-im parses them as numbers
pbpaste | perl -pe 's/(?<=\d),(?=\d{3}(?!\d))//g'
