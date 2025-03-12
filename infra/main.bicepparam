using 'main.bicep'

param resourceGroupName = 'rg-app-demo'

param subnetPrivateEndpointAddressPrefix = '10.0.2.0/27'

param subnetVnetIntegrationAddressPrefix = '10.0.1.0/24'

param vnetAddressPrefix = '10.0.0.0/16'

param vnetName = 'vnet-apps'
