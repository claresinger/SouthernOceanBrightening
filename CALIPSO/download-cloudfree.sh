#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (cesinger): " username
    username=${username:-cesinger}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-07N.hdf"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-07N.hdf -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-07N.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2020/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2020-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2019/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2019-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2018/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2018-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2017/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2017-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2016/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2016-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2015/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2015-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2014/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2014-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2013/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2013-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2012/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2012-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2011/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2011-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2010/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2010-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2009/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2009-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2008/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2008-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-06N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-05D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-05N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-04N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-04D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-03D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-03N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-02D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-02N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-01N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2007/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2007-01D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-12N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-12D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-11N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-11D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-10D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-10N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-09N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-09D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-08D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-08N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-07N.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-07D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-06D.hdf
https://asdc.larc.nasa.gov/data/CALIPSO/LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20/2006/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.2006-06N.hdf
EDSCEOF