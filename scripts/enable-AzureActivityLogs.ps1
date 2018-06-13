<#PSScriptInfo

.VERSION 1.0

.GUID 4e2be68a-f71d-4442-881c-edb7f10bde77

.AUTHOR jbritt@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
  May 1, 2018
  Initial Release

#>

<#  
.SYNOPSIS  
  Configure a subscription or series of subscriptions to send their Azure Activity Logs to a Log Analytics Workspace or
  Event Hub Rule ID for analysis.
  
  Use of Silent switch "-Silent" runs the script without prompting, if all required parameters are provided.

.DESCRIPTION  
  This script takes a SubscriptionID, and either an EventHub Rule ID or an Log Analytics ResourceID as parameters, 
  to enabling Azure Activity Logs to be sent for selected subscriptions to either sink point.

.PARAMETER Silent
    Specify silet if you want to execute the script without prompting

.PARAMETER WSRESOURCEID    
    The resourceID of your OMS workspace within Azure

.PARAMETER SubId
    The subscriptionID of the Azure Subscription that contains the Azure Activity Logs 
    (this can be a single value or an array)

.PARAMETER EHID
    The Event Hub RuleID of the target Event Hub to store Azure Activity Logs 

.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -WSRESOURCEID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/OI-EAST-USE/providers/Microsoft.OperationalInsights/workspaces/OMSWS" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512"
  Take in parameters for WSRESOURCEID and SubscriptionID and prompts for confirmation

.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -WSRESOURCEID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/OI-EAST-USE/providers/Microsoft.OperationalInsights/workspaces/OMSWS" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -Silent
    Take in parameters for WSRESOURCEID and SubscriptionID and executes silently without prompting

.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512"
  Take in parameters for EventHub RuleID and SubscriptionID and prompts for confirmation

.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -Silent
    Take in parameters for EventHub RuleID and SubscriptionID and executes silently without prompting
  
.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -SubID $(Get-Content -Path C:\Temp\subscriptions.txt) -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey"
    Leverage this example to provide a text file of subscription IDs (one per line) in a txt file and configure
    each subscription's activity logs to be sent to the specified EventHub RuleID.

.\enable-AzureActivityLogs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey"
    Leverage this example to provide gather a list of subscription to process and configure (from currently authenticated user
    context).  Each subscription's activity logs will to be sent to the specified EventHub RuleID.

.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -SubID $(Get-Content -Path C:\Temp\subscriptions.txt) -WSRESOURCEID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/OI-EAST-USE/providers/Microsoft.OperationalInsights/workspaces/OMSWS"
    Leverage this example to provide a text file of subscription IDs (one per line) in a txt file and configure
    each subscription's activity logs to be sent to the specified Log Analytics Workspace (Resource ID).

.\enable-AzureActivityLogs.ps1 -WSRESOURCEID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/OI-EAST-USE/providers/Microsoft.OperationalInsights/workspaces/OMSWS"
    Gather a list of subscriptions to process and configure (from currently authenticated user context).
    Each subscription's activity logs will to be sent to the specified Log Analytics Workspace (Resource ID).

.EXAMPLE
  .\enable-AzureActivityLogs.ps1 -Verbose
  To Support Verbose log Output

.NOTES
   AUTHOR: Jim Britt Senior Program Manager - AzureCAT 
   LASTEDIT: May 1, 2018

    Initial Release

.LINK
    This script posted to and discussed at the following locations:
#>

Param
(
    [parameter(Mandatory=$true,
    ParameterSetName="EHID")]
    $EHID,

    [parameter(Mandatory=$true,
    ParameterSetName="WSRESOURCEID")]
    $WSRESOURCEID,

    [Parameter(Mandatory=$False)][array]$SubID,
    [Parameter(Mandatory=$False)][Switch]$Silent
)

# Function used to build numbers in tables
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

function AuthToAzure
{
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
}

function ValidateID
{
    param
    (
        [Parameter(Mandatory=$False)]$EHID,
        [Parameter(Mandatory=$False)]$WSRESOURCEID,
        [Parameter(Mandatory=$False)]$SubID

    )
    # Function to validate EHID, WSRESOURCEID, SUBID 
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
    IF($WSRESOURCEID)
    {
        $cnt = $($WSRESOURCEID.Split("/").Count+1)
        if($($WSRESOURCEID.Split("/", $Cnt)[1]) -eq "Subscriptions" -and
        $($WSRESOURCEID.Split("/", $Cnt)[6]) -eq "Microsoft.OperationalInsights" -and
        $cnt -eq 10)
        
        {
            # Valid Workspace Resource ID
            $ValidID = $True
        }
        
        else
        {
            write-host "Invalid value passed to WSRESOURCEID" -ForegroundColor Red
            $ValidID = $False
        }

    }
    if($SubID)
    {
        [guid]$GUIDVAR = $SubID
        If($GUIDVAR)
        {
            $ValidID = $True
        }
        Else
        {
            $ValidID = $False
            write-host "Invalid value passed to SubID" -ForegroundColor Red

        }
    }
    $ValidID
}
# MAIN SCRIPT
#Test the ID for EventHub Rule ID or ResourceID for Workspace ID for proper format
If($EHID)
{
    $ValidID = ValidateID -EHID $EHID
}

If($WSRESOURCEID)
{
    $ValidId = ValidateID -WSRESOURCEID $WSRESOURCEID
}

If($ValidID)
{
    # Ensure you are logged in
    $Auth = AuthToAzure

    if($SubID.count -eq 1)
    {
        $ValidID = ValidateID -SubID $SubID[0]
        if($ValidID)
        {
            # Below line to go against one subscription
            $subs = get-AzureRmSubscription -SubscriptionId $SubID[0]
        } 
    }
    elseif($SubID.count -eq 0)
    {
        # Below line to go against all subscriptions
        $subs = get-azurermsubscription | Where-Object{$_.Name -eq "jbritt"}
    }
    elseif($SubID.Count -gt 1)
    {
        $SUBS = @()
        $Count = 0
        $ValidSubID = $True
        while($ValidSubID -eq $True -and $SubID.count -gt $Count)
        {
            Foreach($Sub in $SubID)
            {
                $ValidSubID = ValidateID -SubID $Sub
                if($ValidSubID)
                {
                    $MyObj = New-Object System.Object
                    Add-Member -InputObject $MyObj -Name "ID" -Value ($Sub) -MemberType NoteProperty 
                    $Subs = $Subs + $Myobj
                    $count++
                }
            }
            $ValidID = $ValidSubID
            #$Subs
        }
    }

    If($Subs.count -gt 1 -and !$Silent -and $ValidID)
    {
        If($PSCmdlet.ShouldContinue("This operation will configure Activity Logs in ALL $($Subs.Count) subscriptions in your AD tenant. Continue?", "Configure All Subscriptions"))
        {
            $Ready = $True
        }
        Else
        {
            $Ready = $False
        }
    }
    If($Subs.count -eq 1 -and !$Silent -and $ValidID)
    {
        If($PSCmdlet.ShouldContinue("This operation will configure Activity Logs in the $($Subs[0].Name) subscription. Continue?", "Update $($Subs.Name)?"))
        {
            $Ready = $True
        }
        Else
        {
            $Ready = $False
        }
    }
    If(($Ready -or $Silent) -and $ValidID)
    {
        If($EHID)
        {
            # Build Locations
            $locations = (Get-AzureRmLocation).Location
            # Add Global since it is not returned by default
            $locations += "global"

            # Build a table to represent configuration state
            $logProfiles = @()
            Write-Host "Starting configuration for Activity Logs to Event Hub"
            foreach ($sub in $subs)
            {
                try
                {
                    $Error.Clear()
                    $SelectedActityLogSub = Get-AzureRmSubscription -SubscriptionId $sub.id -ErrorAction Stop
                    Write-Host "Updating " -NoNewline -ForegroundColor Cyan
                    write-Host " $($SelectedActityLogSub.Name) " -NoNewline -ForegroundColor Yellow
                    Write-Host " subscription to send Azure Activity Logs to EventHub" -ForegroundColor Cyan

                    $ProfileConfig = Add-AzureRmLogProfile -Name default -serviceBusRuleId $EHID -Locations $locations `
                        -RetentionInDay 90 -Categories Write,Delete,Action

                    $logProfiles += $ProfileConfig | Select @{Label ="Subscription";`
                        Expression = {$SelectedActityLogSub.Name}}, @{Label = "Enabled";Expression = {$_.RetentionPolicy.Enabled}}
                }
                catch
                {
                    $PSObject = New-Object psobject
                    Write-Host "Error Updating subscription " -NoNewline -ForegroundColor Red
                    Write-Host $Sub.ID -ForegroundColor Yellow
                    Write-Verbose $Error.Exception.Message
                    $PSObject | Add-Member NoteProperty Subscription $Sub.id
                    $PSObject | Add-Member NoteProperty Enabled "Error"
                    $logProfiles += $PSObject
                }
            }
            $BuildTable = Add-IndexNumbertoArray ($logProfiles) 
            $logProfiles | select "#", Subscription, Enabled | ft

        }
        If($WSRESOURCEID)
        {
            $SplitCnt = $($WSRESOURCEID.Split("/").Count+1)
            $RG = $($WSRESOURCEID.Split("/", $SplitCnt)[4])
            $WKSPACE = $($WSRESOURCEID.Split("/", $SplitCnt)[8])
            $WorkspaceSubID = $($WSRESOURCEID.Split("/", $SplitCnt)[2])

            # Build a table to represent configuration state
            $logProfiles = @()
            Write-Host "Starting configuration for all Activity Logs to Log Analytics Workspace: $WKSPACE"
            $SelectedSub = Select-AzureRmSubscription $WorkspaceSubID
            foreach ($sub in $subs)
            {
                try
                {
                    $error.Clear()
                    $SelectedActityLogSub = Get-AzureRmSubscription -SubscriptionId $sub.id -ErrorAction Stop
                    Write-Host "Updating " -NoNewline -ForegroundColor Cyan
                    write-Host " $($SelectedActityLogSub.Name) " -NoNewline -ForegroundColor Yellow
                    Write-Host " subscription to send Azure Activity Logs to Log Analytics" -ForegroundColor Cyan
                    $ProfileConfig = New-AzureRmOperationalInsightsAzureActivityLogDataSource -WorkspaceName $WKSPACE `
                        -ResourceGroupName $RG -SubscriptionId $SelectedActityLogSub.Id -Name $SelectedActityLogSub.id -Force
    
                    $logProfiles += $ProfileConfig | Select @{Label ="Subscription";`
                        Expression = {$SelectedActityLogSub.Name}}, WorkspaceName, @{Label = "Enabled";Expression = {if($_.Kind -eq "AzureActivityLog"){$true}}}
                }
                catch
                {
                    $PSObject = New-Object psobject
                    Write-Host "Error Updating subscription " -NoNewline -ForegroundColor Red
                    Write-Host $Sub.ID -ForegroundColor Yellow
                    Write-Verbose $Error.Exception.Message
                    $PSObject | Add-Member NoteProperty Subscription $Sub.id
                    $PSObject | Add-Member NoteProperty WorkspaceName $WKSPACE
                    $PSObject | Add-Member NoteProperty Enabled "Failed"                    
                    $logProfiles += $PSObject
                }
            }
            $BuildTable = Add-IndexNumbertoArray ($logProfiles) 
            $logProfiles | select "#", WorkspaceName, Subscription, Enabled | ft
        }
    }
    Else
    {
        Write-Host "Operation Cancelled!" -ForegroundColor Red
    }
}

if(!$ValidID)
{
    Write-host "Either Event Hub RuleID, SubscriptionID or ResourceID for Workspace is not in the proper format" -ForegroundColor Yellow
    #write-host "Ex: /subscriptions/<SubID>/resourcegroups/<RG>/providers/microsoft.operationalinsights/workspaces/<WSName>" -ForegroundColor Cyan 
}
