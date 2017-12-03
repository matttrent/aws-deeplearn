#!/bin/bash
#
# Configure a p3.2xlarge instance

# get the correct ami
export region=$(aws configure get region)
if [ $region = "us-west-2" ]; then
   export ami="ami-f1e73689" # Oregon
elif [ $region = "eu-west-1" ]; then
   export ami="ami-1812bb61" # Ireland
elif [ $region = "us-east-1" ]; then
  export ami="ami-405ade3a" # Virginia
else
  echo "Only us-west-2 (Oregon), eu-west-1 (Ireland), and us-east-1 (Virginia) are currently supported"
  exit 1
fi

export instanceType="p3.2xlarge"

if [ $# -ne 1 ]; then
    echo "must supply instance name"
    exit 1
fi

. $(dirname "$0")/create-instance.sh $1
