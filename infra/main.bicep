@description('The name of the virtual network that will contains the apps')
param vnetName string

@description('The prefix of the virtual network')
param vnetAddressPrefix string

@description('The prefix of the subnet that will be used for the vnet integration of the App Service')
param subnetVnetIntegrationAddressPrefix string

@description('The subnet for the private endpoint of the address prefix')
param subnetPrivateEndpointAddressPrefix string

/* 
  Creating virtual network and subnets
*/

module nsgapp 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'nsg-apps'
  params: {
    name: 'nsg-app'
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.5.4' = {
  name: 'vnet-apps'
  params: {
    name: vnetName
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
    ]
  }
}
