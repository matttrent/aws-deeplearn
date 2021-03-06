#!/bin/bash
#
# Configure a p2.xlarge instance

# get the correct ami
export region=$(aws configure get region)
if [ $region = "us-west-2" ]; then
   export ami="ami-bc508adc" # Oregon
elif [ $region = "eu-west-1" ]; then
   export ami="ami-b43d1ec7" # Ireland
elif [ $region = "us-east-1" ]; then
  export ami="ami-31ecfb26" # Virginia
else
  echo "Only us-west-2 (Oregon), eu-west-1 (Ireland), and us-east-1 (Virginia) are currently supported"
  exit 1
fi

export instanceType="p2.xlarge"
# export instanceType="p2.8xlarge"
# export instanceType="p2.16xlarge"

if [ $# -ne 1 ]; then
    echo "must supply instance name"
    exit 1
fi

. $(dirname "$0")/create-instance.sh $1
