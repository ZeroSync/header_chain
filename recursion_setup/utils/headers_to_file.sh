#!/bin/bash
for i in {300001..400000}
do
   blockhash=`./bitcoin-cli getblockhash $i;`
   header=`./bitcoin-cli getblockheader $blockhash false`
   echo "$header" | xxd -r -p
done