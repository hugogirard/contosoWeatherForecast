targetScope = 'subscription'

@description('The name of the resource group')
param resourceGroupName string

@description('The name of the virtual network that will contains the apps')
param vnetName string

@description('The prefix of the virtual network')
param vnetAddressPrefix string

@description('The prefix of the subnet that will be used for the vnet integration of the App Service')
param subnetVnetIntegrationAddressPrefix string

@description('The subnet for the private endpoint of the address prefix')
param subnetPrivateEndpointAddressPrefix string

@description('The subnet for agent of the address prefix')
param subnetAgentAddressPrefix string

var location = 'canadacentral'

/* 
  Creating resource group
*/

module rg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'rg'
  params: {
    name: resourceGroupName
    location: location
  }
}

/* 
  Creating virtual network and subnets
*/

module nsgapp 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsgapps'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    name: 'nsg-app'
  }
}

module nsgvm 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsgvm'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    name: 'nsg-jumpbox'
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.5.4' = {
  name: 'vnetapps'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: [
      {
        name: 'snet-vnet-integration'
        addressPrefix: subnetVnetIntegrationAddressPrefix
        networkSecurityGroupResourceId: nsgapp.outputs.resourceId
        delegation: 'Microsoft.Web/serverfarms'
      }
      {
        name: 'snet-pe'
        addressPrefix: subnetPrivateEndpointAddressPrefix
        networkSecurityGroupResourceId: nsgapp.outputs.resourceId
      }
      {
        name: 'snet-agent'
        addressPrefix: subnetAgentAddressPrefix
        networkSecurityGroupResourceId: nsgvm.outputs.resourceId
      }
    ]
  }
}

/* 
  Creating two web apps (backend and frontend) with
  two app service plan
*/

var suffix = uniqueString(rg.outputs.resourceId)

module aspfront 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'aspfrontend'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: 'asp-back-${suffix}'
    kind: 'linux'
    skuCapacity: 1
    skuName: 'B2'
  }
}

module aspbackend 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'aspbackend'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: 'asp-front-${suffix}'
    kind: 'linux'
    skuCapacity: 1
    skuName: 'B2'
  }
}

module webfront 'br/public:avm/res/web/site:0.15.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'webfront'
  params: {
    name: 'front-${suffix}'
    kind: 'app,linux'
    serverFarmResourceId: aspfront.outputs.resourceId
    virtualNetworkSubnetId: vnet.outputs.subnetResourceIds[0]
  }
}

module backend 'br/public:avm/res/web/site:0.15.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'backend'
  params: {
    name: 'back-${suffix}'
    kind: 'app,linux'
    serverFarmResourceId: aspbackend.outputs.resourceId
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      metadata: {
        name: 'CURRENT_STACK'
        value: 'dotnetcore'
      }
    }
    privateEndpoints: [
      {
        subnetResourceId: vnet.outputs.subnetResourceIds[1]
      }
    ]
  }
}

/*  Create the private DNS Zone */

module privateDnsZoneweb 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: 'privateDnsZoneweb'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    name: 'privatelink.azurewebsites.net'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnet.outputs.resourceId
      }
    ]
  }
}

@description('The name of the web app frontend')
output frontEndName string = webfront.outputs.name

@description('The name of the backend front end')
output backEndName string = backend.outputs.name
