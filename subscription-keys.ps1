$subscriptionName = "development"

$apimNameSource = "apimanagementdemo00011"
$apimNameTarget = "apimanagementdemo00011"
$resourceGroupName = "rg-api-management"

$outputFile = "subscriptions.csv"

class APIMSubscription {
    [string] $Id
    [string] $Name
    [string] $UserId
    [string] $ProductId
    [string] $State
    [string] $CreatedDate
    [string] $StartDate
    [string] $ExpirationDate
    [string] $EndDate
    [string] $NotificationDate
    [string] $PrimaryKey
    [string] $SecondaryKey
    [string] $StateComment
    [boolean] $AllowTracing
    [string] $Scope
    [string] $ToBeImported
}

$subscriptions = New-Object Collections.Generic.List[APIMSubscription]

# Select source subscription
Select-AzSubscription -SubscriptionName $subscriptionName

# Extract current subscriptions
$apim = Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimNameSource
$apimContextSource = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimNameSource
$apimSubscriptionsSource = Get-AzApiManagementSubscription -Context $apimContextSource

foreach ($subscription in $apimSubscriptionsSource) {
    $keys = Get-AzApiManagementSubscriptionKey -Context $apimContextSource -SubscriptionId $subscription.SubscriptionId

    $s = New-Object APIMSubscription
    $s.Id = $subscription.Id
    $s.Name = $subscription.Name
    $s.UserId = $subscription.UserId
    $s.ProductId = $subscription.ProductId
    $s.State = $subscription.State
    $s.CreatedDate = $subscription.CreatedDate
    $s.StartDate = $subscription.StartDate
    $s.ExpirationDate = $subscription.ExpirationDate
    $s.EndDate = $subscription.EndDate
    $s.NotificationDate = $subscription.NotificationDate
    $s.PrimaryKey = $keys.PrimaryKey
    $s.SecondaryKey = $keys.SecondaryKey
    $s.StateComment = $subscription.StateComment
    $s.AllowTracing = $subscription.AllowTracing
    $s.Scope = $subscription.Scope.Replace($apim.Id, "")
    $s.ToBeImported = "No"

    $subscriptions.Add($s)
}

$subscriptions | Format-Table
$subscriptions | Export-Csv $outputFile -Delimiter ';' -Force

"Opening Excel..."
""
"Edit the 'ToBeImported' column to 'Yes' for the rows you want to import to the target APIM."
"Save the file and close Excel."

# Open in Excel
Start-Process $outputFile

pause

$sourceSubscriptions = Import-Csv -Path $outputFile -Delimiter ';'

$toBeImportedList = $sourceSubscriptions | Where-Object -Property ToBeImported -Value "Yes" -IEQ

"Importing $($toBeImportedList.Count) subscriptions:"
$toBeImportedList | Format-Table

# Select target subscription
Select-AzSubscription -SubscriptionName $subscriptionName

$apimContextTarget = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimNameTarget

$processed = 1
$totalCount = $toBeImportedList.count
foreach ($toBeImported in $toBeImportedList) {
    Write-Host "$processed / $totalCount - Importing subscription '$($toBeImported.Name)'"
    $processed++

    $toBeImported.PSObject.Properties.Remove("Id")
    $toBeImported.PSObject.Properties.Remove("ToBeImported")
    $toBeImported.PSObject.Properties.Remove("CreatedDate")

    $allowTracing = $toBeImported.AllowTracing
    $toBeImported.PSObject.Properties.Remove("AllowTracing")

    $params = @{}
    $toBeImported | Get-Member -MemberType Properties | Select-Object -exp "Name" | ForEach-Object {
        $value = ($toBeImported | Select-Object -exp $_)
        if ([string]::IsNullOrEmpty($value) -eq $false) {
            $params[$_] = $value
        }
    }
    $params
    
    if ([boolean]::Parse($allowTracing) -eq $true) {
        $params["AllowTracing"] = $true
    }

    New-AzApiManagementSubscription `
        -Context $apimContextTarget `
        @params

    # Note: You cannot import a subscription with the same primary key or secondary key:
    # ---------------------------
    # Error Code: ValidationError
    # Error Message: Another subscription is already using specified primaryKey or secondaryKey
}