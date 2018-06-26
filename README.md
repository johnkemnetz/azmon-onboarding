# Azure Monitor Onboarding Guide

This guide is intended to help Azure customers attempting to setup monitoring on a large Azure environment get set up and maintain that state over time.

## Introduction
As the breadth of Azure’s service offerings increases and the size of your Azure environment grows, the pain of onboarding that environment to a new monitoring tool increases too. Particularly when onboarding a large number of Azure resources to [Log Analytics](http://aka.ms/ladocs) or a [3rd party SIEM tool](http://aka.ms/azmoneventhub), it can be cumbersome to have to set up monitoring resource-by-resource, and an ongoing challenge to keep things set up as resources are created and deleted. To help alleviate some of that pain, we’ve put together this guide to help you with these two situations:
* You want to rapidly connect a large Azure environment to Log Analytics and want all resources (including Virtual Machines) to send log and metric data to your Log Analytics workspace. Once you’ve done that, you want to make sure that any new resources are automatically set up to do this for you.
* You want to rapidly connect a large Azure environment to a 3rd party SIEM tool and you want all resources to send log data to [an Event Hubs namespace, where it can be consumed by a SIEM connector](http://aka.ms/azmoneventhub). Once you’ve done that, you want to make sure that any new resources are automatically set up to do this for you.

For either situation, the basic steps are the same:

1. Enable an Azure Policy initiative or individual policies to ensure that any new resource is automatically setup when it is created (often called “greenfield” enablement).
2. Run a script to set things up on existing resources (often called “brownfield” enablement).

...and that’s it! The rest of this guide walks through this process in detail.

## Send data to Log Analytics
This guide shows you how to set up Log Analytics to monitor two types of Azure data:

* **Virtual Machines** - For Azure Resource Manager virtual machines, you install the OMS agent on either [Linux](https://docs.microsoft.com/azure/virtual-machines/extensions/oms-linux) or [Windows](https://docs.microsoft.com/azure/virtual-machines/extensions/oms-windows) using the Azure VM extensions and include the OMS workspace ID and key in the VM extension settings.
* **Azure Resource Diagnostic Logs** - For [Azure Resource Diagnostic Logs](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-overview-of-diagnostic-logs), you create a Resource Diagnostic Setting on the resource you want to send the data, and [specify the OMS workspace where you want the data to go](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitor-stream-diagnostic-logs-log-analytics).
* **Azure Activity Log** - For [the Azure Activity Log](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-overview-activity-logs), you [enable the Log Analytics connector to an Azure subscription](https://docs.microsoft.com/azure/log-analytics/log-analytics-activity#configuration).

### Step 1: Setup policy for greenfield enablement

[TODO]

### Step 2: Run scripts for brownfield enablement
Before you begin, make sure that you have:
  1. [Installed the latest Azure PowerShell module](https://docs.microsoft.com/powershell/azure/install-azurerm-ps).
  2. Given appropriate permissions for the script to run. The safest way to do this is by running the script in a PowerShell process that has the RemoteSigned execution policy.

```powershell
  
  powershell.exe -ExecutionPolicy RemoteSigned
  
```

  [You can learn more here.](https:/go.microsoft.com/fwlink/?LinkID=135170)
  3. Downloaded the scripts from the PowerShell Gallery:
    * [Enable-AzureDiagnostics](https://www.powershellgallery.com/packages/Enable-AzureDiagnostics/1.0/DisplayScript). You can do this simply by typing `Install-Script -Name Enable-AzureDiagnostics`.
    * [Enable-AzureActivityLogs]() [TODO]
    * [TODO script for vm extensions]

You can also manually download the scripts from the **scripts** folder in this repo.

Once you have the scripts installed and have verified that you have the correct execution policy setup to run the script, you can simply execute the scripts.

#### Enable-AzureRmDiagnostics
This script enables Azure resource diagnostic settings on your Azure resources to route them to a particular Log Analytics workspace. To run it, type `.\Enable-AzureRMDiagnostics.ps1`. This prompts you for details like the resource ID of the workspace data should be sent to, the resource types and log categories of data that should be sent, and the scope (subscription/resource groups) of enablement. You can also run the command silently without promts by providing these details as parameters:

```powershell

  .\Enable-AzureRMDiagnostics.ps1 -WSID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/OI-EAST-USE
    /providers/Microsoft.OperationalInsights/workspaces/OMSWS" -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512"
    -ResourceType "Microsoft.Sql/servers/databases" -ResourceGroup "RGName" -Force
    
```

To learn more about the parameters and available options for executing this script, just type ` Get-Help .\Enable-AzureRMDiagnostics.ps1 -detailed`.

#### Enable-AzureActivityLogs
This script enables the Activity Log connector for a Log Analytics workspace on selected subscriptions. To run it, type `./Enable-AzureActivityLogs.ps1`. This prompts you for details like the subscription ID and resource ID of the workspace where you want data to end up. You can also run the command silently without prompts by providing these details as parameters:

```powershell

  .\enable-AzureActivityLogs.ps1 -WSRESOURCEID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGr
    oups/OI-EAST-USE/providers/Microsoft.OperationalInsights/workspaces/OMSWS" -Silent
    
```

Without providing a subscription ID, the script enables collection of the Activity Log on all subscriptions to which the logged in user has access. There's also an option to provide a list of subscription IDs on which you'd like to enable the Activity Log connector as input to the script:

```powershell

  .\enable-AzureActivityLogs.ps1 -SubID $(Get-Content -Path C:\Temp\subscriptions.txt) -WSRESOURCEID "/subscri
    ptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/OI-EAST-USE/providers/Microsoft.OperationalInsights/work
    spaces/OMSWS"
    
```

To learn more about the parameters and available options for executing this script, just type ` Get-Help .\Enable-AzureActivityLogs.ps1 -detailed`.

#### [TODO Script for VMs]

## Send data to Event Hubs
This guide shows you how to set up Azure Monitor to send data to SIEMs for two types of Azure data:

* **Azure Resource Diagnostic Logs** - For [Azure Resource Diagnostic Logs](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-overview-of-diagnostic-logs), you create a Resource Diagnostic Setting on the resource you want to send the data, and [specify the Event Hubs namespace where you want the data to end up](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-stream-diagnostic-logs-to-event-hubs).
* **Azure Activity Log** - For [the Azure Activity Log](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-overview-activity-logs), you create a Subscription Diagnostic Setting on the subscription from which you want the Activity Log data to be sent, and [specify the Event Hubs namespace where you want the data to end up](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-stream-activity-logs-event-hubs).

You can also send other types of Azure Monitor data to Event Hubs by [setting them up manually](http://aka.ms/azmoneventhub).

### Step 1: Setup policy for greenfield enablement

[TODO]

### Step 2: Run scripts for brownfield enablement
Before you begin, make sure that you have:
  1. [Installed the latest Azure PowerShell module](https://docs.microsoft.com/powershell/azure/install-azurerm-ps).
  2. Given appropriate permissions for the script to run. The safest way to do this is by running the script in a PowerShell process that has the RemoteSigned execution policy.

```powershell
  
  powershell.exe -ExecutionPolicy RemoteSigned
  
```

  [You can learn more here.](https:/go.microsoft.com/fwlink/?LinkID=135170)
  3. Downloaded the scripts from the PowerShell Gallery:
    * [Enable-AzureRMDiagnosticsEventHubs](). [TODO] You can do this simply by typing `Install-Script -Name Enable-AzureDiagnostics`.
    * [Enable-AzureActivityLogs]() [TODO]
    * [TODO script for vm extensions]

You can also manually download the scripts from the **scripts** folder in this repo.

Once you have the scripts installed and have verified that you have the correct execution policy setup to run the script, you can simply execute the scripts.

#### Enable-AzureRmDiagnosticsEventHubs
This script enables Azure resource diagnostic settings on your Azure resources to route them to a particular event hubs namespace. To run it, type `.\Enable-AzureRMDiagnosticsEventHubs.ps1`. This prompts you for details like the event hubs namespace where data should be sent to, the resource types and log categories of data that should be sent, and the scope (subscription/resource groups) of enablement. You can also run the command silently without promts by providing these details as parameters:

```powershell

  .\Enable-AzureRMDiagnosticsEventHubs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resource
    Groups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey"
    -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceType "Microsoft.Sql/servers/databases"
    -ResourceGroup "RGName" -Force
    
```

To learn more about the parameters and available options for executing this script, just type ` Get-Help .\Enable-AzureRMDiagnostics.ps1 -detailed`.

#### Enable-AzureActivityLogs
This script enables Log Profiles to send Activity Log data from subscriptions to an event hubs namespace. To run it, type `./Enable-AzureActivityLogs.ps1`. This prompts you for details like the subscription ID and event hubs namespace where you want data to end up. You can also run the command silently without prompts by providing these details as parameters:

```powershell

  .\enable-AzureActivityLogs.ps1 -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey" -Silent
    
```

Without providing a subscription ID, the script enables collection of the Activity Log on all subscriptions to which the logged in user has access. There's also an option to provide a list of subscription IDs on which you'd like to enable the Log Profile as input to the script:

```powershell

  .\enable-AzureActivityLogs.ps1 -SubID $(Get-Content -Path C:\Temp\subscriptions.txt) -EHID "/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/resourceGroups/EH-EAST-USE/providers/Microsoft.EventHub/namespaces/EH001/AuthorizationRules/RootManageSharedAccessKey"
    
```

To learn more about the parameters and available options for executing this script, just type ` Get-Help .\Enable-AzureActivityLogs.ps1 -detailed`.


## Additional Considerations
Before using the steps above, we recommend carefully considering the cost and scalability of onboarding. Below are some limitations and scale considerations to be aware of.

### Azure Resource Manager limitations
[This document](https://docs.microsoft.com/azure/azure-subscription-service-limits#subscription-limits) describes subscription-wide Azure Resource Manager limits. Most noteably among these are the subscription limits for *Resource Manager API Reads* and *Resource Manager API Writes*. The scripts provided execute both read and write resource manager API calls in your subscriptions, and in larger subscriptions (over 1,200 resources) you may have to run the script, multiple times over the course of a few hours to update all your existing resources.

### Log Analytics workspace limitations
[This document](https://docs.microsoft.com/azure/azure-subscription-service-limits#log-analytics-limits) describes workspace limitations for Log Analytics. Outside of the Free tier, you should not encounter limits in terms of data ingestion.

[Note also the regional support for Log Analytics](https://azure.microsoft.com/global-infrastructure/services/). While you can route data across regions into Log Analytics, you should consider the [geographic data residency, sovereignty, compliance, and resiliency requirements](https://azure.microsoft.com/global-infrastructure/geographies/).

### Event Hubs limitations
There are some [restrictions on the number of event hubs per namespace](https://docs.microsoft.com/azure/azure-subscription-service-limits#event-hubs-limits). It is also important to consider the throughput units neeeded and possibly set up [autoscale for Event Hubs throughput units](https://docs.microsoft.com/azure/event-hubs/event-hubs-auto-inflate). You can also learn more about [event hubs availability and consistency](https://docs.microsoft.com/azure/event-hubs/event-hubs-availability-and-consistency).

## Next Steps
Once you've done both greenfield and brownfield enablement across your environment, we suggest you get more familiar with the services and functionality that were used above. This will help if you ever need to customize, modify, or undo the enablement you did in the previous steps. Here are some helpful links for further understanding:

* **Azure Policy** - The Azure Policy service allows you to better govern your Azure environment by creating sets of rules that will be enforced across a scope. These rules can have a variety of ways that they are enforced, eg. by preventing users from violating the rule ("no SQL databases in East US"), automatically rectifying the violation ("make sure there's a setting deployed with each NSG"), or auditing the violation ("proceed, but let me know if someone didn't add a tag when creating a VM"). The rules you create are referred to as a *policy definition* and when you apply that definition to a scope of resources, you create a *policy assignment*. In many cases, a group of policy definitions are bundled together in a *policy initiative*. [You can learn more about Azure Policy and get started creating policies of your own here](https://docs.microsoft.com/azure/azure-policy/azure-policy-introduction).
* **Azure Monitor Diagnostic Settings** - Azure Monitor Diagnostic Settings control *what monitoring data you want to collect* and *where you want that data to go*. They are always associated with one specific Azure resource, and the type of data you can collect will depend on the Azure resource type. Diagnostic Settings enable you to route data to a storage account, event hub, or Log Analytics workspace from Azure resources where you couldn't install an agent to collect the data, eg. a Network Security Group or Key Vault. [You can learn more about Azure Monitor Diagnostic Settings and Diagnostic Logs here.](https://docs.microsoft.com/azure/monitoring-and-diagnostics/monitoring-overview-of-diagnostic-logs)
* **Azure PowerShell** - The AzureRM modules for PowerShell enable you to interact with Azure Resource Manager using PowerShell. You can create, update, and delete resources and manage your Azure environment. The PowerShell modules can be installed on your own machine, or you can log on to the portal and use [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/overview), which has a pre-configured Azure PowerShell environment without the need to install anything on your machine. [You can learn more about the Azure PowerShell cmdlets and how to install them here.](https://docs.microsoft.com/powershell/azure/overview)

## Feedback and Questions
Feel free to sumbit a PR if you have improvements to the scripts or documentation provided here. If you have questions or feedback, use the GitHub issues page.
