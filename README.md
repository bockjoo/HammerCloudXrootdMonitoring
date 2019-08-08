# HammerCloudXrootdMonitoring
cron script and its dependent scripts that monitors the Hammer Cloud CRAB jobs submitted by CMS (an LHC experiment)
calculates the success rate for a given site, initially only for T2_US_Florida. But the scripts can be configured to monitor
other sites as well.

## How to use it
 git clone https://github.com/bockjoo/HammerCloudXrootdMonitoring.git
 cd HammerCloudXrootdMonitoring/
 sed -e "s#@@workdir@@#$(pwd)#" -e "s#@@@@notifytowhom@@#your@email.address#" -e "s#@@thesite@@#T2_US_Florida#" ftl_check_hc_xrootd_cron.sh.in > ftl_check_hc_xrootd_cron.sh
 chmod a+x ftl_check_hc_xrootd_cron.sh
 ./ftl_check_hc_xrootd_cron.sh
