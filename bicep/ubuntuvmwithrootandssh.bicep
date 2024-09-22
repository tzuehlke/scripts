targetScope = 'resourceGroup'
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

resource sourceNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-ubuntutest'
  location: resourceGroup().location
}

resource sourceVnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'vnet-ubuntutest'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {id: sourceNsg.id}
        }
      }
    ]
  }
}

resource ubuntuVM 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'ubuntutest'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'ubuntutest'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicUbuntuVM.id
        }
      ]
    }
  }
}

resource activateRoot 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  parent: ubuntuVM
  name: 'ActivateRootWithSSH'
  location: resourceGroup().location
  properties:{
    protectedParameters: [
      {
        name: 'ROOTPW'
        value: adminPassword
      }
    ]
    errorBlobUri: 'https://<STORAGE ACCOUNT>.blob.core.windows.net/<CONTAINER>/error.txt?<SAS TOKEN>'
    outputBlobUri: 'https://<STORAGE ACCOUNT>.blob.core.windows.net/<CONTAINER>/output.txt?<SAS TOKEN>'
    source:{
      script: '''
        sudo passwd -u root && sudo echo "root:$ROOTPW" | chpasswd && echo "root pw changed" \
        sudo echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && sudo service ssh reload && echo "ssh restarted"
      '''
    }
  }
}

resource nicUbuntuVM 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'nicUbuntuVM'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: sourceVnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}
