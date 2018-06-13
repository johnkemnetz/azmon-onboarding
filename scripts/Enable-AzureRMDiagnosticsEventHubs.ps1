<#PSScriptInfo

.VERSION 1.0

.GUID e54c83df-440c-4933-8be8-30d0ff7f966c

.AUTHOR jbritt@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 
#https://blogs.technet.microsoft.com/msoms/2017/01/17/enable-azure-resource-metrics-logging-using-powershell

.ICONURI 
https://msdnshared.blob.core.windows.net/media/2017/01/1-OMS-011717.png

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
  May 1, 2018
  Intial Release
#>

<#  
.SYNOPSIS  
  Configure a resource (given a resource ID in Azure) to enable Azure Diagnostics and send that data to an Event Hub. 
  This EHID specified as a parameter is the EventHubAuthorizationRuleId of the Event Hub within an Azure Subscription in the following format
  
  "/subscriptions/<subscriptionID GUID>/resourceGroups/<EH Resource Group>/providers/Microsoft.EventHub/namespaces/<Event Hub Name>/AuthorizationRules/RootManageSharedAccessKey"

  Note  This script currently supports onboarding Azure resources that support Azure Diagnostics (metrics and logs) to Event Hubs only.
  
  Use of Update switch "-Update $True" updates the resource to a new event hub endpoint and enable diagnostics
  or just refresh the configuration for all resources.

  Use of "-Force" provides the ability to launch this script without prompting, if all required parameters are provided.
  
.DESCRIPTION  
  This script takes a SubscriptionID, ResourceType, ResourceGroup and an EventHubAuthorizationRuleId as parameters, analyzes the subscription or
  specific ResourceGroup defined for the resources specified in $Resources, and enables those resources for diagnostic metrics and logs
  also enabling the EventHubAuthorizationRuleId for the Event Hub endpoint to receive these metrics and logs.

.PARAMETER Update
    Specify update if you want to update all resources regardless of configuration

.PARAMETER EHID    
    The EventHubAuthorizationRuleId of your Event Hub within Azure
    
.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the resources you want to update/configure

.PARAMETER ResourceType
    The ResourceType you want to update within your Azure Subscription
    
.PARAMETER ResourceGroupName
    If desired, use a resourcegroup instead of updating all resources of a particular type within an Azure subscription

.PARAMETER ResourceName
    If desired, use a resource name instead of updating all resources of a particular type within an Azure subscription

.PARAMETER Force
    Use Force to run silently [providing all parameters needed for silent mode - see get-help <scriptfile> -examples]

.PARAMETER DisableLogsMetrics
    Use DisableLogsMetrics to remove logs and metrics for a resource 

.EXAMPLE
  .\Enable-AzureRMDiagnosticsEventHubs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceType "Microsoft.Sql/servers/databases" -ResourceGroup "RGName"
  Take in parameters and prompt for confirmation before continuing.

.EXAMPLE
  .\Enable-AzureRMDiagnosticsEventHubs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceType "Microsoft.Sql/servers/databases" -ResourceGroup "RGName" -Force
  Take in parameters and execute silently without prompting using Force.

.EXAMPLE
  .\Enable-AzureRMDiagnosticsEventHubs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceType "Microsoft.Sql/servers/databases" -ResourceGroup "RGName" -Force -Update
  Take in parameters and execute silently without prompting and update all resources with a new EHID

  NOTE: Remove -Force to be prompted.

.EXAMPLE
  .\Enable-AzureRMDiagnosticsEventHubs.ps1 -Verbose -Debug
  To Support Verbose and Debug log Output

.EXAMPLE
  .\Enable-AzureRMDiagnosticsEventHubs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceType "Microsoft.Sql/servers/databases" -ResourceGroup "RGName" -Force -DisableLogsMetrics
  Take in parameters and execute silently without prompting and disable Logs and Metrics 
  for a specific set of resources w/in a resource group and resourceType defined.

  NOTE: EHID can be any string in this instance since we are disabling.

.NOTES
   AUTHOR: Jim Britt Senior Program Manager - Azure CAT 
   LASTEDIT: May 01, 2018

   May 1st, 2018
   Intial Release

.LINK
    This script posted to and discussed at the following locations:
        https://www.powershellgallery.com/packages/Enable-AzureRMDiagnosticsEventHubs        
#>
param
(
    # Use Update to refresh a configuration such as changing to a new Event Hub target endpoint
    [switch]$Update,

    # Provide EventHubAuthoriziationRuleId of and Event Hub within same Azure AD Tenant 
    # to send multiple subs to one Event Hub endpoint
    [Parameter(Mandatory=$False,ParameterSetName='default')]
    [Parameter(Mandatory=$True,ParameterSetName='force')]
    [string]$EHID,

    # Provide SubscriptionID to bypass subscription listing
    [Parameter(Mandatory=$False,ParameterSetName='default')]
    [Parameter(Mandatory=$True,ParameterSetName='force')]
    [guid]$SubscriptionId,

    # Add ResourceType to reduce scope to Resource Type instead of entire list of resources to scan
    [Parameter(Mandatory=$False,ParameterSetName='default')]
    [Parameter(Mandatory=$True,ParameterSetName='force')]
    [string]$ResourceType,

    # Add a ResourceGroup name to reduce scope from entire Azure Subscription to RG
    [string]$ResourceGroupName,

    # Add a ResourceName name to reduce scope from entire Azure Subscription to specific named resource
    [string]$ResourceName,

    # Use Force to run in silent mode (requires certain parameters to be provided)
    [Parameter(Mandatory=$True,ParameterSetName='force')]
    [switch]$Force,

    # Use to remove the configuration of metrics for a selected resource type
    [switch]$DisableLogsMetrics

   
)
# FUNCTIONS
# Get the ResourceType listing from all ResourceTypes capable in this subscription
# to be sent to log analytics - use "-ResourceType" param to bypass
function Get-ResourceType (
    [Parameter(Mandatory=$True)]
    [array]$allResources
    )
{
    $analysis = @()
    
    foreach($resource in $allResources)
    {
        $Categories =@();
        $metrics = $false #initialize metrics flag to $false
        $logs = $false #initialize logs flag to $false
    
        if (! $analysis.where({$_.ResourceType -eq $resource.ResourceType}))
        {
            try
            {
                Write-Verbose "Checking $($resource.ResourceType)"
                $setting = Get-AzureRmDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction Stop
                # If logs are supported or metrics on each resource, set value as $True
                if ($setting.Logs) 
                { 
                    $logs = $true
                    $Categories = $setting.Logs.category 
                }


                if ($setting.Metrics) 
                { 
                    $metrics = $true
                }   
            }
            catch {}
            finally
            {
                $object = New-Object -TypeName PSObject -Property @{'ResourceType' = $resource.ResourceType; 'Metrics' = $metrics; 'Logs' = $logs; 'Categories' = $Categories}
                $analysis += $object
            }
        }
    }
    # Return the list of supported resources
    $analysis
}

# Enable Diagnostics and set EHID for each resource (if not already set)
function Set-Resource
{
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$True)]
        [array]$Resources,
        [switch]$Update,
        [string]$EHID,
        [psobject]$DiagnosticCapability,
        [string]$EHRegion
    )
    Write-Host "Processing resources.  Please wait...."
    Foreach($Resource in $Resources)
    {
        If(!($DisableLogsMetrics))
        {
            if(!($Resource.location -eq $EHRegion))
            {
                Write-Host "Resource $($Resource.Name) is in $($Resource.location) - different region from your Event Hub Rule ID in $EHRegion"  -ForegroundColor Yellow
                break
            }
            $EHIDOK = $True
            $ResourceDiagnosticSetting = get-AzureRmDiagnosticSetting -ResourceId $Resource.ResourceId
            if($ResourceDiagnosticSetting.EventHubAuthorizationRuleId -ne $null -and $ResourceDiagnosticSetting.EventHubAuthorizationRuleId -ne $EHID -and $Update -eq $False)
            {
                # If update switch not used, EHIDOK is set to false and warning is thrown
                $EHIDOK = $False
                $EH = ($ResourceDiagnosticSetting.EventHubAuthorizationRuleId -split "/namespaces/", 2)[1]
                $EH = ($EH -split "/", 2)[0]
                Write-Host "Resource $($Resource.Name) is already enabled for Event Hub $EH. " -NoNewline
                write-host "Use -Update" -ForegroundColor Yellow

            }
            # Update switch enables updating EventHubRuleID if one is already specified.
            if($Update -eq $True -and $EHIDOK -eq $True)
            {
                try
                {
                    $EH = ($ResourceDiagnosticSetting.EventHubAuthorizationRuleId -split "/namespaces/", 2)[1]
                    $EH = ($EH -split "/", 2)[0]
                    
                    $Diag = Set-AzureRmDiagnosticSetting -EventHubAuthorizationRuleId $EHID -ResourceId $Resource.ResourceId
                    if($Diag){Write-Host "Event Hub for existing resource $($Resource.Name) was updated to $EH."}
                }
                catch
                {
                    write-host "An error occurred setting diagnostics on $($Resource.Name)"
                }
            }
        
            if($DiagnosticCapability.logs -eq $True -OR $DiagnosticCapability.metrics -eq $True)
            {
                try
                {
                    $Diag = Set-AzureRmDiagnosticSetting -EventHubAuthorizationRuleId $EHID -ResourceId $Resource.ResourceId -Enabled $True
                    if($Diag){Write-Host "Resource $($Resource.Name) was enabled for all Logs and Metrics"}
                }
                catch
                {
                    write-host "An error occurred setting diagnostics on $($Resource.Name) for logs"
                }

            }
        }
        # Disable logs and metrics on a resource(s) if logs / metrics are a capablity supported on the resource(s)
        If($DisableLogsMetrics -and ($DiagnosticCapability.logs -eq $True -OR $DiagnosticCapability.Metrics -eq $True))
        {
            $ResourceDiagnosticSetting = get-AzureRmDiagnosticSetting -ResourceId $Resource.ResourceId
            if($ResourceDiagnosticSetting.ServiceBusRuleId -ne $Null -or $ResourceDiagnosticSetting.StorageAccountId -ne $Null -or $ResourceDiagnosticSetting.WorkspaceId -ne $Null)
            {
                try
                {
                    $SetEHRuleIDToNull = Set-AzureRmDiagnosticSetting -ResourceId $Resource.ResourceId -EventHubAuthorizationRuleId $Null
                    Write-Host "Resource $($Resource.Name) disabled for logs / metrics to event hub"
                }
                catch
                {
                    write-host "An error occurred removing diagnostic log / metrics on $($Resource.Name)"
                }

            }
            else
            {
                try
                {
                    $DisableLogsandMetrics = Set-AzureRmDiagnosticSetting -ResourceId $Resource.ResourceId -Enabled $False
                }
                catch
                {
                    write-host "An error occurred removing diagnostic log / metrics on $($Resource.Name)"
                }
            }
        }
    }
}

# Function used to build numbers in selection tables for menus
function Add-IndexNumberToArray 
(
    [Parameter(Mandatory=$True)]
    [array]$array
)

{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}

# Need to get region to ensure we are w/in region for configuration.
# EventHubs cannot receive data from other regions
function Get-EventHubRegion
(
    [Parameter(Mandatory=$True)]
    $EHID
)
{
    # Establish number of elements in ResourceID for Event Hub Rule
    $cnt = $($EHID.Split("/").Count+1)
    
    # Enumerate Name
    $EVENTHUBN = $($EHID.Split("/", $cnt)[8]) # Name 
    $ResourceType = "Microsoft.EventHub/namespaces"
    
    # Return object Details for EHRuleID 
    $ehoBJECT = Find-AzureRmResource -ResourceType $ResourceType -ResourceNameEquals $EVENTHUBN 
    
    # Return Location 
    # Note EventHubs can only receive data from the same region (EastUS to EastUS, EastUS 2 to EastUS 2, etc.)
    $($ehoBJECT.Location)
}

# Let's validate this is a properly formatted EventHub rule ID to the best of our ability
function ValidateID
{
    param
    (
        [Parameter(Mandatory=$False)]$EHID

    )
    $ValidID = $False
    $cnt = 0
    
    IF($EHID)
    {
        $cnt = $($EHID.Split("/").Count+1)
        if($($EHID.Split("/", $Cnt)[1]) -eq "Subscriptions" -and 
         $($EHID.Split("/", $Cnt)[6]) -eq "Microsoft.EventHub" -and 
         $cnt -ge 12)
        {
            # Valid EH RuleID
            $ValidID = $True
        }
            
        else
        {
            write-host "Invalid value passed to EHID" -ForegroundColor Red
            $ValidID = $False
        }
    }
    $ValidID
}

# MAIN SCRIPT
#Variable Definitions
[array]$Resources = @()

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzureRmSubscription
}
catch
{
    $null = Login-AzureRmAccount
    $AzureLogin = Get-AzureRmSubscription
}

# Authenticate to Azure if not already authenticated 
# Ensure this is the subscription where your Azure Resources are you want to send diagnostic data from
If($AzureLogin -and !($SubscriptionID))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzureRmSubscription) 
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1) 
    {
        $SelectedSub = 1
    }
    # Get SubscriptionID if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "Please select a subscription from the list below"
        $SubscriptionArray | select "#", Id, Name | ft
        try
        {
            $SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($SubscriptionArray[$SelectedSub - 1].Name))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    write-verbose "You Selected Azure Subscription: $SubscriptionName"
    
    if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
    }
    if($($SubscriptionArray[$SelectedSub - 1].ID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
    }
}

if(($EHID) -and !($DisableLogsMetrics))
{
    # Validate Event Hub Rule ID is in proper format - if not exit
    $ValidID = ValidateID -EHID $EHID
    if(!($ValidID)){exit}

    $cnt = $($EHID.Split("/").Count+1)        
    $EHSub = $($EHID.Split("/", $Cnt)[2])

    # Select Sub for EventHub to get region as a requirement
    Write-Host "Selecting Azure Subscription of Event Hub to get region..." -ForegroundColor Cyan
    $Null = Select-AzureRmSubscription -SubscriptionId $EHSub
    # Get Region for EHRuleID to ensure we are in same region as resource
    $EHRegion = Get-EventHubRegion -EHID $EHID
    write-host "Event Hub is in the $EHRegion region..." -ForegroundColor Cyan
}

Write-Host "Selecting Azure Subscription: $($SubscriptionID.Guid) ..." -ForegroundColor Cyan
$Null = Select-AzureRmSubscription -SubscriptionId $SubscriptionID.Guid

# Build a list of Event Hubs to choose from.  If an event hub is in another subscription
# provide the EventHubAuthoriziationRuleId of that Event Hub as a parameter
# *** Event Hub currently must be within the same tenant as the resource being configured ***
[array]$eventHubs=@()
if(!($EHID) -and !($DisableLogsMetrics))
{
    try
    {
        $eventHubs = Add-IndexNumberToArray (Get-AzureRmEventHubNamespace) 
        Write-Host "Generating a list of Event Hubs from Azure Subscription Selected..." -ForegroundColor Cyan

        [int]$SelectedEH = 0
        if ($eventHubs.Count -eq 1)
        {
            $SelectedEH = 1
        }

        # Get EventHubAuthoriziationRuleId if one isn't provided
        while($SelectedEH -gt $eventHubs.Count -or $SelectedEH -lt 1 -and $eventHubs -ne $Null)
        {
            Write-Host "Please select an Event Hub  from the list below"
            $eventHubs| select "#", Name, Location, ResourceGroup, Id | ft
            if($eventHubs.count -ne 0)
            {

                try
                {
                    $SelectedEH = Read-Host "Please enter a selection from 1 to $($eventHubs.count)"
                }
                catch
                {
                    Write-Warning -Message 'Invalid option, please try again.'
                }
            }
        }
    }
    catch
    {
        Write-Warning -Message 'No Event Hubs found - try specifying parameter EHID'
    }
    If($eventHubs)
    {
        Write-Host "You Selected Event Hub: " -nonewline -ForegroundColor Cyan
        Write-Host "$($eventHubs[$SelectedEH - 1].Name)" -ForegroundColor Yellow
        $EH = $eventHubs[$SelectedEH - 1]
        $EHID = $(Get-AzureRmEventHubAuthorizationRule -ResourceGroupName $EH.ResourceGroup -Namespace $EH.Name).id
    }
    else
    {
        Throw "No OMS Event Hubs available in selected subscription $SubscriptionID"
    }
    # Get Region for EHRuleID to ensure we are in same region as resource
    $EHRegion = Get-EventHubRegion -EHID $EHID
    write-host "Event Hub is in the $EHRegion region..." -ForegroundColor Cyan

}

# Determine which resourcetype to search on
[array]$ResourcesToCheck = @()
[array]$DiagnosticCapable=@()
[array]$Logcategories = @()

# Build parameter set according to parameters provided.
$FindResourceParams = @{}
if($ResourceType)
{
    $FindResourceParams['ResourceType'] = $ResourceType
}
if($ResourceGroupName)
{
    $FindResourceParams['ResourceGroupNameEquals'] = $ResourceGroupName
}
if($ResourceName)
{
    $FindResourceParams['ResourceNameEquals'] = $ResourceName
}
$ResourcesToCheck = Find-AzureRmResource @FindResourceParams 

# If resourceType defined, ensure it can support diagnostics configuration
if($ResourceType)
{
    try
    {
        $Resources = $ResourcesToCheck
        $DiagnosticCapable = Get-ResourceType -allResources $Resources
        [int]$ResourceTypeToProcess = 0
        if ( $DiagnosticCapable.Count -eq 1)
        {
            $ResourceTypeToProcess = 1
        }
    }
    catch
    {
        Throw "No diagnostic capable resources of type $ResourceType available in selected subscription $SubscriptionID"
    }

}

# Gather a list of resources supporting Azure Diagnostic logs and metrics and display a table
if(!($ResourceType))
{
    Write-Host "Gathering a list of monitorable Resource Types from Azure Subscription ID " -NoNewline -ForegroundColor Cyan
    Write-Host "$SubscriptionId..." -ForegroundColor Yellow
    try
    {
        $DiagnosticCapable = Add-IndexNumberToArray (Get-ResourceType $ResourcesToCheck).where({$_.metrics -eq $True -or $_.Logs -eq $True}) 
        [int]$ResourceTypeToProcess = 0
        if ( $DiagnosticCapable.Count -eq 1)
        {
            $ResourceTypeToProcess = 1
        }
        while($ResourceTypeToProcess -gt $DiagnosticCapable.Count -or $ResourceTypeToProcess -lt 1 -and $Force -ne $True)
        {
            Write-Host "The table below are the resource types that support sending diagnostics to Event Hub"
            $DiagnosticCapable | select "#", ResourceType, Metrics, Logs |ft
            try
            {
                $ResourceTypeToProcess = Read-Host "Please select a number from 1 - $($DiagnosticCapable.count) to enable (""True"" = supported configuration)"
            }
            catch
            {
                Write-Warning -Message 'Invalid option, please try again.'
            }
        }
        $ResourceType = $DiagnosticCapable[$ResourceTypeToProcess -1].ResourceType
        # Find all resources for $ResourceType defined
        $Resources = $ResourcesToCheck.where({$_.ResourceType -eq $ResourceType})
    }
    catch
    {
        Throw "No diagnostic capable resources available in selected subscription $SubscriptionID"
    }
}

# Convert string to array 
if($CategoriesChosen)
{
    # Trim spaces out
    $CategoriesChosen = $CategoriesChosen.replace(" ","")
    
    # Define our array of log categories
    [array]$Logcategories = ($CategoriesChosen -split ",")
}

# Validate customer wants to continue to update all resources in ResourceType selected
# If Force used, will update without prompting
if ($Force -OR $PSCmdlet.ShouldContinue("This operation will update $($Resources.Count) $ResourceType resources in your subscription. Continue?",$ResourceType) )
{
        Write-Host "Configuring $($Resources.Count) [$ResourceType] resources in your subscription." 
        Set-Resource -Resources $Resources -Update:$Update -EHID $EHID `
            -DiagnosticCapability $DiagnosticCapable[$ResourceTypeToProcess -1] `
            -EHRegion $EHRegion
        Write-Host "Complete" -ForegroundColor Cyan
}
else
{
        Write-Host "You selected No - exiting"
        Write-Host "Complete" -ForegroundColor Cyan
}