#!/bin/bash
#
# This script should be invoked via setup_t2.sh or setup_p2.sh; those scripts
# will export the right environment variables for this to succeed.

# uncomment for debugging
# set -x

if [ $# -ne 1 ]; then
    echo "must supply instance name"
    exit 1
fi

if [ -z "$ami" ] || [ -z "$instanceType" ]; then
    echo "Missing \$ami or \$instanceType; this script should be called from"
    echo "setup_t2.sh or setup_p2.sh!"
    exit 1
fi

# settings
export name=$1
export keyname='deeplearn'
export cidr="0.0.0.0/0"

# BASH prompt colors
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m'

hash aws 2>/dev/null
if [ $? -ne 0 ]; then
    echo >&2 "'aws' command line tool required, but not installed.  Aborting."
    exit 1
fi

if [ -z "$(aws configure get aws_access_key_id)" ]; then
    echo "AWS credentials not configured.  Aborting"
    exit 1
fi

if [ -z ${AWS_SECURITY_GROUP_ID+x} ] && [ ! -f aws-network-vars.txt ]; 
then 
    echo Network config not found, creating network

    # create the stuff
    export AWS_VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/28 --query 'Vpc.AWS_VPC_ID' --output text)
    aws ec2 create-tags --resources $AWS_VPC_ID --tags --tags Key=Name,Value=$name
    aws ec2 modify-vpc-attribute --vpc-id $AWS_VPC_ID --enable-dns-support "{\"Value\":true}"
    aws ec2 modify-vpc-attribute --vpc-id $AWS_VPC_ID --enable-dns-hostnames "{\"Value\":true}"

    export AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.AWS_INTERNET_GATEWAY_ID' --output text)
    aws ec2 create-tags --resources $AWS_INTERNET_GATEWAY_ID --tags --tags Key=Name,Value=$name-gateway
    aws ec2 attach-internet-gateway --internet-gateway-id $AWS_INTERNET_GATEWAY_ID --vpc-id $AWS_VPC_ID

    export AWS_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $AWS_VPC_ID --cidr-block 10.0.0.0/28 --query 'Subnet.AWS_SUBNET_ID' --output text)
    aws ec2 create-tags --resources $AWS_SUBNET_ID --tags --tags Key=Name,Value=$name-subnet

    export AWS_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $AWS_VPC_ID --query 'RouteTable.AWS_ROUTE_TABLE_ID' --output text)
    aws ec2 create-tags --resources $AWS_ROUTE_TABLE_ID --tags --tags Key=Name,Value=$name-route-table
    export AWS_ROUTE_TABLE_ASSOC=$(aws ec2 associate-route-table --route-table-id $AWS_ROUTE_TABLE_ID --subnet-id $AWS_SUBNET_ID --output text)
    aws ec2 create-route --route-table-id $AWS_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $AWS_INTERNET_GATEWAY_ID

    export AWS_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $name-security-group --description "SG for fast.ai machine" --vpc-id $AWS_VPC_ID --query 'GroupId' --output text)
    # ssh
    aws ec2 authorize-security-group-ingress --group-id $AWS_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr $cidr
    # jupyter notebook
    # aws ec2 authorize-security-group-ingress --group-id $AWS_SECURITY_GROUP_ID --protocol tcp --port 8888-8898 --cidr $cidr

    # export the appropriate variables
    echo export AWS_VPC_ID=$AWS_VPC_ID > aws-network-vars.txt
    echo export AWS_INTERNET_GATEWAY_ID=$AWS_INTERNET_GATEWAY_ID >> aws-network-vars.txt
    echo export AWS_SUBNET_ID=$AWS_SUBNET_ID >> aws-network-vars.txt
    echo export AWS_ROUTE_TABLE_ID=$AWS_ROUTE_TABLE_ID >> aws-network-vars.txt
    echo export AWS_ROUTE_TABLE_ASSOC=$AWS_ROUTE_TABLE_ASSOC >> aws-network-vars.txt
    echo export AWS_SECURITY_GROUP_ID=$AWS_SECURITY_GROUP_ID >> aws-network-vars.txt

    # save delete commands for cleanup
    echo "#!/bin/bash" > network-remove.sh # overwrite existing file
    echo aws ec2 delete-security-group --group-id $AWS_SECURITY_GROUP_ID >> network-remove.sh

    echo aws ec2 disassociate-route-table --association-id $AWS_ROUTE_TABLE_ASSOC >> network-remove.sh
    echo aws ec2 delete-route-table --route-table-id $AWS_ROUTE_TABLE_ID >> network-remove.sh

    echo aws ec2 detach-internet-gateway --internet-gateway-id $AWS_INTERNET_GATEWAY_ID --vpc-id $AWS_VPC_ID >> network-remove.sh
    echo aws ec2 delete-internet-gateway --internet-gateway-id $AWS_INTERNET_GATEWAY_ID >> network-remove.sh
    echo aws ec2 delete-subnet --subnet-id $AWS_SUBNET_ID >> network-remove.sh

    echo aws ec2 delete-vpc --vpc-id $AWS_VPC_ID >> network-remove.sh
    echo echo If you want to delete the key-pair, please do it manually. >> network-remove.sh

    chmod +x network-remove.sh
fi

if [ ! -d ~/.ssh ]
then
	mkdir ~/.ssh
fi

if [ ! -f ~/.ssh/aws-key-$keyname.pem ]
then
	aws ec2 create-key-pair --key-name aws-key-$keyname --query 'KeyMaterial' --output text > ~/.ssh/aws-key-$keyname.pem
	chmod 400 ~/.ssh/aws-key-$keyname.pem
fi

export AWS_INSTANCE_ID=$(aws ec2 run-instances --image-id $ami --count 1 --instance-type $instanceType --key-name aws-key-$keyname --security-group-ids $AWS_SECURITY_GROUP_ID --subnet-id $AWS_SUBNET_ID --associate-public-ip-address --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 128, \"VolumeType\": \"gp2\" } } ]" --query 'Instances[0].InstanceId' --output text)
aws ec2 create-tags --resources $AWS_INSTANCE_ID --tags --tags Key=Name,Value=$name-gpu-machine
export AWS_ALLOC_ADDR=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

echo Waiting for instance start...
aws ec2 wait instance-running --instance-ids $AWS_INSTANCE_ID
sleep 10 # wait for ssh service to start running too
export AWS_ASSOC_ID=$(aws ec2 associate-address --instance-id $AWS_INSTANCE_ID --allocation-id $AWS_ALLOC_ADDR --query 'AssociationId' --output text)
export AWS_INSTANCE_URL=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query 'Reservations[0].Instances[0].PublicDnsName' --output text)
#export AWS_EBS_VOLUME=$(aws ec2 describe-instance-attribute --instance-id $AWS_INSTANCE_ID --attribute  blockDeviceMapping  --query BlockDeviceMappings[0].Ebs.VolumeId --output text)

if ! grep -Fxq $AWS_INSTANCE_URL ~/.ssh/config; then
    echo "Host $name $AWS_INSTANCE_URL" > $name-ssh-config.txt
    echo " HostName $AWS_INSTANCE_URL" >> $name-ssh-config.txt
    echo " User ubuntu" >> $name-ssh-config.txt
    echo " IdentityFile ~/.ssh/aws-key-$keyname.pem" >> $name-ssh-config.txt
    echo " IdentitiesOnly yes" >> $name-ssh-config.txt
    echo " LocalForward 9999 localhost:8888" >> $name-ssh-config.txt
    echo " LocalForward 6006 localhost:6006" >> $name-ssh-config.txt
fi

# reboot instance, because I was getting "Failed to initialize NVML: Driver/library version mismatch"
# error when running the nvidia-smi command
# see also http://forums.fast.ai/t/no-cuda-capable-device-is-detected/168/13
aws ec2 reboot-instances --instance-ids $AWS_INSTANCE_ID

# save commands to file
echo \# Connect to your instance: > $name-commands.txt # overwrite existing file
echo ssh -i ~/.ssh/aws-key-$name.pem ubuntu@$AWS_INSTANCE_URL >> $name-commands.txt
echo \# Stop your instance: : >> $name-commands.txt
echo aws ec2 stop-instances --instance-ids $AWS_INSTANCE_ID  >> $name-commands.txt
echo \# Start your instance: >> $name-commands.txt
echo aws ec2 start-instances --instance-ids $AWS_INSTANCE_ID  >> $name-commands.txt
echo \# Reboot your instance: >> $name-commands.txt
echo aws ec2 reboot-instances --instance-ids $AWS_INSTANCE_ID  >> $name-commands.txt
echo ""

# export vars to be sure
echo export AWS_INSTANCE_ID=$AWS_INSTANCE_ID > $name-aws-instance-vars.txt
echo export AWS_ALLOC_ADDR=$AWS_ALLOC_ADDR >> $name-aws-instance-vars.txt
echo export AWS_ASSOC_ID=$AWS_ASSOC_ID >> $name-aws-instance-vars.txt
echo export AWS_INSTANCE_URL=$AWS_INSTANCE_URL >> $name-aws-instance-vars.txt
echo export AWS_INSTANCE_NAME=$name >> $name-aws-instance-vars.txt

# save delete commands for cleanup
echo "#!/bin/bash" > $name-remove.sh # overwrite existing file
echo aws ec2 disassociate-address --association-id $AWS_ASSOC_ID >> $name-remove.sh
echo aws ec2 release-address --allocation-id $AWS_ALLOC_ADDR >> $name-remove.sh

# volume gets deleted with the instance automatically
echo aws ec2 terminate-instances --instance-ids $AWS_INSTANCE_ID >> $name-remove.sh
echo aws ec2 wait instance-terminated --instance-ids $AWS_INSTANCE_ID >> $name-remove.sh

chmod +x $name-remove.sh

echo -e $BLUE"All done."$NC
echo
echo -e $BLUE"Run the commands in $name-remove.sh to tear down."$NC
echo
if [ -f $name-ssh-config.txt ]
then
    echo -e $BLUE"Add the following (in $name-ssh-config.txt) to your ~/.ssh/config:"$NC
    echo
    cat $name-ssh-config.txt
    echo
fi
echo -e $BLUE"Add the following (in $name-aws-instance-vars.txt) to your environment variables:"$NC
echo -e $BLUE"cp aws-network-vars.txt ~/dotfiles/"$NC
echo -e $BLUE"cp $name-aws-instance-vars.txt ~/dotfiles/"$NC
echo 

cat $name-aws-instance-vars.txt

# Find all you need to connect in the $name-commands.txt file and to remove the stack call $name-remove.sh
# echo Connect to your instance: ssh -i ~/.ssh/aws-key-$name.pem ubuntu@$AWS_INSTANCE_URL
