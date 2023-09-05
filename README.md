# Azure API Management demos

Azure API Management demos

## NSG

NSG is required for API Management service deployment into a subnet:

```json
{
  "error": {
    "code": "InvalidParameters",
    "message": "Invalid parameter: API Management service deployment into SubnetId 
    `/subscriptions/<subscriptionid>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/vnet-apim/subnets/snet-apim` 
    requires a Network Security Group to be associated with it. For recommended configuration and sample templates, please refer to aka.ms/apimvnet",
    "details": null,
    "innerError": null
  }
}
```
See [aka.ms/apimvnet](https://aka.ms/apimvnet) for more details.
