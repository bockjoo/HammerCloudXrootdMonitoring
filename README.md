## HammerCloudXrootdMonitoring
cron script and its dependent scripts that monitors the Hammer Cloud CRAB jobs submitted by CMS (an LHC experiment)
calculates the success rate for a given site, initially only for T2_US_Florida. But the scripts can be configured to monitor
other sites as well.

## How to use it
 git clone https://github.com/bockjoo/HammerCloudXrootdMonitoring.git
 
 cd HammerCloudXrootdMonitoring/
 
 sed -e "s#@@workdir@@#$(pwd)#" -e "s#@@notifytowhom@@#your@email.address#" -e "s#@@thesite@@#T2_XX_YYYYYYY#" ftl_check_hc_xrootd_cron.sh.in > ftl_check_hc_xrootd_cron.sh
 
 chmod a+x ftl_check_hc_xrootd_cron.sh
 
 ./ftl_check_hc_xrootd_cron.sh

## How to create a web page that shows result of all T2 sites
 git clone https://github.com/bockjoo/HammerCloudXrootdMonitoring.git

 cd HammerCloudXrootdMonitoring/

 sed -e "s#@@workdir@@#$(pwd)#" -e "s#@@notifytowhom@@#your@email.address#" -e "s#@@thesite@@#T2_XX_YYYYYYY#" cms_site_check_hc_xrootd.sh.in > cms_site_check_hc_xrootd.sh

 chmod a+x cms_site_check_hc_xrootd.sh

./cms_site_check_hc_xrootd.sh

