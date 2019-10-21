#######################################################################################################################
########### This script sets diagnostic settings to all NSGs in a subscription that you select. It adds the ###########
########### Log Analytics workspace and storage accounts.                                                   ###########
#######################################################################################################################

#Check for required modules, install if necessary.

$AZMod = "Az.Accounts"
$AZNet = "Az.Network"

Write-Host "Checking for the Az module. Any required module will be installed. Please ensure that the exectution is set to RemoteSigned or Unrestricted." -ForegroundColor Cyan

If (Get-Module -ListAvailable -Name $AZMod) { Write-Host $AZMod "module is installed" -ForegroundColor Cyan }
else { Install-Module Az }

If (Get-Module -ListAvailable -Name $AzNet | where Version -EQ 1.12.0) { Write-Host $AzNet "moudle is installed" -ForegroundColor Cyan }
else { Install-Module Az.Network -RequiredVersion 1.12.0 }

Start-Sleep -Seconds 6

# Login to Azure and slelect a subscription. Change the enviroment name to meet your cloud needs.

Login-AzAccount -Environment AzureCloud
$subscriptionId = (Get-AzSubscription | Out-GridView -Title "Select the preferred Azure Subscription and click OK" -PassThru).SubscriptionId
Get-AzSubscription -SubscriptionId $subscriptionId | Select-AzSubscription

# Import Modules

Import-Module Az.Accounts
Import-Module Az.Network -RequiredVersion 1.12.0
Import-Module Az.OperationalInsights


#######################################################################################################################
########## Variables ##################################################################################################
#######################################################################################################################

# Path and file name for export log of changed NSGs

$DataOut = "C:\AzureNSG\DiagnosticsOutput.txt"

# Add the target workspace here.

$WS = "MyWorkspace"

# Test if variable is not null.

If ($WS -ne "") { Write-Host "The" $WS "workspace has beed loaded." -ForegroundColor Cyan }
else { Write-Host "The target Log Analytics workspace is not loaded in the WS variable above." -ForegroundColor DarkRed }
Start-Sleep -Seconds 2

# Add the target resource group here.

$WSRG = "TargetResourceGroup"

# Test if variable is not null.

If ($WSRG -ne "") { Write-Host "The" $WSRG "resouce group has been loaded."  -ForegroundColor Cyan }
else { Write-Host "The target Resource Group is not loaded in the WSRG variable above." -ForegroundColor DarkRed }
Start-Sleep -Seconds 2

# Assemble/Preload the Log Analytics Workspace.

$LAWS = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WSRG -Name $WS

# Test if variable is not null.

If ($LAWS -ne "") { Write-Host "The complete workspace has been loaded." -ForegroundColor Cyan }
else { Write-Host "The target Log Analytcs setting has not been assembled correctly. Please review the WS and/or the WSRG variables above." -ForegroundColor DarkRed }
Start-Sleep -Seconds 2

#######################################################################################################################
########## Important - The location must be in the same regions as the Storage Account that you want to use. ##########
#######################################################################################################################

# Add the location where the target NSGs exist, example eastus.

$loc = "eastus"

# Test if variable is not null.

If ($loc -ne "") { Write-Host "The" $loc "location has been loaded." -ForegroundColor Cyan }
else { Write-Host "The location is not loaded in the loc variable above." -ForegroundColor DarkRed }

#######################################################################################################################
########## Important - The Storage Account used must be in the same region as the NSG. If you do not want to ##########
########## add a storage account then simple comment out the DiagnosticsStorage variable and remove the ###############
########## -StorageAccountId $DiagnosticsStorage from the If loop below. ##############################################
#######################################################################################################################

# Enter Archive Storage ID here.

$DiagnosticsStorage = "/subscriptions/SUBID/resourceGroups/MyResourceGroup/providers/Microsoft.Storage/storageAccounts/mystorage"

# Test if variable is not null.

If ($DiagnosticsStorage -ne "") { Write-Host "The" $DiagnosticsStorage "storage has been loaded." -ForegroundColor Cyan }
else { Write-Host "The target stroage ID is not loaded in the DiagnosticsStorage variable above." -ForegroundColor DarkRed }

# Pre load the NSGs.

$Nsg = Get-AzNetworkSecurityGroup | where location -e $loc

# Test if variable is not null.

If ($Nsg -ne "") { Write-Host "The NSGs have been loaded." -ForegroundColor Cyan }
else { Write-Host "The loc is not loaded in the loc variable above." -ForegroundColor DarkRed }

# Apply the diagnostics settings to all of the NSGs in the Subscription selected.

foreach ($nsg in $nsg) {

    # Create the Service Name for Daignostics. The RetentionInDays is set for 365, change it to fit your needs.

    $ServiceName = $Nsg.name + "-Diag" | Out-String

    Set-AzDiagnosticSetting -Name $ServiceName -ResourceId $Nsg.id -WorkspaceId $LAWS.ResourceId -Enabled $true -StorageAccountId $DiagnosticsStorage -RetentionInDays 365
    Write-Host $Nsg.name "Has been set." -ForegroundColor Cyan
    $Nsg.name | out-file -filepath $DataOut -append
}
Write-Host "The Log file with the list of changed NSGs is located here" $DataOut
Write-Host "The script has completed execution." -ForegroundColor Yellow