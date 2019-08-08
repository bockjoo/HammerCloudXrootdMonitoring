#!/bin/bash
thesite=$1
if [ "x$thesite" == "x" ] ; then
   echo ERROR $(basename $0) provide the argument for the site name
   exit 1
fi
query_json=es.q.match_hc_xrootd.json
eval $(sed 's#"DBID=#\n"DBID=#' es.q.match_hc_xrootd.json | grep ^\"DBID= | cut -d\" -f2)

output=$(curl -H "Content-Type: application/x-ndjson" -H "Authorization: Bearer $(cat token.txt)" -XGET https://monit-grafana.cern.ch/api/datasources/proxy/${DBID}/_msearch --data-binary "@${query_json}" 2>/dev/null | sed 's#}\]}},{"key":"#\n#g' | grep ${thesite}\")

tasks=$(printf "$output\n" | cut -d\" -f1)
for task in $tasks ; do
  completed=$(printf "$output\n"  | grep $task | cut -d\" -f4 | cut -d: -f2 | cut -d, -f1)
  keyscounts=$(printf "$output\n" | grep $task | cut -d\" -f13- | sed 's#}# #g')
  sum_exit_0=0
  sum_exit_not_0=0
  for keycount in $keyscounts ; do
      echo $keycount | grep -q key\": || continue
      key=$(echo $keycount | cut -d: -f2 | cut -d, -f1)
      count=$(echo $keycount | cut -d: -f3)
      if [ $key -eq 0 ] ; then
         sum_exit_0=$(expr $sum_exit_0 + $count)
      else
         sum_exit_not_0=$(expr $sum_exit_not_0 + $count)
      fi
  done
  sum=$(expr $sum_exit_not_0 + $sum_exit_0)
  success_rate=$(echo "scale=2 ; $sum_exit_0 / $sum " | bc)
  echo $task completed=$completed sum=$sum success=$success_rate
  if [ $completed -ne $sum ] ; then
     echo Warning $completed is not equal to $sum
  fi  
done
exit 0


