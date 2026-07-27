![Picture1](/pics/EUD_Conditional_Access_Signals_Diagram_preview.png)

# Secure Conditional Access Baseline Starter Kit

## Disclaimer

This Secure Conditional Access Baseline Starter Kit is provided as implementation guidance and sample automation only. It is not a substitute for an organization-specific security, legal, compliance, privacy, licensing, or operational assessment. Conditional Access policies, exclusions, named locations, authentication strengths, application and device filters, role scopes, and deployment states must be reviewed and adapted to the target tenant before use.

Test all changes in a non-production environment and validate them in report-only mode where supported before enforcement. Maintain tested emergency access accounts and an approved rollback procedure to reduce the risk of tenant lockout or unintended service disruption. Feature behavior, prerequisites, licensing, and Microsoft cloud capabilities may change; administrators are responsible for confirming current Microsoft documentation and tenant availability at the time of deployment. Use of the kit is at the organization’s own risk, and no warranty, guarantee of fitness, or support commitment is expressed or implied.

[Microsoft Entra Conditional Access documentation - Microsoft Entra ID | Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/conditional-access/)

## Summary

The provided PowerShell script in this repo implements a layered Microsoft Entra Conditional Access security framework rather than a standalone script outcome: it creates or references custom security attributes, break-glass accounts, named locations, secure workstation targeting, privileged role scopes, identity-risk controls, insider-risk controls, workload-identity protections, guest restrictions, and app/data-classification-based access policies. Microsoft describes Conditional Access as the policy engine that combines signals such as user, device, and location to automate access decisions and enforce organizational policy; the framework uses that model as the tenant’s Zero Trust access-control plane.

The target state is a tenant where baseline controls protect all users, privileged roles receive stronger authentication and device requirements, Confidential / Highly Confidential applications are protected through custom security attribute targeting, guest access is constrained, and workload identities / agent-related access paths are brought into the Conditional Access model. The script explicitly warns that policies must be reviewed before moving from test/simulation states to enforcement and that Endpoint DLP indicators, IRM triggering events, and Adaptive Protection bindings require portal-side configuration steps.


Figure 1: Layered Microsoft Entra Conditional Access target-state architecture showing identity, device, location, risk, app classification, guest, workload-identity, and operational rollout relationships.

## Architecture Principles and Trust Boundaries

The framework implements four trust boundaries:

-   Standard workforce access: Legacy authentication is blocked, while MFA, compliant-device requirements, session restrictions, security-information registration protection, and risk-based remediation are enforced.
-   Privileged administration: A 42-role administrative scope is protected through phishing-resistant MFA, country restrictions, high-risk blocking, compliant-device enforcement, and PAW-style device filtering.
-   Data-sensitive application access: The custom security attribute set DataSensitivity and the multi-value string attribute Classification classify applications as Highly Confidential, Confidential, General, Public, or Non-Business. Policies then target applications tagged as Highly Confidential or Confidential.
-   External and guest access: Guest-specific controls block access to CHC applications, admin portals, and all applications except the approved VDI/AVD application 0af06dc6-e4b5-4f28-818e-e78e62d137a5.

Device trust is central to the design. Microsoft’s Conditional Access device-filter documentation states that device filters can target specific device attributes and gives privileged workstation use cases using extension attributes; the script uses device.isCompliant, extensionAttribute1=PAW, and extensionAttribute1=CSC patterns to separate compliant devices, privileged access workstations, and CHC secure clients.

Location trust is implemented with country named locations for admin access and CHC data access, both allowing US and CH and excluding unknown countries/regions; Microsoft documents country/region and IP named locations as Conditional Access network signals. Administrators must align the allowed countries to their desired locations before going into production.

## Component Inventory

| Component | Target-state outcome | Operational dependency |
| --- | --- | --- |
| PowerShell / Graph foundation | Requires PowerShell 5.1, NuGet, Microsoft Graph modules for authentication, users, groups, sign-ins, governance, directory management, and applications. | Administrator workstation must be able to install/import modules and connect to Graph. |
| Microsoft Graph permissions | Uses scopes including Policy.ReadWrite.ConditionalAccess, CustomSecAttributeDefinition.ReadWrite.All, Group.ReadWrite.All, User.ReadWrite.All, and RoleManagement.ReadWrite.Directory. | Interactive admin consent and least-privilege review required. |
| Attribute Definition Administrator assignment | Assigns the current user the Attribute Definition Administrator role so custom security attributes can be created. | Role assignment must be permitted and auditable. |
| Custom security attributes | Creates DataSensitivity and Classification to classify applications for CA targeting. | Microsoft notes app filters use custom security attributes on service principals and only support string attributes for Conditional Access filters. |
| Break-glass accounts | Requires BreakGlass1@<defaultDomain> and BreakGlass2@<defaultDomain> to pre-exist; deployment exits if either is missing. | Microsoft recommends two or more emergency access accounts and excluding them from CA policies that block or restrict sign-in. |
| Named locations | Creates/reuses Countries allowed for admin access and Countries allowed for CHC data access, both with US and CH, unknown countries excluded. | Validate business-approved geographies and VPN/cloud proxy behavior. |
| Secure workstation group | Uses existing PAW-Global-Users security group; if absent, falls back to Secure Workstation Users. The PAW-Global-Users security group is extensively used in another, private framework for Privileged Access Workstations. | PAW/secure workstation lifecycle, device compliance, and extension attributes must be maintained. |
| Admin role scope | Targets a broad privileged role set; version history states v2.2 aligns with 42 roles which are marked as Privileged in Entra ID. | Review role list against tenant privileged-access standard. |

## Conditional Access Control Catalog

The catalog below lists the Conditional Access policies included in the Secure Conditional Access Baseline Starter Kit. Break-glass accounts refer to BreakGlass1 and BreakGlass2, which are excluded throughout the framework.

[Conditional Access - Block access - Microsoft Entra ID | Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-example#user-exclusions)

[Manage emergency access admin accounts - Microsoft Entra ID | Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access)

-   **BAS-001-2606-Block-AllResources-AllUsers-LegacyAuth**
    -   Control domain: Baseline
    -   Security outcome / enforcement logic: Blocks Exchange ActiveSync and other legacy/basic auth client app types, which cannot satisfy MFA.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: State not explicitly shown in visible source; verify in tenant.
-   **BAS-002-2606-Allow-AllResources-AllUsers-RequireMFA**
    -   Control domain: Baseline MFA
    -   Security outcome / enforcement logic: Requires MFA for all users, excluding Directory Synchronization Accounts role d29b2b05-8046-44ba-8758-1e26182fcf32.
    -   Population and exclusions: All users; excludes break-glass accounts and Directory Sync accounts.
    -   State / rollout note: Verify final state.
-   **BAS-003-2606-Block-AllResources-AllUsers-UnsupportedPlatform**
    -   Control domain: Platform control
    -   Security outcome / enforcement logic: Blocks platforms not in allowlist: Android, iOS, Windows Phone, Windows, macOS, Linux.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Verify final state.
-   **BAS-004-2606-Allow-AllResources-AllUsers-NoPersistentBrowser**
    -   Control domain: Session/device
    -   Security outcome / enforcement logic: For unmanaged/non-compliant devices, disables persistent browser and sets sign-in frequency to one hour.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Verify final state; user-impact testing required.
-   **BAS-005-2606-Allow-AllResources-AllUsers-MFAforRiskySignIns**
    -   Control domain: Sign-in risk
    -   Security outcome / enforcement logic: Requires step-up MFA when Identity Protection reports high sign-in risk.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Requires Entra ID Protection risk signals; P2 required for risk in CA.
-   **BAS-006-2606-Allow-AllResources-AllUsers-PasswordChangeForHighRiskUsers**
    -   Control domain: User risk
    -   Security outcome / enforcement logic: Requires MFA and password change for high user risk; script notes password change remediates the risk.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Requires Entra ID P2 risk policy capability.
-   **BAS-007-2606-Block-AllResources-AllUsers-RequireCompliantDevice**
    -   Control domain: Device trust
    -   Security outcome / enforcement logic: Blocks standard users from non-compliant devices using device.isCompliant -eq True exclusion logic.
    -   Population and exclusions: All users; excludes break-glass accounts and GuestsOrExternalUsers.
    -   State / rollout note: Verify final state; guest handling is separated.
-   **BAS-008-2606-Block-AllResources-AllUsers-DeviceFlowAuthenticationTransfer**
    -   Control domain: Auth flow hardening
    -   Security outcome / enforcement logic: Blocks device code flow and authentication transfer to reduce token-hijacking paths.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Verify final state.
-   **BAS-009-2606-Block-O365Apps-AllUsers-ElevatedInsiderRisk**
    -   Control domain: Insider risk
    -   Security outcome / enforcement logic: Blocks Office 365 access for users with elevated insider risk.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Requires Purview Adaptive Protection / insider-risk configuration; Microsoft states Adaptive Protection can dynamically apply Conditional Access by insider risk level.
-   **BAS-010-2606-Allow-O365-AllUsers-ApplicationEnforcedRestrictions**
    -   Control domain: App/session control
    -   Security outcome / enforcement logic: Enables Office 365 application-enforced restrictions so SharePoint/Exchange honor app control.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Microsoft positions app-enforced restrictions for unmanaged-device access limits in SharePoint/OneDrive and Outlook attachments.
-   **BAS-011-2606-Allow-AllResources-AllUsers-SecureSecurityInfoRegistration**
    -   Control domain: Registration protection
    -   Security outcome / enforcement logic: Requires MFA for security-info registration from non-trusted locations; excludes Global Admins to avoid lockout.
    -   Population and exclusions: All users; excludes break-glass accounts, guests, and Global Administrator role.
    -   State / rollout note: Validate trusted locations before enforcement.
-   **BAS-012-2606-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions**
    -   Control domain: SharePoint/OneDrive protection
    -   Security outcome / enforcement logic: Enables SharePoint/OneDrive app-enforced restrictions to limit download on unmanaged devices.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Requires Microsoft 365 app-side configuration.
-   **DLP-001-2606-Allow-AllApps-AllUsers-PhishingResistantMFAforCHCData**
    -   Control domain: Data protection
    -   Security outcome / enforcement logic: Requires phishing-resistant MFA for CHC-classified apps.
    -   Population and exclusions: All users; excludes break-glass accounts; targets app filter.
    -   State / rollout note: Explicit report-only.
-   **DLP-002-2606-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData**
    -   Control domain: Data/device
    -   Security outcome / enforcement logic: Requires compliant device with extensionAttribute1=CSC for CHC apps.
    -   Population and exclusions: All users; excludes break-glass accounts; targets app filter.
    -   State / rollout note: Explicit report-only; device attribute governance required.
-   **DLP-003-2606-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData**
    -   Control domain: Data sovereignty
    -   Security outcome / enforcement logic: Blocks CHC app access outside the CHC allowed-country named location.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Explicit report-only; geography validation required.
-   **DLP-004-2606-Block-AllApps-Guests-AccessToCHCData**
    -   Control domain: Guest/data
    -   Security outcome / enforcement logic: Blocks guests from Confidential / Highly Confidential apps.
    -   Population and exclusions: GuestsOrExternalUsers; excludes break-glass accounts.
    -   State / rollout note: Explicit report-only.
-   **PER-001-2606-Allow-AllApps-Admins-PhishingResistantMFA**
    -   Control domain: Privileged auth
    -   Security outcome / enforcement logic: Requires phishing-resistant MFA for admin roles and secure workstation users.
    -   Population and exclusions: Admin role IDs and secure workstation group; excludes break-glass accounts.
    -   State / rollout note: Microsoft defines phishing-resistant MFA strength as FIDO2, Windows Hello for Business/platform credential, or multifactor certificate-based authentication.
-   **PER-002-2606-Block-AllApps-Admins-AllowSpecificCountriesOnly**
    -   Control domain: Privileged geography
    -   Security outcome / enforcement logic: Allows admin sign-ins only from approved countries; excludes AVD, device registration, Intune enrollment, and WHfB provisioning apps if present.
    -   Population and exclusions: Admin role IDs; excludes break-glass accounts.
    -   State / rollout note: Verify service principals exist; script filters missing app IDs to avoid creation failure.
-   **PER-003-2606-Block-AllApps-Admins-HighSignInRisk**
    -   Control domain: Privileged risk
    -   Security outcome / enforcement logic: Blocks admin sign-ins with high sign-in risk.
    -   Population and exclusions: Admin role IDs; excludes break-glass accounts.
    -   State / rollout note: Requires ID Protection risk.
-   **PER-004-2606-Block-AllApps-Admins-HighUserRisk**
    -   Control domain: Privileged risk
    -   Security outcome / enforcement logic: Blocks admin sign-ins when the admin account is high user risk.
    -   Population and exclusions: Admin role IDs; excludes break-glass accounts.
    -   State / rollout note: Requires ID Protection risk.
-   **PER-005-2606-Block-AllApps-Admins-RequireCompliantDevice**
    -   Control domain: Privileged device
    -   Security outcome / enforcement logic: Blocks admin roles from any non-compliant device.
    -   Population and exclusions: Admin role IDs; excludes break-glass accounts.
    -   State / rollout note: Requires compliant-device lifecycle.
-   **PER-006-2606-Block-AllApps-Admins-RequireSecureCompliantDevice**
    -   Control domain: PAW
    -   Security outcome / enforcement logic: Requires admins and secure workstation users to use compliant PAW devices with extensionAttribute1=PAW.
    -   Population and exclusions: Admin role IDs + secure workstation group; excludes break-glass accounts.
    -   State / rollout note: Requires PAW deployment and device attribute maintenance.
-   **PER-007-2606-Block-AllApps-Agents-HighRisk**
    -   Control domain: Workload identity
    -   Security outcome / enforcement logic: Blocks high-risk service principals using servicePrincipalRiskLevels=high and clientApplications.includeServicePrincipals.
    -   Population and exclusions: Workload identities / service principals.
    -   State / rollout note: Requires Microsoft Entra Workload ID Premium; script skips on license error 1149.
-   **PER-008-2606-BlockAllApps-AgentUsers-HighRisk**
    -   Control domain: Agent-user risk
    -   Security outcome / enforcement logic: Blocks high sign-in risk when acting through AI agent delegation; if private preview agent scope is unavailable, falls back to sign-in-risk-only policy.
    -   Population and exclusions: All users; excludes break-glass accounts.
    -   State / rollout note: Uses PrivatePreview:CAAgentContext; fallback behavior is built in.
-   **PER-009-2606-Block-AllApps-Externals-RequireCompliantSecureVDI**
    -   Control domain: External access
    -   Security outcome / enforcement logic: Blocks external users from all apps except approved VDI / AVD app 0af06dc6-e4b5-4f28-818e-e78e62d137a5.
    -   Population and exclusions: Guests/external users; excludes break-glass accounts.
    -   State / rollout note: Explicit report-only.
-   **PER-010-2606-Block-AdminPortals-Guests-AdminPortals**
    -   Control domain: Guest/admin portal
    -   Security outcome / enforcement logic: Blocks guests from Microsoft admin portals.
    -   Population and exclusions: Guests/external users; excludes break-glass accounts.
    -   State / rollout note: Verify final state.

## Implementation Prerequisites and Assumptions

The tenant must have Microsoft Entra Conditional Access capability; Microsoft states a working tenant with Entra ID P1/P2 or trial licensing is a prerequisite, and Entra ID P2 is required to include Identity Protection risk in Conditional Access policies. The framework’s risk-based policies assume Entra ID Protection can provide high sign-in risk and high user risk, and Microsoft’s ID Protection deployment guidance states risk data can feed Conditional Access decisions and requires P2 for ID Protection deployment.

The authentication design assumes that phishing-resistant methods are available and registered for admins and CHC users. Microsoft defines authentication strength as a Conditional Access control specifying allowed authentication method combinations and includes built-in Phishing-resistant MFA strength with FIDO2 security key, Windows Hello for Business / platform credential, and multifactor certificate-based authentication. The break-glass strategy assumes two pre-existing accounts and aligns with Microsoft guidance to create two or more emergency access accounts, keep them cloud-only, exclude them from CA policies that block/restrict sign-in, monitor usage, and validate regularly.

For data-protection targeting, applications must exist as service principals and be tagged with the custom security attribute. Microsoft documents that Conditional Access application filters tag service principals with custom attributes evaluated at token issuance time, and that Conditional Access application filters support string custom security attributes. For device trust, Intune compliance and Entra device attributes must be operational; Microsoft documents extensionAttribute1-15, isCompliant, and device filters as supported Conditional Access device-filter properties, with caveats for unregistered devices and negative operators.

Workload identity protection requires Microsoft Entra Workload ID Premium to create or modify policies scoped to service principals; Microsoft also notes workload identity policies cover service principals owned by the organization and don’t cover managed identities or multitenant SaaS apps. Insider-risk controls require Microsoft Purview Adaptive Protection / Insider Risk Management integration; Microsoft states Adaptive Protection can dynamically apply Conditional Access controls based on insider risk levels and that Conditional Access with insider risk requires Entra ID P2.

## Operational Considerations, Limitations, and Rollout Guidance

Rollout model. Treat the framework as a staged deployment. The script explicitly advises testing in a non-production tenant and reviewing all policies before switching from TestWithNotifications / Simulation to enforce mode. Microsoft states report-only mode evaluates most Conditional Access policies during sign-in without enforcing them and logs results in sign-in details; after validation, policies can be moved from Report-only to On. Microsoft also warns that report-only policies requiring compliant devices can still prompt macOS, iOS, and Android users for device certificates, even though compliance isn’t enforced.

Monitoring and governance. Use sign-in logs, the Conditional Access tab, policy impact, and the Conditional Access Insights and Reporting workbook to validate policy behavior before and after enforcement. Microsoft recommends applying CA coverage broadly, minimizing policy sprawl, establishing naming conventions, monitoring impact with workbooks, troubleshooting with What If, and governing policy changes; it also notes a 240-policy tenant limit across all states.

Break-glass operations. Emergency access accounts must remain excluded from enforced blocking or restrictive policies; Microsoft recommends monitoring every use, storing credentials securely, validating the accounts at least every 90 days, and using secure workstations for emergency access. The framework depends on BreakGlass1 and BreakGlass2; if either account is absent, deployment stops, which is intentional resilience behavior rather than an error to bypass.

Known limitations and validation points. Validate that the US and CH country allowlists match the tenant’s real business and regulatory operating model; Microsoft notes locations are based on public IP/GPS signals and policies apply after first-factor authentication, not as a frontline DoS defense. Validate that app-enforced restrictions are configured on the relevant Microsoft 365 workloads, because the script references app-enforced restrictions for Office 365, SharePoint, and OneDrive while also noting portal-side configuration dependencies. Validate PER007/PER008 behavior in the tenant because the script has explicit license-skip behavior for Workload ID Premium and preview/fallback behavior for agent-scope conditions.

## Implementation Guidance for Administrators

1.  Pre-stage dependencies: create and monitor BreakGlass1 and BreakGlass2, verify Conditional Access Administrator / Attribute Definition Administrator permissions, confirm Graph consent, and validate the required Microsoft Graph modules and NuGet installation path.
2.  Prepare identity and device signals: configure MFA and phishing-resistant methods, establish Intune compliance baselines, populate PAW/CSC device extension attributes, and define trusted / allowed network and country locations.
3.  Prepare data classification: tag enterprise applications with DataSensitivity.Classification values so DLP policies can target Highly Confidential and Confidential apps through application filters.
4.  Deploy in validation-first mode where applicable: leave explicitly report-only policies in report-only until sign-in logs, policy impact, and workbook data show expected behavior; verify the actual state of policies that are not explicitly report-only in the visible source.
5.  Operationalize exceptions: keep exclusions small, documented, and time-bound; Microsoft recommends testing exclusion criteria because combinations of policies can still require controls for excluded users through other applicable policies.
6.  Move to enforcement through change control: for each policy family, approve enforcement only after documented test cases confirm expected results for standard users, admins, guests, PAW users, unmanaged devices, risky users, CHC app access, and workload identities.
