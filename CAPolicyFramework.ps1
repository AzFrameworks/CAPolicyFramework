<#
DISCLAIMER The sample scripts are not supported under any Microsoft standard support program or service.
The sample codes are provided AS IS without warranty of any kind. Microsoft further disclaims all implied
warranties including, without limitation, any implied warranties of merchantability or of fitness for a
particular purpose. The entire risk arising out of the use or performance of the sample codes and documentation
remains with you. In no event shall Microsoft, its authors, owners of this repository or anyone else involved
in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without
limitation, damages for loss of business profits, business interruption, loss of business information, or other
pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if
Microsoft has been advised of the possibility of such damages.
#>

if (-not (Get-PackageProvider -Name NuGet)) {
    Write-Host "Installing Package provider 'NuGet'..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
} else {
    Write-Host "Package provider 'Nuget' is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph.Authentication module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Authentication -Force
} else {
    Write-Host "Microsoft.Graph.Authentication module is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Host "Installing Microsoft.Graph.Users module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Users -Force
} else {
    Write-Host "Microsoft.Graph.Users module is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Write-Host "Installing Microsoft.Graph.Groups module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Groups -Force
} else {
    Write-Host "Microsoft.Graph.Groups module is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
    Write-Host "Installing Microsoft.Graph.Identity.SignIns module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Identity.SignIns -Force
} else {
    Write-Host "Microsoft.Graph.Identity.SignIns module is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.Governance)) {
    Write-Host "Installing Microsoft.Graph.Identity.Governance module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Identity.Governance -Force
} else {
    Write-Host "Microsoft.Graph.Identity.Governance module is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.DirectoryManagement)) {
    Write-Host "Installing Microsoft.Graph.Identity.DirectoryManagement module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Identity.DirectoryManagement -Force
} else {
    Write-Host "Microsoft.Graph.Identity.DirectoryManagement module is already installed." -ForegroundColor Yellow
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
    Write-Host "Installing Microsoft.Graph.Applications module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Applications -Force
} else {
    Write-Host "Microsoft.Graph.Applications module is already installed." -ForegroundColor Yellow
}

$permissions = @(
    "Policy.Read.All"
    "Policy.ReadWrite.ConditionalAccess"
    "Application.Read.All"
    "CustomSecAttributeDefinition.Read.All"
    "CustomSecAttributeDefinition.ReadWrite.All"
    "User.Read.All"
    "User.ReadWrite.All"
    "Group.Read.All"
    "Group.ReadWrite.All"
    "RoleManagement.ReadWrite.Directory"
)
Connect-MgGraph -Scopes $permissions -NoWelcome

$CurrentUser = (Get-MgContext).Account
$CurrentUserId = (Get-MgUser | Where-Object { $_.UserPrincipalName -eq $CurrentUser }).Id

$Params = @{
	"@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
	RoleDefinitionId = "8424c6f0-a189-499e-bbd0-26c1753c96d4"
	PrincipalId = $CurrentUserId
	DirectoryScopeId = "/"
}

if (-not (Get-MgRoleManagementDirectoryRoleAssignment | Where-Object { ($_.PrincipalId -eq $CurrentUserId) -and ($_.RoleDefinitionId -eq "8424c6f0-a189-499e-bbd0-26c1753c96d4") })) {
    Write-Host "Creating role assignment 'Attribute Definition Administrator' for $CurrentUser..." -ForegroundColor Yellow
    New-MgRoleManagementDirectoryRoleAssignment -BodyParameter @Params
} else {
    Write-Host "Role assignment 'Attribute Definition Administrator' for $CurrentUser exists already." -ForegroundColor Yellow
}

$params = @{
    Id = "DataSensitivity"
    Description = "Data sensitivity attribute set"
    MaxAttributesPerSet = 25
}
if (-not (Get-MgDirectoryAttributeSet | Where-Object { $_.Id -eq "DataSensitivity" })) {
    Write-Host "Creating attribute set 'DataSensitivity'..." -ForegroundColor Yellow
    New-MgDirectoryAttributeSet -BodyParameter @Params
} else {
    Write-Host "Attribute set 'DataSensitivity' exists already." -ForegroundColor Yellow
}

$params = @{
    attributeSet = "DataSensitivity"
    description = "Data sensitivity classifications"
    isCollection = $true
    isSearchable = $true
    name = "Classification"
    status = "Available"
    type = "String"
    usePreDefinedValuesOnly = $true
    allowedValues = @(
        @{
            id = "Highly Confidential"
            isActive = $true
        }
        @{
            id = "Confidential"
            isActive = $true
        }
        @{
            id = "General"
            isActive = $true
        }
        @{
            id = "Public"
            isActive = $true
        }
        @{
            id = "Non-Business"
            isActive = $true
        }
    )
}
if (-not (Get-MgDirectoryCustomSecurityAttributeDefinition | Where-Object { $_.Name -eq "Classification" })) {
    Write-Host "Creating attribute definition 'Classification'..." -ForegroundColor Yellow
    New-MgDirectoryCustomSecurityAttributeDefinition -BodyParameter @Params
} else {
    Write-Host "Attribute definistion 'Classification' exists already." -ForegroundColor Yellow
}

$BreakGlassDomain = (Get-MgDomain).Id
$BreakGlassName1 = "Break Glass User 1"
$BreakGlassName2 = "Break Glass User 2"
$BreakGlassUPN1 = "BreakGlass1@$($BreakGlassDomain)"
$BreakGlassUPN2 = "BreakGlass2@$($BreakGlassDomain)"
$BreakGlassMailNickname1 = "BreakGlass1"
$BreakGlassMailNickname2 = "BreakGlass2"

$PasswordProfile = @{
    Password = "PmMxnR5KcF2QCErH"
    ForceChangePasswordNextSignIn = $true
    ForceChangePasswordNextSignInWithMfa = $true
}

$Params = @{
    DisplayName = $BreakGlassName1
    PasswordProfile = $PasswordProfile
    UserPrincipalName = $BreakGlassUPN1
    AccountEnabled = $true
    MailNickname = $BreakGlassMailNickname1
}
if (-not (Get-MgUser | Where-Object { $_.UserPrincipalName -eq $BreakGlassUPN1 })) {
    Write-Host "Creating Break Glass User 1..." -ForegroundColor Yellow
    $BreakGlass1Id = (New-MgUser -BodyParameter @Params).Id
} else {
    $BreakGlass1Id = (Get-MgUser | Where-Object { $_.UserPrincipalName -eq $BreakGlassUPN1 }).Id
    Write-Host "Break Glass User 1 exists already." -ForegroundColor Yellow
}

$Params = @{
    DisplayName = $BreakGlassName2
    PasswordProfile = $PasswordProfile
    UserPrincipalName = $BreakGlassUPN2
    AccountEnabled = $true
    MailNickname = $BreakGlassMailNickname2
}
if (-not (Get-MgUser | Where-Object { $_.UserPrincipalName -eq $BreakGlassUPN2 })) {
    Write-Host "Creating Break Glass User 2..." -ForegroundColor Yellow
    $BreakGlass2Id = (New-MgUser -BodyParameter @Params).Id
} else {
    $BreakGlass2Id = (Get-MgUser | Where-Object { $_.UserPrincipalName -eq $BreakGlassUPN2 }).Id
    Write-Host "Break Glass User 2 exists already." -ForegroundColor Yellow
}

$Params = @{
	"@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
	RoleDefinitionId = "62e90394-69f5-4237-9190-012177145e10"
	PrincipalId = $BreakGlass1Id
	DirectoryScopeId = "/"
}
if (-not (Get-MgRoleManagementDirectoryRoleAssignment | Where-Object { ($_.PrincipalId -eq $BreakGlass1Id) -and ($_.RoleDefinitionId -eq "62e90394-69f5-4237-9190-012177145e10") })) {
    Write-Host "Creating role assignment 'Global Administrator' for $BreakGlassName1..." -ForegroundColor Yellow
    New-MgRoleManagementDirectoryRoleAssignment -BodyParameter @Params
} else {
    Write-Host "Role assignment 'Global Administrator' for $BreakGlassName1 exists already." -ForegroundColor Yellow
}

$Params = @{
	"@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
	RoleDefinitionId = "62e90394-69f5-4237-9190-012177145e10"
	PrincipalId = $BreakGlass2Id
	DirectoryScopeId = "/"
}
if (-not (Get-MgRoleManagementDirectoryRoleAssignment | Where-Object { ($_.PrincipalId -eq $BreakGlass2Id) -and ($_.RoleDefinitionId -eq "62e90394-69f5-4237-9190-012177145e10") })) {
    Write-Host "Creating role assignment 'Global Administrator' for $BreakGlassName2..." -ForegroundColor Yellow
    New-MgRoleManagementDirectoryRoleAssignment -BodyParameter @Params
} else {
    Write-Host "Role assignment 'Global Administrator' for $BreakGlassName2 exists already." -ForegroundColor Yellow
}

$params = @{
    "@odata.type" = "#microsoft.graph.countryNamedLocation"
    DisplayName = "Countries allowed for admin access"
    CountriesAndRegions = @(
        "US"
        "CH"
    )
    IncludeUnknownCountriesAndRegions = $false
}
if (-not (get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq "Countries allowed for admin access" })) {
    Write-Host "Creating named location 'Countries allowed for admin access'..." -ForegroundColor Yellow
    $AdminAllowedCountriesId = (New-MgIdentityConditionalAccessNamedLocation -BodyParameter @params).id
} else {
    Write-Host "Named location 'Countries allowed for admin access' exists already." -ForegroundColor Yellow
}

$params = @{
    "@odata.type" = "#microsoft.graph.countryNamedLocation"
    DisplayName = "Countries allowed for CHC data access"
    CountriesAndRegions = @(
        "US"
        "CH"
    )
    IncludeUnknownCountriesAndRegions = $false
}
if (-not (get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq "Countries allowed for CHC data access" })) {
    Write-Host "Creating named location 'Countries allowed for CHC data access'..." -ForegroundColor Yellow
    $CHCllowedCountriesId = (New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params).id
} else {
    Write-Host "Named location 'Countries allowed for CHC data access' exists already." -ForegroundColor Yellow
}

$SecureGroupName = "Secure Workstation Users"
$SecureGroupMailName = "SecureWorkstationsUsers"
$SecureGroupQuery = '(user.userPrincipalName -startsWith "AZADM-")'

$Params = @{
    Description = $SecureGroupName
    DisplayName = $SecureGroupName
    MailEnabled = $False
    SecurityEnabled = $true
    MailNickName = $SecureGroupMailName
    GroupTypes = 'DynamicMembership'
    MembershipRule = $SecureGroupQuery
    MembershipRuleProcessingState = 'Paused'
}
$SecureGroupNameId = (New-MgGroup -BodyParameter $Params).Id
Update-MgGroup -GroupId $SecureGroupNameId -MembershipRuleProcessingState "On"

# Create Conditional Access policies

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    Platforms = @{
        includePlatforms = "All"
        excludePlatforms = ("Android","iOS","WindowsPhone","Windows","macOS","Linux")
    }
    
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS001-Block-AllApps-AllUsers-UnsupportedPlatform";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS001-Block-AllApps-AllUsers-UnsupportedPlatform" })) {
    Write-Host "Creating policy 'BAS001-Block-AllApps-AllUsers-UnsupportedPlatform'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS001-Block-AllApps-AllUsers-UnsupportedPlatform' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'Office365'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    InsiderRiskLevels = 'Elevated'
       
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS002-Block-O365Apps-AllUsers-ElevatedInsiderRisk";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS002-Block-O365Apps-AllUsers-ElevatedInsiderRisk" })) {
    Write-Host "Creating policy 'BAS002-Block-O365Apps-AllUsers-ElevatedInsiderRisk'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS002-Block-O365Apps-AllUsers-ElevatedInsiderRisk' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'MicrosoftAdminPortals'
    };
    Users = @{
        includeUsers = 'GuestsOrExternalUsers'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
       
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS003-Block-AllApps-Guests-AdminPortals";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS003-Block-AllApps-Guests-AdminPortals" })) {
    Write-Host "Creating policy 'BAS003-Block-AllApps-Guests-AdminPortals'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS003-Block-AllApps-Guests-AdminPortals' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    ClientAppTypes = @('ExchangeActiveSync', 'Other')
    
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS004-Block-AllApps-AllUsers-LegacyAuth";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS004-Block-AllApps-AllUsers-LegacyAuth" })) {
    Write-Host "Creating policy 'BAS004-Block-AllApps-AllUsers-LegacyAuth'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS004-Block-AllApps-AllUsers-LegacyAuth exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    Devices = @{
        deviceFilter = @{
            mode = 'include'
            rule = 'device.trustType -ne "ServerAD" -or device.isCompliant -ne True'
        }
    }
    
}
$grantcontrols = @{
    Operator = 'OR'
}
$sessionControls = @{
    persistentBrowser = @{
        mode = 'never'
        isEnabled = 'true'
    }
    signInFrequency = @{
        value = '1'
        type = 'hours'
        isEnabled = 'true'
    }
}

$Params = @{
    DisplayName = "BAS005-Allow-AllApps-AllUsers-NoPersistentBrowser";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;
    SessionControls = $sessionControls;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS005-Allow-AllApps-AllUsers-NoPersistentBrowser" })) {
    Write-Host "Creating policy 'BAS005-Allow-AllApps-AllUsers-NoPersistentBrowser'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS005-Allow-AllApps-AllUsers-NoPersistentBrowser' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    Platforms = @{
        includePlatforms = ('Android','iOS')
    }

}
$grantcontrols = @{
    BuiltInControls = @('approvedApplication','compliantApplication'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS006-Allow-AllApps-AllUsers-RequireApprovedClientApps";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS006-Allow-AllApps-AllUsers-RequireApprovedClientApps" })) {
    Write-Host "Creating policy 'BAS006-Allow-AllApps-AllUsers-RequireApprovedClientApps'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS006-Allow-AllApps-AllUsers-RequireApprovedClientApps' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeRoles = ('9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3','c4e39bd9-1100-46d3-8c65-fb160da0071f','158c047a-c907-4556-b7ef-446551a6b5f7','7698a772-787b-4ac8-901f-60d6b08affd2','b1be1c3e-b65d-4f19-8427-f6fa0d97feb9','9360feb5-f418-4baa-8175-e2a00bac4301','8329153b-31d0-4727-b945-745eb3bc5f31','62e90394-69f5-4237-9190-012177145e10','f2ef992c-3afb-46b9-b7cf-a126ee74c451','fdd7a751-b60b-444a-984c-02652fe8fa1c','729827e3-9c14-49f7-bb1b-9608f156bbb8','8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2','3a2c62db-5318-420d-8d74-23affee5d9d5','194ae4cb-b126-40b2-bd5b-6091b380977d','e8611ab8-c189-46e8-94e1-60213ab1f814','7be44c8a-adaf-4e2a-84d6-ab2649e08a13','966707d0-3269-4727-9be2-8c3a10f19b9d','5d6b6bb7-de71-4623-b4af-96380a352509','5f2222b1-57c3-48ba-8ad5-d4759f1fde6f','fe930be7-5e62-47db-91af-98c3a49a38b1','29232cdf-9323-42fd-ade2-1d097af3e4de','cf1c38e5-3621-4004-a7cb-879624dced7c','ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe','422218e4-db15-4ef9-bbe0-8afb41546d79','25a516ed-2fa0-40ea-a2d0-12923a21473a','aaf43236-0c0d-4d5f-883a-6955382ac081','be2f45a1-457d-42af-a067-6ec1fa63bc45','59d46f88-662b-457b-bceb-5c3809e5908f')
    };
    Devices = @{
        deviceFilter = @{
            mode = 'exclude'
            rule = 'device.isCompliant -eq True'
        }
    }

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS007-Block-AllApps-Admins-RequireCompliantDevice";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS007-Block-AllApps-Admins-RequireCompliantDevice" })) {
    Write-Host "Creating policy 'BAS007-Block-AllApps-Admins-RequireCompliantDevice'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS007-Block-AllApps-Admins-RequireCompliantDevice' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        excludeRoles = 'd29b2b05-8046-44ba-8758-1e26182fcf32'
    };

}
$grantcontrols = @{
    BuiltInControls = @('mfa'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS008-Allow-AllApps-AllUsers-RequireMFA";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS008-Allow-AllApps-AllUsers-RequireMFA" })) {
    Write-Host "Creating policy 'BAS008-Allow-AllApps-AllUsers-RequireMFA'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS008-Allow-AllApps-AllUsers-RequireMFA' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    signInRiskLevels = 'High'
    
}
$grantcontrols = @{
    BuiltInControls = @('mfa'); 
    Operator = 'OR'
}
$sessionControls = @{
    signInFrequency = @{
        authenticationType = 'primaryAndSecondaryAuthentication'
        frequencyInterval = 'everyTime'
        isEnabled = 'true'
    }
}

$Params = @{
    DisplayName = "BAS009-Allow-AllApps-AllUsers-MFAforRiskySignIns";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;
    SessionControls = $sessionControls;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS009-Allow-AllApps-AllUsers-MFAforRiskySignIns" })) {
    Write-Host "Creating policy 'BAS009-Allow-AllApps-AllUsers-MFAforRiskySignIns'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS009-Allow-AllApps-AllUsers-MFAforRiskySignIns' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'All'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    userRiskLevels = 'High'
    
}
$grantcontrols = @{
    BuiltInControls = @('mfa','passwordChange'); 
    Operator = 'AND'
}
$sessionControls = @{
    signInFrequency = @{
        authenticationType = 'primaryAndSecondaryAuthentication'
        frequencyInterval = 'everyTime'
        isEnabled = 'true'
    }
}

$Params = @{
    DisplayName = "BAS010-Allow-AllApps-AllUsers-PasswordChangeForHighRiskUsers";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;
    SessionControls = $sessionControls;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS010-Allow-AllApps-AllUsers-PasswordChangeForHighRiskUsers" })) {
    Write-Host "Creating policy 'BAS010-Allow-AllApps-AllUsers-PasswordChangeForHighRiskUsers'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS010-Allow-AllApps-AllUsers-PasswordChangeForHighRiskUserss' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeGroups = $SecureGroupNameId
        includeRoles = ('9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3','c4e39bd9-1100-46d3-8c65-fb160da0071f','158c047a-c907-4556-b7ef-446551a6b5f7','7698a772-787b-4ac8-901f-60d6b08affd2','b1be1c3e-b65d-4f19-8427-f6fa0d97feb9','9360feb5-f418-4baa-8175-e2a00bac4301','8329153b-31d0-4727-b945-745eb3bc5f31','62e90394-69f5-4237-9190-012177145e10','f2ef992c-3afb-46b9-b7cf-a126ee74c451','fdd7a751-b60b-444a-984c-02652fe8fa1c','729827e3-9c14-49f7-bb1b-9608f156bbb8','8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2','3a2c62db-5318-420d-8d74-23affee5d9d5','194ae4cb-b126-40b2-bd5b-6091b380977d','e8611ab8-c189-46e8-94e1-60213ab1f814','7be44c8a-adaf-4e2a-84d6-ab2649e08a13','966707d0-3269-4727-9be2-8c3a10f19b9d','5d6b6bb7-de71-4623-b4af-96380a352509','5f2222b1-57c3-48ba-8ad5-d4759f1fde6f','fe930be7-5e62-47db-91af-98c3a49a38b1','29232cdf-9323-42fd-ade2-1d097af3e4de','cf1c38e5-3621-4004-a7cb-879624dced7c','ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe','422218e4-db15-4ef9-bbe0-8afb41546d79','25a516ed-2fa0-40ea-a2d0-12923a21473a','aaf43236-0c0d-4d5f-883a-6955382ac081','be2f45a1-457d-42af-a067-6ec1fa63bc45','59d46f88-662b-457b-bceb-5c3809e5908f')
    };
    
}
$grantcontrols = @{
    Operator = 'OR'
    authenticationStrength = @{
        id = '00000000-0000-0000-0000-000000000004'
    }
}

$Params = @{
    DisplayName = "BAS011-Allow-AllApps-Admins-PhisingResistentMFA";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS011-Allow-AllApps-Admins-PhisingResistentMFA" })) {
    Write-Host "Creating policy 'BAS011-Allow-AllApps-Admins-PhisingResistentMFA'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -BodyParameter @Params
} else {
    Write-Host "Policy 'BAS011-Allow-AllApps-Admins-PhisingResistentMFA' exists already." -ForegroundColor Yellow
}


$conditions = @{
    Applications = @{
        includeUserActions = "urn:user:registersecurityinfo"
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id,'GuestsOrExternalUsers'
        includeUsers = 'All'
        excludeRoles = '62e90394-69f5-4237-9190-012177145e10'
    };
    Locations = @{
        includeLocations = 'All'
        excludeLocations = 'AllTrusted'
    };

}
$grantcontrols = @{
    BuiltInControls = @('mfa'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "BAS012-Allow-AllApps-AllUsers-SecureSecurityInfoRegistration";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS012-Allow-AllApps-AllUsers-SecureSecurityInfoRegistration" })) {
    Write-Host "Creating policy 'BAS012-Allow-AllApps-AllUsers-SecureSecurityInfoRegistration'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'BAS012-Allow-AllApps-AllUsers-SecureSecurityInfoRegistration' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'Office365'
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeUsers = 'All'
    };

}
$grantcontrols = @{
    BuiltInControls = @('mfa'); 
    Operator = 'OR'
}
$sessionControls = @{
    applicationEnforcedRestrictions = @{
        isEnabled = 'true'
    }
}

$Params = @{
    DisplayName = "BAS013-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;
    SessionControls = $sessionControls;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS013-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions" })) {
    Write-Host "Creating policy 'BAS013-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'BAS013-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = "All"
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id,"GuestsOrExternalUsers"
   };
    Devices = @{
        deviceFilter = @{
            mode = 'exclude'
            rule = 'device.isCompliant -eq True'
        }
    }
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}
$Params = @{
    DisplayName = "BAS014-Block-AllApps-AllUsers-RequireCompliantDevice";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "BAS014-Block-AllApps-AllUsers-RequireCompliantDevice" })) {
    Write-Host "Creating policy 'BAS014-Block-AllApps-AllUsers-RequireCompliantDevice'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'BAS014-Block-AllApps-AllUsers-RequireCompliantDevice' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        applicationFilter = @{
            mode = 'include'
            rule = 'CustomSecurityAttribute.DataSensitivity_Classification -contains "Highly Confidential" -or CustomSecurityAttribute.DataSensitivity_Classification -contains "Confidential"'
        }
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeUsers = 'All'
    };
    Devices = @{
        deviceFilter = @{
            mode = 'exclude'
            rule = 'device.extensionAttribute1 -eq "CSC" -and device.isCompliant -eq True'
        }
    }

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "DLP001-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "DLP001-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData" })) {
    Write-Host "Creating policy 'DLP001-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'DLP001-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        applicationFilter = @{
            mode = 'include'
            rule = 'CustomSecurityAttribute.DataSensitivity_Classification -contains "Highly Confidential" -or CustomSecurityAttribute.DataSensitivity_Classification -contains "Confidential"'
        }
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeUsers = 'All'
    };

}
$grantcontrols = @{
    Operator = 'OR'
    authenticationStrength = @{
        id = '00000000-0000-0000-0000-000000000004'
    }
}

$Params = @{
    DisplayName = "DLP002-Allow-AllApps-AllUsers-PhisingResistantMFAforCHCData";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "DLP002-Allow-AllApps-AllUsers-PhisingResistantMFAforCHCData" })) {
    Write-Host "Creating policy 'DLP002-Allow-AllApps-AllUsers-PhisingResistantMFAforCHCData'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'DLP002-Allow-AllApps-AllUsers-PhisingResistantMFAforCHCData' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        applicationFilter = @{
            mode = 'include'
            rule = 'CustomSecurityAttribute.DataSensitivity_Classification -contains "Highly Confidential" -or CustomSecurityAttribute.DataSensitivity_Classification -contains "Confidential"'
        }
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeUsers = 'GuestsOrExternalUsers'
    };

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "DLP003-Block-AllApps-Guests-BlockAccessToCHCData";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "DLP003-Block-AllApps-Guests-BlockAccessToCHCData" })) {
    Write-Host "Creating policy 'DLP003-Block-AllApps-Guests-BlockAccessToCHCData'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'DLP003-Block-AllApps-Guests-BlockAccessToCHCData' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        applicationFilter = @{
            mode = 'include'
            rule = 'CustomSecurityAttribute.DataSensitivity_Classification -contains "Highly Confidential" -or CustomSecurityAttribute.DataSensitivity_Classification -contains "Confidential"'
        }
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeUsers = 'All'
    };
    Locations = @{
        includeLocations = 'All'
        excludeLocations = $CHCllowedCountriesId
    };

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "DLP004-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls = $grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "DLP004-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData" })) {
    Write-Host "Creating policy 'DLP004-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'DLP004-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeGroups = $SecureGroupNameId
        includeRoles = ('9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3','c4e39bd9-1100-46d3-8c65-fb160da0071f','158c047a-c907-4556-b7ef-446551a6b5f7','7698a772-787b-4ac8-901f-60d6b08affd2','b1be1c3e-b65d-4f19-8427-f6fa0d97feb9','9360feb5-f418-4baa-8175-e2a00bac4301','8329153b-31d0-4727-b945-745eb3bc5f31','62e90394-69f5-4237-9190-012177145e10','f2ef992c-3afb-46b9-b7cf-a126ee74c451','fdd7a751-b60b-444a-984c-02652fe8fa1c','729827e3-9c14-49f7-bb1b-9608f156bbb8','8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2','3a2c62db-5318-420d-8d74-23affee5d9d5','194ae4cb-b126-40b2-bd5b-6091b380977d','e8611ab8-c189-46e8-94e1-60213ab1f814','7be44c8a-adaf-4e2a-84d6-ab2649e08a13','966707d0-3269-4727-9be2-8c3a10f19b9d','5d6b6bb7-de71-4623-b4af-96380a352509','5f2222b1-57c3-48ba-8ad5-d4759f1fde6f','fe930be7-5e62-47db-91af-98c3a49a38b1','29232cdf-9323-42fd-ade2-1d097af3e4de','cf1c38e5-3621-4004-a7cb-879624dced7c','ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe','422218e4-db15-4ef9-bbe0-8afb41546d79','25a516ed-2fa0-40ea-a2d0-12923a21473a','aaf43236-0c0d-4d5f-883a-6955382ac081','be2f45a1-457d-42af-a067-6ec1fa63bc45','59d46f88-662b-457b-bceb-5c3809e5908f')
    };
    Devices = @{
        deviceFilter = @{
            mode = 'exclude'
            rule = 'device.extensionAttribute1 -eq "PAW" -and device.isCompliant -eq True'
        }
    }

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "PER001-Block-AllApps-Admins-RequireSecureCompliantDevice";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "PER001-Block-AllApps-Admins-RequireSecureCompliantDevice" })) {
    Write-Host "Creating policy 'PER001-Block-AllApps-Admins-RequireSecureCompliantDevice'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'PER001-Block-AllApps-Admins-RequireSecureCompliantDevice' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
        excludeApplications = ('0af06dc6-e4b5-4f28-818e-e78e62d137a5')
    };
    Users = @{
        includeUsers = 'GuestsOrExternalUsers'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "PER002-Block-AllApps-Externals-RequireCompliantSecureVDI";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "PER002-Block-AllApps-Externals-RequireCompliantSecureVDI" })) {
    Write-Host "Creating policy 'PER002-Block-AllApps-Externals-RequireCompliantSecureVDI'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'PER002-Block-AllApps-Externals-RequireCompliantSecureVDI' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
        excludeApplications = ('0af06dc6-e4b5-4f28-818e-e78e62d137a5','9cdead84-a844-4324-93f2-b2e6bb768d07','a4a365df-50f1-4397-bc59-1a1564b8bb9c','270efc09-cd0d-444b-a71f-39af4910ec45')
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeRoles = ('9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3','c4e39bd9-1100-46d3-8c65-fb160da0071f','158c047a-c907-4556-b7ef-446551a6b5f7','7698a772-787b-4ac8-901f-60d6b08affd2','b1be1c3e-b65d-4f19-8427-f6fa0d97feb9','9360feb5-f418-4baa-8175-e2a00bac4301','8329153b-31d0-4727-b945-745eb3bc5f31','62e90394-69f5-4237-9190-012177145e10','f2ef992c-3afb-46b9-b7cf-a126ee74c451','fdd7a751-b60b-444a-984c-02652fe8fa1c','729827e3-9c14-49f7-bb1b-9608f156bbb8','8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2','3a2c62db-5318-420d-8d74-23affee5d9d5','194ae4cb-b126-40b2-bd5b-6091b380977d','e8611ab8-c189-46e8-94e1-60213ab1f814','7be44c8a-adaf-4e2a-84d6-ab2649e08a13','966707d0-3269-4727-9be2-8c3a10f19b9d','5d6b6bb7-de71-4623-b4af-96380a352509','5f2222b1-57c3-48ba-8ad5-d4759f1fde6f','fe930be7-5e62-47db-91af-98c3a49a38b1','29232cdf-9323-42fd-ade2-1d097af3e4de','cf1c38e5-3621-4004-a7cb-879624dced7c','ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe','422218e4-db15-4ef9-bbe0-8afb41546d79','25a516ed-2fa0-40ea-a2d0-12923a21473a','aaf43236-0c0d-4d5f-883a-6955382ac081','be2f45a1-457d-42af-a067-6ec1fa63bc45','59d46f88-662b-457b-bceb-5c3809e5908f')
    };
    Locations = @{
        includeLocations = 'All'
        excludeLocations = $AdminAllowedCountriesId
    };

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "PER003-Block-AllApps-Admins-AllowSpecificCountriesOnly";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "PER003-Block-AllApps-Admins-AllowSpecificCountriesOnly" })) {
    Write-Host "Creating policy 'PER003-Block-AllApps-Admins-AllowSpecificCountriesOnly'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'PER003-Block-AllApps-Admins-AllowSpecificCountriesOnly' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeRoles = ('9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3','c4e39bd9-1100-46d3-8c65-fb160da0071f','158c047a-c907-4556-b7ef-446551a6b5f7','7698a772-787b-4ac8-901f-60d6b08affd2','b1be1c3e-b65d-4f19-8427-f6fa0d97feb9','9360feb5-f418-4baa-8175-e2a00bac4301','8329153b-31d0-4727-b945-745eb3bc5f31','62e90394-69f5-4237-9190-012177145e10','f2ef992c-3afb-46b9-b7cf-a126ee74c451','fdd7a751-b60b-444a-984c-02652fe8fa1c','729827e3-9c14-49f7-bb1b-9608f156bbb8','8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2','3a2c62db-5318-420d-8d74-23affee5d9d5','194ae4cb-b126-40b2-bd5b-6091b380977d','e8611ab8-c189-46e8-94e1-60213ab1f814','7be44c8a-adaf-4e2a-84d6-ab2649e08a13','966707d0-3269-4727-9be2-8c3a10f19b9d','5d6b6bb7-de71-4623-b4af-96380a352509','5f2222b1-57c3-48ba-8ad5-d4759f1fde6f','fe930be7-5e62-47db-91af-98c3a49a38b1','29232cdf-9323-42fd-ade2-1d097af3e4de','cf1c38e5-3621-4004-a7cb-879624dced7c','ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe','422218e4-db15-4ef9-bbe0-8afb41546d79','25a516ed-2fa0-40ea-a2d0-12923a21473a','aaf43236-0c0d-4d5f-883a-6955382ac081','be2f45a1-457d-42af-a067-6ec1fa63bc45','59d46f88-662b-457b-bceb-5c3809e5908f')
    };
    signInRiskLevels = 'High'
    
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "PER004-Block-AllApps-Admins-HighUserRisk";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "PER004-Block-AllApps-Admins-HighUserRisk" })) {
    Write-Host "Creating policy 'PER004-Block-AllApps-Admins-HighUserRisk'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'PER004-Block-AllApps-Admins-HighUserRisk' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
        includeRoles = ('9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3','c4e39bd9-1100-46d3-8c65-fb160da0071f','158c047a-c907-4556-b7ef-446551a6b5f7','7698a772-787b-4ac8-901f-60d6b08affd2','b1be1c3e-b65d-4f19-8427-f6fa0d97feb9','9360feb5-f418-4baa-8175-e2a00bac4301','8329153b-31d0-4727-b945-745eb3bc5f31','62e90394-69f5-4237-9190-012177145e10','f2ef992c-3afb-46b9-b7cf-a126ee74c451','fdd7a751-b60b-444a-984c-02652fe8fa1c','729827e3-9c14-49f7-bb1b-9608f156bbb8','8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2','3a2c62db-5318-420d-8d74-23affee5d9d5','194ae4cb-b126-40b2-bd5b-6091b380977d','e8611ab8-c189-46e8-94e1-60213ab1f814','7be44c8a-adaf-4e2a-84d6-ab2649e08a13','966707d0-3269-4727-9be2-8c3a10f19b9d','5d6b6bb7-de71-4623-b4af-96380a352509','5f2222b1-57c3-48ba-8ad5-d4759f1fde6f','fe930be7-5e62-47db-91af-98c3a49a38b1','29232cdf-9323-42fd-ade2-1d097af3e4de','cf1c38e5-3621-4004-a7cb-879624dced7c','ecb2c6bf-0ab6-418e-bd87-7986f8d63bbe','422218e4-db15-4ef9-bbe0-8afb41546d79','25a516ed-2fa0-40ea-a2d0-12923a21473a','aaf43236-0c0d-4d5f-883a-6955382ac081','be2f45a1-457d-42af-a067-6ec1fa63bc45','59d46f88-662b-457b-bceb-5c3809e5908f')

    };
    userRiskLevels = 'High'
    
}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "PER005-Block-AllApps-Admins-HighSignInRisk";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "PER005-Block-AllApps-Admins-HighSignInRisk" })) {
    Write-Host "Creating policy 'PER005-Block-AllApps-Admins-HighSignInRisk'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'PER005-Block-AllApps-Admins-HighSignInRisk' exists already." -ForegroundColor Yellow
}

$conditions = @{
    Applications = @{
        includeApplications = 'All'
    };
    Users = @{
        includeUsers = 'GuestsOrExternalUsers'
        excludeUsers = $BreakGlass1Id,$BreakGlass2Id
    };
    AuthenticationFlows = @{
        transferMethods = ('deviceCodeFlow,authenticationTransfer')
    };

}
$grantcontrols = @{
    BuiltInControls = @('block'); 
    Operator = 'OR'
}

$Params = @{
    DisplayName = "PER006-Block-AllApps-Guests-DeviceFlowAuthenticationTransfer";
    State = "EnabledForReportingButNotEnforced";
    Conditions = $conditions;
    GrantControls =$grantcontrols;  
}
if (-not (Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "PER006-Block-AllApps-Guests-DeviceFlowAuthenticationTransfer" })) {
    Write-Host "Creating policy 'PER006-Block-AllApps-Guests-DeviceFlowAuthenticationTransfer'..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy @Params
} else {
    Write-Host "Policy 'PER006-Block-AllApps-Guests-DeviceFlowAuthenticationTransfer' exists already." -ForegroundColor Yellow
}
