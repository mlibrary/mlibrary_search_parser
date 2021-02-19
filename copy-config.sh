#! /bin/bash

K8S_LOCATION="../../kubernetes-config/base/search/spectrum-config"
SPECTRUM_CONFIG_LOCATION="../spectrum/config/"
PARSER_TEST_CONFIG_LOCATION="./spec/data/"
BRANCH="parser-test-1"

cp $K8S_LOCATION/$BRANCH/config--foci--00-catalog.yml $PARSER_TEST_CONFIG_LOCATION/00-catalog.yml

for f in $K8S_LOCATION/common/config--*
do
  if [[ $f =~ ^.*foci.*$ ]]; then
    new=`echo $f | awk -F'--' '{print $3}'`
    cp $f $SPECTRUM_CONFIG_LOCATION/foci/$new
  else
    new=`echo $f | awk -F'--' '{print $2}'`
    cp $f $SPECTRUM_CONFIG_LOCATION/$new
  fi
done

for f in $K8S_LOCATION/$BRANCH/config--*
do
  echo $f
  if [[ $f =~ ^.*foci.*$ ]]; then
    new=`echo $f | awk -F'--' '{print $3}'`
    cp $f $CONFIG_LOCATION/foci/$new
  else
    new=`echo $f | awk -F'--' '{print $2}'`
    cp $f $CONFIG_LOCATION/$new
  fi
  echo $new
done
