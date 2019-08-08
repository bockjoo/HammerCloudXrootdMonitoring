#!/bin/bash
#
# License : Bockjoo Kim
# 
thesite=$1
if [ "x$thesite" == "x" ] ; then
   echo ERROR $(basename $0) provide the argument for the site name
   exit 1
fi

nhits_json=es.q.match_hc_xrootd_site.json
sort_search_json=es.q.match_hc_xrootd_site_sort_search.json
# Since we are looking at only up to 2 days of HC jobs, it is very unlikely for us to use sort_search_after, though
sort_search_after_json=es.q.match_hc_xrootd_site_sort_search_after.json

sed -e "s#@@thesite@@#$thesite#" ${nhits_json}.in > ${nhits_json}
eval $(sed 's#"DBID=#\n"DBID=#' ${nhits_json} | grep ^\"DBID= | cut -d\" -f2)
dbname=$(sed 's#"index"#\n"index"#' ${nhits_json} | grep ^\"index\" | cut -d\" -f4 | cut -d* -f1)

date1=$(date --date="1 day ago" +%Y-%m-%d) 
index="${dbname}*-${date1}"
scroll="20m"
size=10000
unique_f=data.CRAB_JobLogURL
tie_breaker_id=data.CRAB_TaskCreationDate

nhits=$(curl -H "Content-Type: application/x-ndjson" -H "Authorization: Bearer $(cat token.txt)" -XGET https://monit-grafana.cern.ch/api/datasources/proxy/${DBID}/_msearch --data-binary "@${nhits_json}" 2>/dev/null | sed 's#"hits":#\nhits_total #' | grep ^hits_total | cut -d: -f2 | cut -d, -f1)
echo INFO nhits=$nhits

sed -e "s#@@thesite@@#$thesite#" -e "s#@@size@@#$size#" -e "s#@@unique_f@@#$unique_f#" -e "s#@@tie_breakter_id@@#$tie_breaker_id#" ${sort_search_json}.in > ${sort_search_json}

nsearch=$(expr $nhits / $size)
for i in $(seq 0 $nsearch) ; do
   echo INFO page $i 
   if [ $i -eq 0 ] ; then
      curl -H "Content-Type: application/x-ndjson" -H "Authorization: Bearer $(cat token.txt)" -XGET https://monit-grafana.cern.ch/api/datasources/proxy/${DBID}/_msearch --data-binary "@${sort_search_json}" 2>/dev/null 1> $(basename $0 | sed "s#\.sh##").$i.out
      search_after=$(sed 's#sort":#\nsort":#g' $(basename $0 | sed "s#\.sh##").$i.out | grep ^sort | tail -1 | cut -d\[ -f2- | cut -d\] -f1)
   else
      sed -e "s#@@thesite@@#$thesite#" -e "s#@@size@@#$size#" -e "s#@@search_after@@#$search_after#" -e "s#@@unique_f@@#$unique_f#" -e "s#@@tie_breakter_id@@#$tie_breaker_id#" ${sort_search_search_json}.in > ${sort_search_after_json}
      curl -H "Content-Type: application/x-ndjson" -H "Authorization: Bearer $(cat token.txt)" -XGET https://monit-grafana.cern.ch/api/datasources/proxy/${DBID}/_msearch --data-binary "@${sort_search_after_json}" 2>/dev/null 1> $(basename $0 | sed "s#\.sh##").$i.out
      search_after=$(sed 's#sort":#\nsort":#g' $(basename $0 | sed "s#\.sh##").$i.out | grep ^sort | tail -1 | cut -d\[ -f2- | cut -d\] -f1) # "cmsgwms-submit5.fnal.gov#141210.58#1556679777",1556693872000
      #gzip -c $(basename $0 | sed "s#\.sh##").$i.out > $(basename $0 | sed "s#\.sh##").$i.out.gz
   fi
done

# All lines with Site ExitCode CRAB_Workflow CRAB_JobLogURL
output=$(sed 's#"data":#\n"data":#g' $(basename $0 | sed "s#\.sh##").*.out| sed 's#,"#,\n"#g' | sed 's#"Site":#\n"Site":#g' | sed 's#"ExitCode":#\n"ExitCode":#g' | sed 's#"Status":#\n"Status":#g' | sed 's#"CRAB_Workflow":#\n"CRAB_Workflow":#g' | sed 's#"CRAB_JobLogURL"#\n"CRAB_JobLogURL"#g' | sed 's#"CRAB_PostJobLogURL"#\n"CRAB_PostJobLogURL"#g' | grep "^\"Site\"\|^\"ExitCode\"\|\"CRAB_Workflow\"\|\"CRAB_JobLogURL\"" | while read line1 ; do read line2 ; read line3 ; read line4 ; echo $line1 $line2 $line3 $line4 | sed 's# ##g'; done)
workflows=$(printf "$output\n" | sed 's#,#\n#g' | grep CRAB_Workflow | cut -d\" -f4 | sort -u)
for workflow in $workflows ; do
   completed=$(printf "$output\n" | grep $workflow | wc -l)
   sites=$(printf "$output\n" | grep $workflow | sed 's#,#\n#g' | grep \"Site\" | cut -d\" -f4 | sort -u)
   sum=0
   for s in $sites ; do
      count=$(printf "$output\n" | grep $workflow | sed 's#,#\n#g' | grep :\"$s\" | wc -l)
      #echo $(echo $workflow | cut -d: -f1) $s: $count
      sum=$(expr $sum + $count)
   done
   echo $(echo $workflow | cut -d: -f1) completed=$completed sum=$sum
   for s in $sites ; do
      count=$(printf "$output\n" | grep $workflow | sed 's#,#\n#g' | grep :\"$s\" | wc -l)
      exitcodes=$(printf "$output\n" | grep $workflow | grep ":\"$s\"" | sed 's#,#\n#g' | grep "\"ExitCode\":" | cut -d: -f2 | sort -u)
      sumc=0
      for exitcode in $exitcodes ; do
          c=$(printf "$output\n" | grep $workflow | grep ":\"$s\"" | grep "\"ExitCode\":${exitcode}," | wc -l)
          #echo "        " Site=$s ExitCode"(=$exitcode)": $c
          sumc=$(expr $sumc + $c)
          if [ $exitcode -eq 0 ] ; then
             echo "        " Site=$s ExitCode"(=$exitcode)"
          else
             CRAB_JobLogURLs=$(printf "$output\n" | grep $workflow | grep ":\"$s\"" | grep "\"ExitCode\":${exitcode}," | sed 's#,#\n#g' | grep "\"CRAB_JobLogURL\":" | cut -d\" -f4)
             echo "        " Site=$s ExitCode"(=$exitcode)" CRAB_JobLogURLs
             for url in $CRAB_JobLogURLs ; do
                echo "           " $url
             done
             
          fi
      done
      #echo "   " Site=$s SiteCount=$count ExitCodeCount=$sumc
   done
done

echo rm -f $(basename $0 | sed "s#\.sh##").*.out

exit 0
