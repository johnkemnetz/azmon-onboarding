# Azure Monitor Onboarding Guide

This guide is intended to help Azure customers attempting to setup monitoring on a large Azure environment get set up and maintain that state over time.

## Introduction
As the breadth of Azure’s service offerings increases and the size of your Azure environment grows, the pain of onboarding that environment to a new monitoring tool increases too. Particularly when onboarding a large number of Azure resources to Log Analytics or a 3rd party SIEM tool, it can be cumbersome to have to set up monitoring resource-by-resource, and an ongoing challenge to keep things set up as resources are created and deleted. To help alleviate some of that pain, we’ve put together this guide to help you with these two situations:
* You want to rapidly connect a large Azure environment to Log Analytics and want all resources (including Virtual Machines) to send log and metric data to your Log Analytics workspace. Once you’ve done that, you want to make sure that any new resources are automatically set up to do this for you.
* You want to rapidly connect a large Azure environment to a 3rd party SIEM tool and you want all resources to send log data to an Event Hubs namespace, where it can be consumed by a SIEM connector. Once you’ve done that, you want to make sure that any new resources are automatically set up to do this for you.

For either situation, the basic steps are the same:

1. Enable an Azure Policy initiative or individual policies to ensure that any new resource is automatically setup when it is created (often called “greenfield” enablement).
2. Run a script to set things up on existing resources (often called “brownfield” enablement).

...and that’s it! The rest of this guide walks through this process in detail.

## Send data to Log Analytics


## Send data to Event Hubs
