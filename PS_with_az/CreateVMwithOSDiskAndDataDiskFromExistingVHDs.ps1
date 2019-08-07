# Connect-AzAccount
# Select-AzSubscription <SUBSCRIPTIONNAME>

$rgName = "vhd4vm2"
$location = "westeurope"
$nicname = "vm1-nic"
$subnet1Name = "vm1-subnet"
$vnetName = "vm1-vnet"
$vnetAddressPrefix = "10.0.0.0/16"
$vnetSubnetAddressPrefix = "10.0.0.0/24"
$vmName = "vm1"
$vmSize = "Standard_D2s_v3"
$vhdStorageAccount = "<STORAGEACCOUNTNAME>"
$rgVhdStorageAccount = "<RG-STORAGEACCOUNTNAME>"
$disk1src = "https://<STORAGEACCOUNTNAME>.blob.core.windows.net/<CONTAINER>/disk1-fixed.vhd"
$disk2src = "https://<STORAGEACCOUNTNAME>.blob.core.windows.net/<CONTAINER>/disk2-fixed.vhd"

$pip = New-AzPublicIpAddress -Name $nicname -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic
$subnetconfig = New-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $vnetSubnetAddressPrefix
$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetconfig
$nic = New-AzNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$discStorageAcc = Get-AzStorageAccount -ResourceGroupName $rgVhdStorageAccount -Name $vhdStorageAccount

$diskConfig1 = New-AzDiskConfig -AccountType 'Premium_LRS' -Location $location -CreateOption Import -StorageAccountId ($discStorageAcc.Id) -SourceUri $disk1src
$disk1 = New-AzDisk -Disk $diskConfig1 -ResourceGroupName $rgName -DiskName "disk1"
$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $disk1.Id -CreateOption Attach -Linux
$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $disk1.Id -CreateOption Attach -Linux

$diskConfig2 = New-AzDiskConfig -AccountType 'Premium_LRS' -Location $location -CreateOption Import -StorageAccountId ($discStorageAcc.Id) -SourceUri $disk2src
$disk2 = New-AzDisk -Disk $diskConfig2 -ResourceGroupName $rgName -DiskName "disk2"
$vm = Add-AzVMDataDisk -VM $vm -ManagedDiskId $disk2.Id -CreateOption Attach -Lun 0

New-AzVM -ResourceGroupName $rgName -Location $location -VM $vm -Verbose