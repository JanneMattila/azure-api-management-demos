# SOAP

This repo contain simple Web Service implementation for `ProductsService`.
WSDL fils is saved to [ProductsService.wsdl](./ProductsService.wsdl).

## SOAP pass-through

Import to Azure API Management:

![Import to Azure API Management](./images/apim-soap1.png)

SOAP API in Azure API Management:

![SOAP API in Azure API Management](./images/apim-soap2.png)

Expose API using [dev tunnel](https://learn.microsoft.com/en-us/azure/developer/dev-tunnels/get-started?tabs=windows).

Update the url in APIM:

![Update the url in APIM](./images/apim-soap3.png)

Test the API:

![Test the API](./images/apim-soap4.png)

Each method has types defined in APIM:

![Types defined in APIM](./images/apim-soap5.png)

## SOAP to REST

Import to Azure API Management:

![Import to Azure API Management](./images/apim-soap6.png)

SOAP API in Azure API Management:

![SOAP API in Azure API Management](./images/apim-soap7.png)

APIM Policy to convert SOAP to REST:

![APIM Policy to convert SOAP to REST](./images/apim-soap8.png)

`GetProducts` method converted to REST:

```xml
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/Services/ProductsService.asmx" copy-unmatched-params="false" />
        <set-header name="SOAPAction" exists-action="override">
            <value>"https://products.jannemattila.com/GetProducts"</value>
        </set-header>
        <set-body template="liquid">
			<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns="https://products.jannemattila.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<soap:Body>
					<GetProducts>
					</GetProducts>
				</soap:Body>
			</soap:Envelope>
		</set-body>
        <set-header name="Content-Type" exists-action="override">
            <value>text/xml</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <choose>
            <when condition="@(context.Response.StatusCode < 400)">
                <set-body template="liquid">
        {
            "getProductsResponse": 
            {
                "getProductsResult": 
                [
                    {% JSONArrayFor item in body.envelope.body.GetProductsResponse.GetProductsResult -%}
                    {
                        "id": {% if item.Id %}{{item.Id}}{% else %} null {% endif %},
                        "name": {% if item.Name %}"{{item.Name | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "description": {% if item.Description %}"{{item.Description | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "price": {% if item.Price %}{{item.Price}}{% else %} null {% endif %},
                        "productName": {% if item.ProductName %}"{{item.ProductName | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productDescription": {% if item.ProductDescription %}"{{item.ProductDescription | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productPrice": {% if item.ProductPrice %}{{item.ProductPrice}}{% else %} null {% endif %},
                        "productQuantity": {% if item.ProductQuantity %}{{item.ProductQuantity}}{% else %} null {% endif %},
                        "productCategory": {% if item.ProductCategory %}"{{item.ProductCategory | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productImage": {% if item.ProductImage %}"{{item.ProductImage | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productStatus": {% if item.ProductStatus %}"{{item.ProductStatus | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productCreated": {% if item.ProductCreated %}"{{item.ProductCreated | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productUpdated": {% if item.ProductUpdated %}"{{item.ProductUpdated | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productType": {% if item.ProductType %}"{{item.ProductType | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productBrand": {% if item.ProductBrand %}"{{item.ProductBrand | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productModel": {% if item.ProductModel %}"{{item.ProductModel | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productColor": {% if item.ProductColor %}"{{item.ProductColor | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %},
                        "productSize": {% if item.ProductSize %}"{{item.ProductSize | Replace: '\r', '\r' | Replace: '\n', '\n' | Replace: '([^\\](\\\\)*)"', '$1\"'}}"{% else %} null {% endif %}
                    }
                    {% endJSONArrayFor -%}
                ]
            }
        }</set-body>
            </when>
            <otherwise>
                <set-variable name="old-body" value="@(context.Response.Body.As<string>(preserveContent: true))" />
                <!-- Error response as per https://github.com/Microsoft/api-guidelines/blob/master/Guidelines.md#7102-error-condition-responses -->
                <set-body template="liquid">{
            "error": {
                "code": "{{body.envelope.body.fault.faultcode}}",
                "message": "{{body.envelope.body.fault.faultstring}}"
            }
        }</set-body>
                <choose>
                    <when condition="@(string.IsNullOrEmpty(context.Response.Body.As<JObject>(preserveContent: true)["error"]["code"].ToString()) && string.IsNullOrEmpty(context.Response.Body.As<JObject>(preserveContent: true)["error"]["message"].ToString()))">
                        <set-body>@{
                    var newResponseBody = new JObject();
                    newResponseBody["error"] = new JObject();
                    newResponseBody["error"]["code"] = "InvalidErrorResponseBody";
                    if (string.IsNullOrEmpty((string)context.Variables["old-body"]))
                    {
                        newResponseBody["error"]["message"] = "The error response body was not a valid SOAP error response. The response body was empty.";
                    }
                    else
                    {
                        newResponseBody["error"]["message"] = "The error response body was not a valid SOAP error response. The response body was: '" + context.Variables["old-body"] + "'.";
                    }
                    return newResponseBody.ToString();
                }</set-body>
                    </when>
                </choose>
            </otherwise>
        </choose>
        <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
        </set-header>
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

Update the url in APIM (note the path!):

![Update the url in APIM](./images/apim-soap9.png)

Test the API:

![Test the API](./images/apim-soap10.png)
