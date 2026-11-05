#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys the CA Policy Framework (Import-CAPolicyFrameworkV2.ps1) as Microsoft Entra
    Conditional Access V2 policy plans. Every V1 policy of the framework becomes one rule;
    no policy is consolidated, merged or removed.

.DESCRIPTION
    The script creates seven policy plans through the Microsoft Graph beta endpoint
    /identity/conditionalAccess/plans and adds the 26 framework policies as rules:

      PLN-01 Baseline access - all users            9 rules  (BAS-001/002/003/004/007/008/010/011/012)
      PLN-02 Identity and insider risk - all users  4 rules  (BAS-005/006/009, PER-008)
      PLN-03 Data protection - CHC applications     3 rules  (DLP-001/002/003)
      PLN-04 Privileged roles                       4 rules  (PER-002/003/004/005)
      PLN-05 Privileged access workstations         2 rules  (PER-001/006)
      PLN-06 Guest and external access              3 rules  (DLP-004, PER-009/010)
      PLN-07 Workload identities                    1 rule   (PER-007)

    Conditions that are identical for every rule of a plan are configured once as the
    plan's shared conditions (sharedConditions). All other conditions, exclusions, grant
    controls and session controls stay on the individual rule exactly as in the V1 script.
    Use -NoSharedConditions to keep the full V1 conditions on every rule instead.

    The script is idempotent: existing plans are detected by display name, and only rules
    that are missing in an existing plan are added. Existing V1 policies are not changed.

    Prerequisites created by Import-CAPolicyFrameworkV2.ps1 (named locations, secure
    workstation group, custom security attributes) are looked up and, where reasonable,
    created if they are missing.

.PARAMETER BreakGlassUpn
    UPNs of the emergency-access accounts excluded from every user-based rule.
    If omitted, the script detects accounts whose UPN starts with BreakGlass, bg-, emrg- or
    emergency- and asks for confirmation.

.PARAMETER RuleState
    State for all created rules. Default: enabledForReportingButNotEnforced (Report-only),
    which matches the V1 framework.

.PARAMETER NoSharedConditions
    Keep the complete V1 conditions on every rule and leave sharedConditions empty.

.PARAMETER ExportPath
    Writes the plan and rule definitions as JSON to this folder. Combine with -ExportOnly to
    review the definitions without changing the tenant.

.PARAMETER ExportOnly
    Builds and exports the definitions only. No plan or rule is created.
    Without a Graph connection, placeholder IDs are used for tenant-specific objects.

.EXAMPLE
    .\Import-CAPolicyFrameworkV2-PolicyPlans.ps1 -BreakGlassUpn 'BreakGlass1@contoso.com','BreakGlass2@contoso.com'

.EXAMPLE
    .\Import-CAPolicyFrameworkV2-PolicyPlans.ps1 -ExportOnly -ExportPath .\plans

.NOTES
    Version : 1.0
    Based on: Import-CAPolicyFrameworkV2.ps1 v2.2 (AzFrameworks/CAPolicyFramework)
    API     : Microsoft Graph beta - conditionalAccessPolicyPlan / conditionalAccessPolicyRule.
              APIs under /beta are subject to change and are not supported for production use.

AUTHOR
    Daniel Metzger

DISCLAIMER
    This script is provided "AS IS" without warranty of any kind, express or implied,
    including but not limited to warranties of merchantability, fitness for a particular
    purpose, and non-infringement. Use of this script is entirely at your own risk.

    The author, Daniel Metzger, makes no representations or warranties regarding the
    accuracy, completeness, or suitability of this script for any specific environment
    or use case. The author accepts no liability for any direct, indirect, incidental,
    special, or consequential damages arising from the use or inability to use this
    script, including but not limited to:

      - Unintended lockout of users or administrators from Microsoft Entra ID
      - Misconfiguration of Conditional Access policies or policy plans
      - Data loss, service disruption, or security incidents
      - Non-compliance with organizational, legal, or regulatory requirements

    Always test in a dedicated non-production tenant before deploying to any production
    environment. Review every plan and every rule thoroughly before transitioning from
    Report-only to Enabled state. V1 policies and V2 policy plan rules are evaluated
    concurrently: while both coexist in a tenant, every applicable condition of both
    must be satisfied.

    Nothing in this script constitutes legal, security, or compliance advice.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]] $BreakGlassUpn,
    [ValidateSet('enabledForReportingButNotEnforced', 'enabled', 'disabled')]
    [string]   $RuleState = 'enabledForReportingButNotEnforced',
    [switch]   $NoSharedConditions,
    [string]   $ExportPath,
    [switch]   $ExportOnly
)

$ErrorActionPreference = 'Stop'
$plansUri = 'https://graph.microsoft.com/beta/identity/conditionalAccess/plans'

#region Helper functions

function Write-Step { param([string]$Text) Write-Host "`n== $Text" -ForegroundColor Cyan }

function Get-GraphErrorText {
    param($ErrorRecord)
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) { return $ErrorRecord.ErrorDetails.Message }
    return $ErrorRecord.Exception.Message
}

function Get-AllPages {
    param([string]$Uri)
    $items = @()
    while ($Uri) {
        $r = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
        if ($r.value) { $items += $r.value }
        $Uri = $r.'@odata.nextLink'
    }
    return $items
}

function Get-UserIdByUpn {
    param([string]$Upn)
    try {
        (Invoke-MgGraphRequest -Method GET -OutputType PSObject `
            -Uri "https://graph.microsoft.com/v1.0/users/$([uri]::EscapeDataString($Upn))?`$select=id").id
    } catch { $null }
}

function Select-ExistingAppIds {
    # Rule creation fails with ServicePrincipalNotFound when an excluded app is not provisioned.
    param([string[]]$AppIds)
    foreach ($appId in $AppIds) {
        try {
            Invoke-MgGraphRequest -Method GET -OutputType PSObject `
                -Uri "https://graph.microsoft.com/v1.0/servicePrincipals(appId='$appId')?`$select=id" | Out-Null
            $appId
        } catch {
            Write-Host "    App $appId has no service principal in this tenant - not added to the exclusion." -ForegroundColor DarkGray
        }
    }
}

function Show-BreakGlassDialog {
    param([string[]]$Suggestions = @())
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing

    $form                 = [System.Windows.Forms.Form]::new()
    $form.Text            = 'Break-Glass Accounts — Required for Deployment'
    $form.Size            = [System.Drawing.Size]::new(460, 220)
    $form.StartPosition   = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox     = $false
    $form.MinimizeBox     = $false

    $lbl1          = [System.Windows.Forms.Label]::new()
    $lbl1.Text     = 'Break-Glass Account 1 (UPN):'
    $lbl1.Location = [System.Drawing.Point]::new(12, 14)
    $lbl1.Size     = [System.Drawing.Size]::new(420, 18)

    $txt1          = [System.Windows.Forms.TextBox]::new()
    $txt1.Location = [System.Drawing.Point]::new(12, 34)
    $txt1.Size     = [System.Drawing.Size]::new(420, 22)
    $txt1.Text     = if ($Suggestions.Count -ge 1) { $Suggestions[0] } else { '' }

    $lbl2          = [System.Windows.Forms.Label]::new()
    $lbl2.Text     = 'Break-Glass Account 2 (UPN):'
    $lbl2.Location = [System.Drawing.Point]::new(12, 68)
    $lbl2.Size     = [System.Drawing.Size]::new(420, 18)

    $txt2          = [System.Windows.Forms.TextBox]::new()
    $txt2.Location = [System.Drawing.Point]::new(12, 88)
    $txt2.Size     = [System.Drawing.Size]::new(420, 22)
    $txt2.Text     = if ($Suggestions.Count -ge 2) { $Suggestions[1] } else { '' }

    $btnOk              = [System.Windows.Forms.Button]::new()
    $btnOk.Text         = 'OK'
    $btnOk.Location     = [System.Drawing.Point]::new(252, 138)
    $btnOk.Size         = [System.Drawing.Size]::new(80, 28)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton  = $btnOk

    $btnCancel              = [System.Windows.Forms.Button]::new()
    $btnCancel.Text         = 'Cancel'
    $btnCancel.Location     = [System.Drawing.Point]::new(348, 138)
    $btnCancel.Size         = [System.Drawing.Size]::new(80, 28)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton      = $btnCancel

    $form.Controls.AddRange(@($lbl1, $txt1, $lbl2, $txt2, $btnOk, $btnCancel))
    $result = $form.ShowDialog()
    $form.Dispose()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return @($txt1.Text.Trim(), $txt2.Text.Trim()) | Where-Object { $_ }
}

function Copy-Deep {
    param($InputObject)
    # Round trip through JSON so that shared and rule conditions never share references
    if ($null -eq $InputObject) { return $null }
    ConvertTo-Json -InputObject $InputObject -Depth 20 | ConvertFrom-Json -AsHashtable -NoEnumerate
}

function Merge-Conditions {
    # Returns the full condition set of a rule: shared conditions plus rule-specific conditions.
    # Used for -NoSharedConditions and as fallback when a plan is rejected with shared conditions.
    param([hashtable]$Shared, [hashtable]$Rule)
    $result = Copy-Deep $Rule
    if (-not $Shared) { return $result }
    foreach ($key in $Shared.Keys) {
        if (-not $result.ContainsKey($key)) { $result[$key] = Copy-Deep $Shared[$key]; continue }
        if ($Shared[$key] -is [hashtable] -and $result[$key] -is [hashtable]) {
            foreach ($sub in $Shared[$key].Keys) {
                if ($result[$key].ContainsKey($sub)) {
                    # Exclusion and inclusion lists are combined (union)
                    $result[$key][$sub] = @(@($Shared[$key][$sub]) + @($result[$key][$sub]) | Select-Object -Unique)
                } else {
                    $result[$key][$sub] = Copy-Deep $Shared[$key][$sub]
                }
            }
        }
    }
    return $result
}

#endregion

#region Connection and prerequisites

$connected = $false
if (-not $ExportOnly) {
    foreach ($m in 'Microsoft.Graph.Authentication') {
        if (-not (Get-Module -ListAvailable -Name $m)) {
            Write-Host "Installing module $m..." -ForegroundColor Yellow
            Install-Module $m -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module $m
    }
    Write-Step 'Connecting to Microsoft Graph'
    try {
        Connect-MgGraph -NoWelcome -Scopes @(
            'Policy.Read.All'
            'Policy.ReadWrite.ConditionalAccess'
            'Application.Read.All'
            'User.Read.All'
            'Group.Read.All'
            'CustomSecAttributeDefinition.Read.All'
        )
    } catch {
        if ($_ -match 'InteractiveBrowserCredential' -or $_ -match 'WithLogging' -or $_ -match 'Method not found') {
            Write-Host ''
            Write-Host 'AUTHENTICATION FAILED — MSAL DLL VERSION CONFLICT' -ForegroundColor Red
            Write-Host ''
            Write-Host '  Cause : ExchangeOnlineManagement is loaded in this session and has bound an' -ForegroundColor Yellow
            Write-Host '          older Microsoft.Identity.Client assembly that is incompatible with' -ForegroundColor Yellow
            Write-Host '          the interactive browser credential used by Microsoft.Graph.' -ForegroundColor Yellow
            Write-Host ''
            Write-Host '  Fix   : Open a NEW PowerShell 7 session and run this script directly,' -ForegroundColor Green
            Write-Host '          without importing or running any ExchangeOnlineManagement commands' -ForegroundColor Green
            Write-Host '          beforehand.' -ForegroundColor Green
            Write-Host ''
            throw 'Aborted: MSAL DLL conflict. Start a new PowerShell session and run this script without ExchangeOnlineManagement loaded.'
        }
        throw
    }
    $connected = $true
} elseif (Get-Command Get-MgContext -ErrorAction SilentlyContinue) {
    $connected = [bool](Get-MgContext)
}

Write-Step 'Resolving prerequisites'

# Break-glass accounts
$breakGlassIds = @()
if ($connected) {
    if (-not $BreakGlassUpn) {
        $suggestions = @()
        $filter = "startsWith(userPrincipalName,'BreakGlass') or startsWith(userPrincipalName,'bg-') or " +
                  "startsWith(userPrincipalName,'emrg-') or startsWith(userPrincipalName,'emergency-')"
        $found = Get-AllPages -Uri "https://graph.microsoft.com/v1.0/users?`$filter=$([uri]::EscapeDataString($filter))&`$select=id,userPrincipalName&`$top=20"
        if ($found) {
            Write-Host 'Detected emergency-access account candidates:' -ForegroundColor Yellow
            $found | ForEach-Object { Write-Host "  $($_.userPrincipalName)" }
            $suggestions = @($found.userPrincipalName | Select-Object -First 2)
        }
        $dialogResult = Show-BreakGlassDialog -Suggestions $suggestions
        if ($null -eq $dialogResult) {
            throw 'Deployment cancelled: break-glass account input was cancelled. Specify -BreakGlassUpn to skip the dialog.'
        }
        $BreakGlassUpn = $dialogResult
    }
    foreach ($upn in $BreakGlassUpn) {
        $id = Get-UserIdByUpn -Upn $upn
        if ($id) { $breakGlassIds += $id; Write-Host "  Break-glass account: $upn ($id)" -ForegroundColor Green }
        else     { Write-Warning "  Break-glass account not found: $upn" }
    }
    if ($breakGlassIds.Count -eq 0) {
        throw 'No emergency-access account resolved. Specify -BreakGlassUpn. Deployment stopped to prevent lockout.'
    }
} else {
    $breakGlassIds = @('00000000-0000-0000-0000-00000000bg01', '00000000-0000-0000-0000-00000000bg02')
    Write-Host '  Export only without Graph connection: placeholder IDs are used.' -ForegroundColor DarkGray
}

# Named locations (same names and countries as the V1 framework)
function Get-OrCreateCountryLocation {
    param([string]$Name)
    if (-not $connected) { return "<named location: $Name>" }
    $existing = Get-AllPages -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' |
        Where-Object { $_.displayName -eq $Name } | Select-Object -First 1
    if ($existing) { Write-Host "  Named location '$Name' found." -ForegroundColor Green; return $existing.id }
    if ($ExportOnly -or $WhatIfPreference) { return "<named location: $Name>" }
    Write-Host "  Creating named location '$Name' (US, CH)..." -ForegroundColor Yellow
    (Invoke-MgGraphRequest -Method POST -OutputType PSObject `
        -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' -Body @{
            '@odata.type'                     = '#microsoft.graph.countryNamedLocation'
            displayName                       = $Name
            countriesAndRegions               = @('US', 'CH')
            includeUnknownCountriesAndRegions = $false
        }).id
}
$adminAllowedCountriesId = Get-OrCreateCountryLocation -Name 'Countries allowed for admin access'
$chcAllowedCountriesId   = Get-OrCreateCountryLocation -Name 'Countries allowed for CHC data access'

# Secure workstation group: PAW-Global-Users, otherwise Secure Workstation Users
$secureGroupId = '<group: PAW-Global-Users or Secure Workstation Users>'
if ($connected) {
    $grp = $null
    foreach ($name in 'PAW-Global-Users', 'Secure Workstation Users') {
        $grp = (Invoke-MgGraphRequest -Method GET -OutputType PSObject `
            -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=$([uri]::EscapeDataString("displayName eq '$name'"))&`$select=id,displayName").value |
            Select-Object -First 1
        if ($grp) { break }
    }
    if ($grp) {
        $secureGroupId = $grp.id
        Write-Host "  Secure workstation group: $($grp.displayName) ($($grp.id))" -ForegroundColor Green
    } else {
        throw "Neither 'PAW-Global-Users' nor 'Secure Workstation Users' exists. Run Import-CAPolicyFrameworkV2.ps1 first."
    }

    # Custom security attribute used by the CHC application filter
    try {
        Invoke-MgGraphRequest -Method GET -OutputType PSObject `
            -Uri 'https://graph.microsoft.com/v1.0/directory/customSecurityAttributeDefinitions/DataSensitivity_Classification' | Out-Null
        Write-Host '  Custom security attribute DataSensitivity.Classification found.' -ForegroundColor Green
    } catch {
        Write-Warning '  DataSensitivity.Classification not found. The CHC rules are created, but match no application until apps are tagged.'
    }
}

# Same 42 privileged roles as Import-CAPolicyFrameworkV2.ps1 v2.2
$adminRoleIds = @(
    '62e90394-69f5-4237-9190-012177145e10'  # Global Administrator
    '3a2c62db-5318-420d-8d74-23affee5d9d5'  # Intune Administrator
    'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9'  # Conditional Access Administrator
    'c4e39bd9-1100-46d3-8c65-fb160da0071f'  # Authentication Administrator
    '0526716b-113d-4c15-b2c8-68e3c22b9f80'  # Authentication Policy Administrator
    '8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2'  # Hybrid Identity Administrator
    '7be44c8a-adaf-4e2a-84d6-ab2649e08a13'  # Privileged Authentication Administrator
    'e8611ab8-c189-46e8-94e1-60213ab1f814'  # Privileged Role Administrator
    '194ae4cb-b126-40b2-bd5b-6091b380977d'  # Security Administrator
    '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'  # Application Administrator
    'cf1c38e5-3621-4004-a7cb-879624dced7c'  # Application Developer
    'ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe'  # Attribute Provisioning Administrator
    '422218e4-db15-4ef9-bbe0-8afb41546d79'  # Attribute Provisioning Reader
    '25a516ed-2fa0-40ea-a2d0-12923a21473a'  # Authentication Extensibility Administrator
    'aaf43236-0c0d-4d5f-883a-6955382ac081'  # B2C IEF Keyset Administrator
    '158c047a-c907-4556-b7ef-446551a6b5f7'  # Cloud Application Administrator
    '7698a772-787b-4ac8-901f-60d6b08affd2'  # Cloud Device Administrator
    '9360feb5-f418-4baa-8175-e2a00bac4301'  # Directory Writers
    '8329153b-31d0-4727-b945-745eb3bc5f31'  # Domain Name Administrator
    '29232cdf-9323-42fd-ade2-1d097af3e4de'  # Exchange Administrator
    'be2f45a1-457d-42af-a067-6ec1fa63bc45'  # External Identity Provider Administrator
    'f2ef992c-3afb-46b9-b7cf-a126ee74c451'  # Global Reader
    'fdd7a751-b60b-444a-984c-02652fe8fa1c'  # Groups Administrator
    '729827e3-9c14-49f7-bb1b-9608f156bbb8'  # Helpdesk Administrator
    '59d46f88-662b-457b-bceb-5c3809e5908f'  # Lifecycle Workflows Administrator
    '966707d0-3269-4727-9be2-8c3a10f19b9d'  # Password Administrator
    '5d6b6bb7-de71-4623-b4af-96380a352509'  # Security Reader
    '5f2222b1-57c3-48ba-8ad5-d4759f1fde6f'  # Security Operator
    'fe930be7-5e62-47db-91af-98c3a49a38b1'  # User Administrator
    'db506228-d27e-4b7d-95e5-295956d6615f'  # Agent ID Administrator
    'd2562ede-74db-457e-a7b6-544e236ebb61'  # AI Administrator
    '1fe13547-53f6-408d-ac04-7f8eed167b38'  # AI Reader
    '0b00bede-4072-4d22-b441-e7df02a1ef63'  # Authentication Extensibility Password Administrator
    '17315797-102d-40b4-93e0-432062caca18'  # Compliance Administrator
    'e6d1a23a-da11-4be4-9570-befc86d067a7'  # Compliance Data Administrator
    '31392ffb-586c-42d1-9346-e59415a2cc4e'  # Exchange Recipient Administrator
    '6e591065-9bad-43ed-90f3-e9424366d2f0'  # External ID User Flow Administrator
    '0f971eea-41eb-4569-a71e-57bb8a3eff1e'  # External ID User Flow Attribute Administrator
    '45d8d3c5-c802-45c6-b32a-1d70b5e1e86e'  # Identity Governance Administrator
    'b5a8dcf3-09d5-43a9-a639-8e29ef291470'  # Knowledge Administrator
    'f28a1f50-f6e7-4571-818b-6a12f2af6b6c'  # SharePoint Administrator
    '69091246-20e8-4a56-aa4d-066075b2a7a8'  # Teams Administrator
)

$dirSyncRoleId     = 'd29b2b05-8046-44ba-8758-1e26182fcf32'  # Directory Synchronization Accounts
$globalAdminRoleId = '62e90394-69f5-4237-9190-012177145e10'
$phishResistantId  = '00000000-0000-0000-0000-000000000004'  # Built-in phishing-resistant MFA strength
$approvedVdiAppId  = '0af06dc6-e4b5-4f28-818e-e78e62d137a5'  # Azure Virtual Desktop

$chcAppFilterRule = 'CustomSecurityAttribute.DataSensitivity_Classification -contains "Highly Confidential" -or ' +
                    'CustomSecurityAttribute.DataSensitivity_Classification -contains "Confidential"'

$per002ExcludeApps = if ($connected) {
    @(Select-ExistingAppIds -AppIds @(
        '0af06dc6-e4b5-4f28-818e-e78e62d137a5'  # Azure Virtual Desktop
        '9cdead84-a844-4324-93f2-b2e6bb768d07'  # Device Registration Service
        'a4a365df-50f1-4397-bc59-1a1564b8bb9c'  # Microsoft Intune Enrollment
        '270efc09-cd0d-444b-a71f-39af4910ec45'  # Windows Hello for Business Provisioning
    ))
} else {
    @('0af06dc6-e4b5-4f28-818e-e78e62d137a5', '9cdead84-a844-4324-93f2-b2e6bb768d07',
      'a4a365df-50f1-4397-bc59-1a1564b8bb9c', '270efc09-cd0d-444b-a71f-39af4910ec45')
}

#endregion

#region Plan definitions (no consolidation: one V1 policy = one rule)

$block = @{ grantControls = @{ operator = 'OR'; builtInControls = @('block') } }

$plans = @(
    @{
        displayName      = 'PLN-01-2611-Baseline-AllUsers'
        description      = 'Baseline controls for every user: legacy authentication, MFA, platforms, sessions, device compliance, authentication flows and Office 365 restrictions. Source: BAS-001 to BAS-004, BAS-007, BAS-008, BAS-010 to BAS-012.'
        tags             = @('CAPolicyFramework', 'Baseline')
        sharedConditions = @{
            users = @{ includeUsers = @('All'); excludeUsers = $breakGlassIds }
        }
        rules = @(
            @{ displayName = 'BAS-001-2611-Block-AllResources-AllUsers-LegacyAuth'
               description = 'Blocks Exchange ActiveSync and other legacy clients, which cannot satisfy MFA.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; clientAppTypes = @('exchangeActiveSync', 'other') }
               controls    = $block }
            @{ displayName = 'BAS-002-2611-Allow-AllResources-AllUsers-RequireMFA'
               description = 'Requires MFA for all users. Directory Synchronization Accounts are excluded locally.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; users = @{ excludeRoles = @($dirSyncRoleId) } }
               controls    = @{ grantControls = @{ operator = 'OR'; builtInControls = @('mfa') } } }
            @{ displayName = 'BAS-003-2611-Block-AllResources-AllUsers-UnsupportedPlatform'
               description = 'Blocks every platform outside the allowlist (Android, iOS, Windows Phone, Windows, macOS, Linux).'
               conditions  = @{ applications = @{ includeApplications = @('All') }
                                platforms    = @{ includePlatforms = @('all'); excludePlatforms = @('android', 'iOS', 'windowsPhone', 'windows', 'macOS', 'linux') } }
               controls    = $block }
            @{ displayName = 'BAS-004-2611-Allow-AllResources-AllUsers-NoPersistentBrowser'
               description = 'No persistent browser session and one-hour sign-in frequency on unmanaged or non-compliant devices.'
               conditions  = @{ applications = @{ includeApplications = @('All') }
                                devices      = @{ deviceFilter = @{ mode = 'include'; rule = 'device.trustType -ne "ServerAD" -or device.isCompliant -ne True' } } }
               controls    = @{ sessionControls = @{ persistentBrowser = @{ mode = 'never'; isEnabled = $true }
                                                     signInFrequency   = @{ value = 1; type = 'hours'; isEnabled = $true } } } }
            @{ displayName = 'BAS-007-2611-Block-AllResources-AllUsers-RequireCompliantDevice'
               description = 'Blocks members on non-compliant devices. Guests are excluded locally and handled in PLN-06.'
               conditions  = @{ applications = @{ includeApplications = @('All') }
                                users        = @{ excludeUsers = @('GuestsOrExternalUsers') }
                                devices      = @{ deviceFilter = @{ mode = 'exclude'; rule = 'device.isCompliant -eq True' } } }
               controls    = $block }
            @{ displayName = 'BAS-008-2611-Block-AllResources-AllUsers-DeviceFlowAuthenticationTransfer'
               description = 'Blocks device code flow and authentication transfer.'
               conditions  = @{ applications = @{ includeApplications = @('All') }
                                authenticationFlows = @{ transferMethods = 'deviceCodeFlow,authenticationTransfer' } }
               controls    = $block }
            @{ displayName = 'BAS-010-2611-Allow-O365-AllUsers-ApplicationEnforcedRestrictions'
               description = 'Application-enforced restrictions for Office 365.'
               conditions  = @{ applications = @{ includeApplications = @('Office365') }; clientAppTypes = @('all') }
               controls    = @{ sessionControls = @{ applicationEnforcedRestrictions = @{ isEnabled = $true } } } }
            @{ displayName = 'BAS-011-2611-Allow-AllResources-AllUsers-SecureSecurityInfoRegistration'
               description = 'Requires MFA to register security information outside trusted locations. Guests and Global Administrators are excluded locally.'
               conditions  = @{ applications = @{ includeUserActions = @('urn:user:registersecurityinfo') }
                                users        = @{ excludeUsers = @('GuestsOrExternalUsers'); excludeRoles = @($globalAdminRoleId) }
                                locations    = @{ includeLocations = @('All'); excludeLocations = @('AllTrusted') } }
               controls    = @{ grantControls = @{ operator = 'OR'; builtInControls = @('mfa') } } }
            @{ displayName = 'BAS-012-2611-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions'
               description = 'MFA plus SharePoint and OneDrive application-enforced restrictions for Office 365.'
               conditions  = @{ applications = @{ includeApplications = @('Office365') } }
               controls    = @{ grantControls   = @{ operator = 'OR'; builtInControls = @('mfa') }
                                sessionControls = @{ applicationEnforcedRestrictions = @{ isEnabled = $true } } } }
        )
    }
    @{
        displayName      = 'PLN-02-2611-IdentityAndInsiderRisk-AllUsers'
        description      = 'Risk-based controls for every user: risky sign-ins, risky users, elevated insider risk and risky agent delegation. Source: BAS-005, BAS-006, BAS-009, PER-008.'
        tags             = @('CAPolicyFramework', 'Risk')
        sharedConditions = @{
            users        = @{ includeUsers = @('All'); excludeUsers = $breakGlassIds }
        }
        rules = @(
            @{ displayName = 'BAS-005-2611-Allow-AllResources-AllUsers-MFAforRiskySignIns'
               description = 'Requires MFA at every sign-in when sign-in risk is high.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; signInRiskLevels = @('high') }
               controls    = @{ grantControls   = @{ operator = 'OR'; builtInControls = @('mfa') }
                                sessionControls = @{ signInFrequency = @{ authenticationType = 'primaryAndSecondaryAuthentication'; frequencyInterval = 'everyTime'; isEnabled = $true } } } }
            @{ displayName = 'BAS-006-2611-Allow-AllResources-AllUsers-PasswordChangeForHighRiskUsers'
               description = 'Requires MFA and a password change when user risk is high.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; userRiskLevels = @('high') }
               controls    = @{ grantControls = @{ operator = 'AND'; builtInControls = @('mfa', 'passwordChange') } } }
            @{ displayName = 'BAS-009-2611-Block-O365Apps-AllUsers-ElevatedInsiderRisk'
               description = 'Blocks Office 365 for users with elevated insider risk (Purview Adaptive Protection).'
               conditions  = @{ applications = @{ includeApplications = @('Office365') }; insiderRiskLevels = 'elevated' }
               controls    = $block }
            @{ displayName = 'PER-008-2611-BlockAllApps-AgentUsers-HighRisk'
               description = 'Blocks high sign-in risk when acting through AI agent delegation. Falls back to sign-in risk only if the agents condition is not available.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; clientAppTypes = @('all'); signInRiskLevels = @('high')
                                agents = @{ includeAgentUsers = @('All'); excludeAgentUsers = @() } }
               controls    = $block
               fallbackRemove = 'agents' }
        )
    }
    @{
        displayName      = 'PLN-03-2611-DataProtection-CHCApplications'
        description      = 'Controls for applications tagged Highly Confidential or Confidential (custom security attribute DataSensitivity.Classification). Source: DLP-001 to DLP-003.'
        tags             = @('CAPolicyFramework', 'DataProtection')
        sharedConditions = @{
            users        = @{ includeUsers = @('All'); excludeUsers = $breakGlassIds }
            applications = @{ applicationFilter = @{ mode = 'include'; rule = $chcAppFilterRule } }
        }
        rules = @(
            @{ displayName = 'DLP-001-2611-Allow-AllApps-AllUsers-PhishingResistantMFAforCHCData'
               description = 'Requires phishing-resistant MFA for CHC applications.'
               conditions  = @{}
               controls    = @{ grantControls = @{ operator = 'OR'; authenticationStrength = @{ id = $phishResistantId } } } }
            @{ displayName = 'DLP-002-2611-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData'
               description = 'Blocks CHC applications unless the device is compliant and tagged extensionAttribute1 = CSC.'
               conditions  = @{ devices = @{ deviceFilter = @{ mode = 'exclude'; rule = 'device.extensionAttribute1 -eq "CSC" -and device.isCompliant -eq True' } } }
               controls    = $block }
            @{ displayName = 'DLP-003-2611-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData'
               description = 'Blocks CHC applications outside the allowed countries.'
               conditions  = @{ locations = @{ includeLocations = @('All'); excludeLocations = @($chcAllowedCountriesId) } }
               controls    = $block }
        )
    }
    @{
        displayName      = 'PLN-04-2611-PrivilegedRoles'
        description      = 'Controls for the 42 privileged directory roles: allowed countries, high sign-in risk, high user risk and compliant devices. Source: PER-002 to PER-005.'
        tags             = @('CAPolicyFramework', 'Privileged')
        sharedConditions = @{
            users        = @{ includeRoles = $adminRoleIds; excludeUsers = $breakGlassIds }
        }
        rules = @(
            @{ displayName = 'PER-002-2611-Block-AllApps-Admins-AllowSpecificCountriesOnly'
               description = 'Blocks administrator sign-ins outside the allowed countries. Device registration, enrolment and AVD apps are excluded locally.'
               conditions  = @{ applications = @{ includeApplications = @('All'); excludeApplications = $per002ExcludeApps }
                                locations    = @{ includeLocations = @('All'); excludeLocations = @($adminAllowedCountriesId) } }
               controls    = $block }
            @{ displayName = 'PER-003-2611-Block-AllApps-Admins-HighSignInRisk'
               description = 'Blocks administrator sign-ins with high sign-in risk.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; signInRiskLevels = @('high') }
               controls    = $block }
            @{ displayName = 'PER-004-2611-Block-AllApps-Admins-HighUserRisk'
               description = 'Blocks administrators with high user risk.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; userRiskLevels = @('high') }
               controls    = $block }
            @{ displayName = 'PER-005-2611-Block-AllApps-Admins-RequireCompliantDevice'
               description = 'Blocks administrators on non-compliant devices.'
               conditions  = @{ applications = @{ includeApplications = @('All') }
                                devices      = @{ deviceFilter = @{ mode = 'exclude'; rule = 'device.isCompliant -eq True' } } }
               controls    = $block }
        )
    }
    @{
        displayName      = 'PLN-05-2611-PrivilegedAccessWorkstations'
        description      = 'Controls for privileged roles and members of the secure workstation group: phishing-resistant MFA and PAW devices. Source: PER-001, PER-006.'
        tags             = @('CAPolicyFramework', 'Privileged', 'PAW')
        sharedConditions = @{
            users        = @{ includeRoles = $adminRoleIds; includeGroups = @($secureGroupId); excludeUsers = $breakGlassIds }
            applications = @{ includeApplications = @('All') }
        }
        rules = @(
            @{ displayName = 'PER-001-2611-Allow-AllApps-Admins-PhishingResistantMFA'
               description = 'Requires phishing-resistant MFA.'
               conditions  = @{}
               controls    = @{ grantControls = @{ operator = 'OR'; authenticationStrength = @{ id = $phishResistantId } } } }
            @{ displayName = 'PER-006-2611-Block-AllApps-Admins-RequireSecureCompliantDevice'
               description = 'Blocks unless the device is compliant and tagged extensionAttribute1 = PAW.'
               conditions  = @{ devices = @{ deviceFilter = @{ mode = 'exclude'; rule = 'device.extensionAttribute1 -eq "PAW" -and device.isCompliant -eq True' } } }
               controls    = $block }
        )
    }
    @{
        displayName      = 'PLN-06-2611-GuestAndExternalAccess'
        description      = 'Controls for guests and external users: CHC applications, all applications except the approved VDI app, and admin portals. Source: DLP-004, PER-009, PER-010.'
        tags             = @('CAPolicyFramework', 'Guests')
        sharedConditions = @{
            users        = @{ includeUsers = @('GuestsOrExternalUsers'); excludeUsers = $breakGlassIds }
        }
        rules = @(
            @{ displayName = 'DLP-004-2611-Block-AllApps-Guests-BlockAccessToCHCData'
               description = 'Blocks guests from CHC applications.'
               conditions  = @{ applications = @{ applicationFilter = @{ mode = 'include'; rule = $chcAppFilterRule } } }
               controls    = $block }
            @{ displayName = 'PER-009-2611-Block-AllApps-Externals-RequireCompliantSecureVDI'
               description = 'Blocks guests from every application except the approved VDI app.'
               conditions  = @{ applications = @{ includeApplications = @('All'); excludeApplications = @($approvedVdiAppId) } }
               controls    = $block }
            @{ displayName = 'PER-010-2611-Block-AdminPortals-Guests-AdminPortals'
               description = 'Blocks guests from Microsoft admin portals.'
               conditions  = @{ applications = @{ includeApplications = @('MicrosoftAdminPortals') } }
               controls    = $block }
        )
    }
    @{
        displayName      = 'PLN-07-2611-WorkloadIdentities'
        description      = 'Controls for service principals owned by the tenant. Requires Microsoft Entra Workload ID Premium. Source: PER-007.'
        tags             = @('CAPolicyFramework', 'WorkloadIdentities')
        sharedConditions = @{
            clientApplications = @{ includeServicePrincipals = @('ServicePrincipalsInMyTenant'); excludeServicePrincipals = @() }
        }
        rules = @(
            @{ displayName = 'PER-007-2611-Block-AllApps-Agents-HighRisk'
               description = 'Blocks service principals with high risk.'
               conditions  = @{ applications = @{ includeApplications = @('All') }; servicePrincipalRiskLevels = @('high') }
               controls    = $block }
        )
    }
)

#endregion

#region Build request bodies

function New-RuleBody {
    param([hashtable]$Rule, [hashtable]$Shared, [switch]$Flatten, [switch]$Fallback)
    $conditions = if ($Flatten) { Merge-Conditions -Shared $Shared -Rule $Rule.conditions } else { Copy-Deep $Rule.conditions }
    if ($Fallback -and $Rule.fallbackRemove) { $conditions.Remove($Rule.fallbackRemove) }
    @{
        displayName = $Rule.displayName
        description = $Rule.description
        state       = $RuleState
        conditions  = $conditions
        controls    = Copy-Deep $Rule.controls
    }
}

function New-PlanBody {
    param([hashtable]$Plan, [switch]$Flatten, [switch]$Fallback)
    @{
        displayName = $Plan.displayName
        description = $Plan.description
        tags        = $Plan.tags
        rules       = @($Plan.rules | ForEach-Object { New-RuleBody -Rule $_ -Shared $Plan.sharedConditions -Flatten:$Flatten -Fallback:$Fallback })
    }
}

if ($ExportPath) {
    New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
    foreach ($p in $plans) {
        $file = Join-Path $ExportPath "$($p.displayName).json"
        ConvertTo-Json -InputObject (New-PlanBody -Plan $p -Flatten:$NoSharedConditions) -Depth 20 | Set-Content -Path $file -Encoding utf8
        Write-Host "  Exported $file" -ForegroundColor DarkGray
    }
}

$ruleCount = ($plans | ForEach-Object { $_.rules.Count } | Measure-Object -Sum).Sum
Write-Host "`n$($plans.Count) plans with $ruleCount rules defined." -ForegroundColor Cyan
if ($ExportOnly) { Write-Host 'Export only - no changes made.' -ForegroundColor Yellow; return }

#endregion

#region Deployment

Write-Step 'Deploying policy plans'
$existingPlans = Get-AllPages -Uri $plansUri
$summary = [System.Collections.Generic.List[object]]::new()

foreach ($plan in $plans) {
    $existing = $existingPlans | Where-Object { $_.displayName -eq $plan.displayName } | Select-Object -First 1

    if (-not $existing) {
        if (-not $PSCmdlet.ShouldProcess($plan.displayName, 'Create policy plan with rules')) { continue }
        Write-Host "Creating plan '$($plan.displayName)' with $($plan.rules.Count) rule(s)..." -ForegroundColor Yellow
        try {
            $null = Invoke-MgGraphRequest -Method POST -Uri $plansUri -OutputType PSObject `
                -Body (ConvertTo-Json -InputObject (New-PlanBody -Plan $plan -Flatten -Fallback) -Depth 20) `
                -ContentType 'application/json'
            $status = 'Created'
            Write-Host '  Created' -ForegroundColor Green
        } catch {
            $err = Get-GraphErrorText $_
            if ($err -match '1149|2014') {
                Write-Host '  [SKIP] Requires Microsoft Entra Workload ID Premium. Assign the licence and run the script again.' -ForegroundColor Yellow
                $status = 'Skipped (licence)'
            } else {
                Write-Host "  Failed: $err" -ForegroundColor Red
                $status = 'Failed'
            }
        }
        $summary.Add([pscustomobject]@{ Plan = $plan.displayName; Rules = $plan.rules.Count; Result = $status })
        continue
    }

    # Plan exists: add only the rules that are missing
    Write-Host "Plan '$($plan.displayName)' exists - checking rules..." -ForegroundColor Green
    $existingRules = Get-AllPages -Uri "$plansUri/$($existing.id)/rules"
    $added = 0
    foreach ($rule in $plan.rules) {
        if ($existingRules.displayName -contains $rule.displayName) { continue }
        if (-not $PSCmdlet.ShouldProcess($rule.displayName, "Add rule to $($plan.displayName)")) { continue }
        foreach ($fallback in $false, $true) {
            try {
                Invoke-MgGraphRequest -Method POST -Uri "$plansUri/$($existing.id)/rules" -OutputType PSObject `
                    -Body (ConvertTo-Json -InputObject (New-RuleBody -Rule $rule -Shared $plan.sharedConditions -Flatten:$NoSharedConditions -Fallback:$fallback) -Depth 20) `
                    -ContentType 'application/json' | Out-Null
                Write-Host "  Added rule '$($rule.displayName)'" -ForegroundColor Green
                $added++
                break
            } catch {
                Write-Host "  Failed to add '$($rule.displayName)': $(Get-GraphErrorText $_)" -ForegroundColor DarkYellow
            }
        }
    }
    $summary.Add([pscustomobject]@{ Plan = $plan.displayName; Rules = $plan.rules.Count; Result = "Existing, $added rule(s) added" })
}

Write-Step 'Summary'
$summary | Format-Table -AutoSize
Write-Host "All rules use state '$RuleState'. V1 policies were not changed." -ForegroundColor Cyan
Write-Host 'Validate the rules in Report-only, then enable them family by family and disable the matching V1 policies.' -ForegroundColor Cyan

#endregion
