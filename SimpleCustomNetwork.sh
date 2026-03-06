# This script will create a custom network named $NETWORKNAME in the project $PROJECTID
# Sbunets will be created for each Region in $REGIONLIST
# The IP range 10.80.0.0/16 will be used, subnetting into /24 ranges
# The first subnet will be created as 10.80.1.0/24 (the SUBNETNUMBER will be used as a counter)
#
# Three firewall rules will be created
# $NETWORKNAME-allowinternaltraffic: Allows any IPs beginning 10.80 to communicate directly with no firewall restrictions
# $NETWORKNAME-allowicmp: Allows ICMP (ping) traffic from the anywhere (including the Internet) to communicate with VMs
# $NETWORKNAME-allowssh: Allows SSH communicationes from the IP range used by Google's Identity Aware Proxy (IAP).
# The IAP range is used by the SSH button and also used when connecting via gcloud compute ssh $INSTANCENAME --ZONE=$ZONE 
# Adjust this rule as necessary to allow other known IP ranges (DO NOT ALLOW 0.0.0.0/0 - that allows the entire internet to connect)

# Set this value to name your network
PROJECTID="USEYOURPROJECTIDHERE"
NETWORKNAME="projectnetwork"
REGIONLIST="us-central1 us-east1 us-west1"
BASEIP="10.80"

# This command sets the project
# Alternately, add the --project=$PROJECTID parameter to each command
gcloud config set project $PROJECTID

# This creates a custom network. Network Name is defined in the Env Variable $NETWORKNAME
gcloud compute networks create $NETWORKNAME \
    --subnet-mode=custom

# This creates a subnet for each region
# SUBNETNUMBER will increment for each region
SUBNETNUMBER=1
echo $REGIONLIST
for REGION in $REGIONLIST; do
  SUBNET="$BASEIP.$SUBNETNUMBER.0/24"
  echo Creating Subnet for $REGION $SUBNET
  gcloud compute networks subnets create subnet-$REGION \
    --network=$NETWORKNAME \
    --region=$REGION \
    --range=$SUBNET
  SUBNETNUMBER=$((SUBNETNUMBER + 1))
done

# This allows Internal VMs (VMs with addresses beginning with $BASEIP) to communicate
gcloud compute firewall-rules create $NETWORKNAME-allowinternaltraffic \
    --network=$NETWORKNAME \
    --priority=65534 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=all \
    --source-ranges="$BASEIP.0.0/16"

# This allows PING traffic from the Internet to your VM
gcloud compute firewall-rules create $NETWORKNAME-allowicmp \
    --network=$NETWORKNAME \
    --priority=1000 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=icmp \
    --source-ranges=0.0.0.0/0

# This firewall rule will allow SSH using the Google SSH button or via Command Line
gcloud compute firewall-rules create $NETWORKNAME-allowssh \
    --network=$NETWORKNAME \
    --priority=1000 \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=35.235.240.0/20

