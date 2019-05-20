#Preparation if needed
#az login --use-device-code
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

$vnet="Test-VNet" #name of the existing vNET with the two subnets
$rg="SubnetTest-rg" 
$pub_sn_nsg="nsg4pub-subnet" #name of the NEW Network Security Group for the public subnet
$pub_sn="public-sn" #name of the existing public subnet
$pub_sn_allowed_ipaddr=@("11.22.33.44", "22.33.44.55")  #allowed ip adresses to access the public subnet
$prv_sn_nsg="nsg4prv-subnet" #name of the NEW Network Security Group for the private subnet
$prv_sn="private-sn" #name of the existing private subnet

# create NSG for the public subnet
az network nsg create -g $rg -n $pub_sn_nsg
# create a new rule for allowed IP adresses
az network nsg rule create -g $rg --nsg-name $pub_sn_nsg -n "AllowFromSpecialIPAddresses" --priority 100  --source-address-prefixes $pub_sn_allowed_ipaddr --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*" --access Allow --direction Inbound --protocol "*" --description "Allow public access only from the listed IP addresses"
# assign the NSG to the public subnet
az network vnet subnet update -g $rg -n $pub_sn --vnet-name $vnet --network-security-group $pub_sn_nsg

# get the address prefix of the public subnet, this will be the allowed address range for the private subnet 
$pub_sn_addrPrefix = az network vnet subnet show -g $rg -n $pub_sn --vnet-name $vnet | ConvertFrom-Json | Select addressPrefix
#$pub_sn_addrPrefix.addressPrefix

az network nsg create -g $rg -n $prv_sn_nsg
az network nsg rule create -g $rg --nsg-name $prv_sn_nsg -n "AllowFromPublicSubnet" --priority 100  --source-address-prefixes $pub_sn_addrPrefix.addressPrefix --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*" --access Allow --direction Inbound --protocol "*" --description "Allow access only from the public subnet of this vnet"
# rule that denies all other vnet inbound traffic
az network nsg rule create -g $rg --nsg-name $prv_sn_nsg -n "DenyOtherVNetInBound" --priority 200  --source-address-prefixes "VirtualNetwork" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*" --access Deny --direction Inbound --protocol "*" --description "Allow access only from the public subnet of this vnet"
# assign the NSG to the public subnet
az network vnet subnet update -g $rg -n $prv_sn --vnet-name $vnet --network-security-group $prv_sn_nsg
