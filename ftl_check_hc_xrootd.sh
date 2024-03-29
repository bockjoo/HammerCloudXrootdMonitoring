#!/bin/bash
thesite=$1
if [ "x$thesite" == "x" ] ; then
   echo ERROR $(basename $0) provide the argument for the site name
   exit 1
fi
query_json=es.q.match_hc_xrootd.json
sed -e "s#@@thesite@@#$thesite#" ${query_json}.in > $query_json
eval $(sed 's#"DBID=#\n"DBID=#' es.q.match_hc_xrootd.json | grep ^\"DBID= | cut -d\" -f2)

#output=$(curl -H "Content-Type: application/x-ndjson" -H "Authorization: Bearer $(cat token.txt)" -XGET https://monit-grafana.cern.ch/api/datasources/proxy/${DBID}/_msearch --data-binary "@${query_json}" 2>/dev/null | sed 's#}\]}},{"key":"#\n#g' | grep ${thesite}\")
output=$(curl -H "Content-Type: application/x-ndjson" -H "Authorization: Bearer $(cat token.txt)" -XGET https://monit-grafana.cern.ch/api/datasources/proxy/${DBID}/_msearch --data-binary "@${query_json}" 2>/dev/null | sed 's#"CRAB_Workflow"#\n"CRAB_Workflow"#' | sed 's#}\]}},{"key":"#\n#g' | sed 's#"key":"#\n#' | grep ${thesite}\")

tasks=$(printf "$output\n" | cut -d\" -f1)
sum_0=0
sum_not_0=0
sum_completed=0
for task in $tasks ; do
  completed=$(printf "$output\n"  | grep $task | cut -d\" -f4 | cut -d: -f2 | cut -d, -f1)
  #keyscounts=$(printf "$output\n" | grep $task | cut -d\" -f13- | sed 's#}# #g')
  keyscounts=$(printf "$output\n" | grep $task | sed 's#$task#\n$task#' | grep $task | cut -d\" -f13- | sed 's#\[# #' | sed 's#}# #g' | sed 's#key"#\nkey"#g')
  sum_completed=$(expr $sum_completed + $completed)
  sum_exit_0=0
  sum_exit_not_0=0
  for keycount in $keyscounts ; do
      echo $keycount | grep -q key\": || continue
      echo $keycount | grep -q $task && continue
      key=$(echo $keycount | cut -d: -f2 | cut -d, -f1)
      count=$(echo $keycount | cut -d: -f3)
      if [ $key -eq 0 ] ; then
         sum_exit_0=$(expr $sum_exit_0 + $count)
         sum_0=$(expr $sum_0 + $count)
      else
         sum_exit_not_0=$(expr $sum_exit_not_0 + $count)
         sum_not_0=$(expr $sum_not_0 + $count)
      fi
  done
  sum=$(expr $sum_exit_not_0 + $sum_exit_0)
  success_rate=$(echo "scale=2 ; $sum_exit_0 / $sum " | bc)
  echo $task completed=$completed sum=$sum success=$success_rate
  if [ $completed -ne $sum ] ; then
     echo Warning $completed is not equal to $sum
  fi  
done
sum=$(expr $sum_not_0 + $sum_0)
if [ $sum -eq 0 ] ; then
   success_rate=-1.00
else
   success_rate=$(echo "scale=2 ; $sum_0 / $sum " | bc)
fi
echo alltasks sum_completed=$sum_completed sum=$sum success=$success_rate
exit 0


