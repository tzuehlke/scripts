targetScope = 'resourceGroup'
param adminUsername string = 'adminUser'
@secure()
param adminPassword string

resource sourceNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-sqltest'
  location: resourceGroup().location
}

resource sourceVnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'sqltest'
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

resource sqlserver 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'SQLServer'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'SQL2017-WS2016'
        sku: 'Standard'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'SQLServer'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicSqlServer.id
        }
      ]
    }
  }
}

resource nicSqlServer 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'nicSqlServer'
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

resource sqlServerInstall 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  parent: sqlserver
  name: 'sqlServerDbInstall'
  location: resourceGroup().location
  properties:{
    source:{
      script: '''
        $zipUrl = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip"
        $destinationFolder = "C:\AWSample"
        New-Item -ItemType Directory -Path $destinationFolder
        $zipFilePath = "$destinationFolder\file.zip"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $destinationFolder)
        Remove-Item -Path $zipFilePath
        sqlcmd -S $Env:COMPUTERNAME -E -i "$destinationFolder\instawdb.sql"
        New-NetFirewallRule -Name "Allow SQL Server" -DisplayName "SQL Server" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 1433 -Protocol TCP
      '''
    }
  }
}

// Deploy with: New-AzResourceGroupDeployment -ResourceGroupName <EXISTING RG> -TemplateFile <THISFILE>.bicep -adminPassword (ConvertTo-SecureString "..." -AsPlainText -Force)
