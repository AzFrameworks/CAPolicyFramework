

Version 2.0 Final

Daniel Metzger,
Cloud Solution Architect Identity & Security,
Microsoft Switzerland GmbH
 
## About this Conditional Access Framework

A well-planned Conditional Access deployment is essential for implementing an organization’s access strategy for applications and resources. In a mobile-first, cloud-first environment, users access organizational resources from many locations, devices, and applications. As a result, access decisions must consider more than who is requesting access; they must also account for location, device state, the requested resource, and other relevant signals.

Microsoft Entra Conditional Access uses signals such as identity, device, and location to make automated access decisions and enforce policies aligned with organizational requirements. These policies can require controls such as multifactor authentication (MFA), prompting users only when needed to strengthen security while preserving a smooth user experience.

![Picture1](/pics/EUD_Conditional_Access_Signals_Diagram_preview.png)
 
This document presents a baseline Conditional Access policy framework based on recommended Microsoft Entra templates and extended with additional policies for privileged administrative activities and sensitive data access. It is intended as a starting point for broad implementation across all users. Organizations will typically customize the framework and add further policies to meet specific requirements, and not every policy will be enabled in every environment from the outset.

The framework provides guidance for configuring essential Conditional Access policies that improve security without disrupting operations. For example, it recommends excluding emergency “break-glass” accounts from all Conditional Access policies to avoid accidental lockouts. Directory synchronization service accounts should also be excluded to maintain uninterrupted identity synchronization. Policies should initially be deployed in Report-only mode so organizations can assess their impact through sign-in logs and Conditional Access insights before enforcement.

A PowerShell script is included to support rapid deployment of this Conditional Access framework. The script automates policy creation, helping ensure consistent and efficient application of access policies.
 
## The Conditional Access funnel model

![Picture2](/pics/Conditional_Access_Funnel_Graphics_preview_2.png) 

![Picture3](/pics/Conditional_Access_Funnel_Graphics_preview_1.png) 
 
## Baseline policies

Exclude break-glass emergency access accounts and directory synchronization accounts from all Conditional Access policies to reduce the risk of accidental tenant lockout. Break-glass accounts must remain available for emergency administration, while Microsoft Entra ID Directory Synchronization Accounts cannot satisfy MFA or device-based requirements by design. Deploy policies in Report-only mode first to assess their impact and adjust them as needed before enforcement, helping avoid unintended disruption.

The following baseline policies provide a core set of controls for protecting all users and sign-ins. They appear in the same order in which the deployment script creates them.

![Picture4](/pics/Picture4.png) 
 
**o BAS-001-2606-Block-AllResources-AllUsers-LegacyAuth**
(Block legacy authentication protocols that cannot enforce MFA)

**Description:** Blocks legacy authentication protocols, such as POP, IMAP, SMTP, and older Office clients, across all applications and users. Because these protocols do not support modern controls such as MFA or device compliance, they are frequently used in credential-based attacks. Blocking legacy authentication requires users to rely on modern authentication methods and helps remove a common attack path.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication">Block legacy authentication with Conditional Access</a>

**o BAS-002-2606-Allow-AllResources-AllUsers-RequireMFA**
(Require multifactor authentication for all users)

**Description:** Requires all users to complete MFA when accessing any application, reducing the risk of account compromise. The policy enforces MFA for all sign-ins, with typical exclusions for break-glass and non-interactive service accounts such as directory synchronization accounts. Organization-wide MFA is strongly recommended because accounts protected by MFA are far less likely to be compromised.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength">Require multifactor authentication for all users</a>

**o BAS-003-2606-Block-AllResources-AllUsers-UnsupportedPlatform**
(Block access from unknown or unsupported device platforms)

**Description:** Blocks access to all resources when the device platform is not recognized as Windows, macOS, Linux, iOS, or Android, including devices reported as “Unknown” or unsupported platforms such as Chrome OS. Because the device platform condition depends on the user agent string and is not strongly validated, this policy should be combined with controls such as device compliance or app protection to reduce the risk of user-agent spoofing.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-device-unknown-unsupported">Block unknown or unsupported device platform</a>

**o BAS-004-2606-Allow-AllResources-AllUsers-NoPersistentBrowser**
(Disable persistent browser sessions and enforce reauthentication frequency on unmanaged devices)

**Description:** Prevents browser sessions from remaining signed in on personal or non-compliant devices. The policy applies to all users on devices that are not hybrid Azure AD joined or Intune compliant, sets persistent browser sessions to “Never,” and requires reauthentication every hour. This reduces the risk of unauthorized access from stale sessions, especially on unmanaged devices.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-persistent-browser">Require reauthentication and disable browser persistence</a>

**o BAS-005-2606-Allow-AllResources-AllUsers-MFAforRiskySignIns**
(Require multifactor authentication for high-risk sign-in attempts)

**Description:** Requires MFA when Microsoft Entra ID Protection identifies a sign-in as high risk. Requiring users to reverify their identity during anomalous sign-ins helps interrupt illegitimate access attempts, even when a password has been compromised. If the user has not registered for MFA, the sign-in is blocked until registration or administrative remediation is completed.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-risk-based-sign-in">Require multifactor authentication for elevated sign-in risk</a>

**o BAS-006-2606-Allow-AllResources-AllUsers-PasswordChangeForHighRiskUsers**
(Require password change for high-risk user accounts)

**Description:** Requires users to change their password securely when Microsoft Entra ID Protection marks their account as high risk. Access to resources is blocked until the user resets the password and completes MFA, allowing the risk to be remediated. This helps limit damage from leaked or compromised credentials by ensuring they are rotated before further access is granted.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-risk-based-user">Require remediation for risky users</a>

**o BAS-007-2606-Block-AllResources-AllUsers-RequireCompliantDevice**
(Require compliant device for all user access)

**Description:** Blocks access to cloud resources from devices that are not Intune compliant or hybrid Azure AD joined. The policy applies to internal users, with exclusions for emergency accounts and external or guest identities. Requiring device compliance helps prevent access from unmanaged or insecure endpoints; users on personal or non-compliant devices must enroll their device or use an approved access method.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-device-compliance">Require device compliance with Conditional Access</a>

**o BAS-008-2606-Block-AllResources-AllUsers-DeviceFlowAuthenticationTransfer**
(Block device code flow and authentication token transfer)*

**Description:** Blocks device code flow and authentication token transfer for all users. These flows can introduce bypass opportunities, especially in phishing scenarios or cross-device sign-ins. Blocking them helps ensure that authentication occurs through standard interactive methods governed by the organization’s Conditional Access controls.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-authentication-flows">Block authentication flows with Conditional Access policy</a>

**o BAS-009-2606-Block-O365Apps-AllUsers-ElevatedInsiderRisk**
(Block access to Microsoft 365 apps for users flagged with elevated insider risk)

**Description:** Blocks access to Microsoft 365 applications when Microsoft Purview Insider Risk Management identifies a user with an elevated insider risk score. Insider risk signals can be used in Conditional Access decisions to restrict access when anomalous or risky activity is detected. This gives security teams time to investigate or require additional controls before normal access resumes. Prerequisite: Microsoft Purview Insider Risk Management must be enabled to generate the required risk signals.

**o BAS-010-2606-Allow-O365-AllUsers-ApplicationEnforcedRestrictions**
(Use application-enforced restrictions for Office 365 on unmanaged devices)

**Description:** Applies application-enforced restrictions for Office 365 cloud apps, typically when accessed from unmanaged or non-compliant devices. Supported services such as SharePoint Online, OneDrive, and Outlook on the web can then provide limited web-only access, such as viewing without downloading. SharePoint and Exchange restrictions must be configured in advance. This approach protects corporate data on unmanaged endpoints by allowing controlled access instead of full access.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-app-enforced-restrictions">Use application enforced restrictions for unmanaged devices</a>

**o BAS-011-2606-Allow-AllResources-AllUsers-SecureSecurityInfoRegistration**
(Secure MFA & SSPR security info registration process)

**Description:** Requires MFA when users register or change security information for MFA or Self-Service Password Reset (SSPR). The policy protects the “Register security info” user action and helps prevent attackers with only a password from adding or changing authentication methods. Typical exclusions include break-glass accounts, guests, and Global Administrators to avoid setup issues. Prerequisite: Combined registration for MFA and SSPR should be enabled.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-security-info-registration">Protect security info registration with Conditional Access policy</a>

**o BAS-012-2606-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions**
(Enforce additional session controls for Office 365 applications)

**Description:** Applies application-enforced restrictions to Office 365 apps, potentially together with an MFA requirement. This layered approach helps ensure that users accessing Office 365 from unmanaged or untrusted contexts meet strong authentication requirements while operating within limited application experiences. It works with configured cloud app restrictions to reduce data leakage risk on unmanaged devices.

## Data sensitivity-based Access Control
 
![Picture6](/pics/Common_Baseline_Policies_for_Conditional_Access_Updated_preview.png) 

To protect applications that handle Confidential or Highly Confidential data, the framework includes policies based on application-specific attributes. These policies use a custom DataSensitivity attribute set, including a Classification attribute with values such as “Confidential” and “Highly Confidential.” Conditional Access filters for applications with these attributes and applies stricter controls.  

**o DLP-001-2606-Allow-AllApps-AllUsers-PhishingResistantMFAforCHCData**
(Require phishing-resistant MFA for confidential & highly confidential data access)

**Description:** Requires phishing-resistant MFA, such as FIDO2 security keys, certificate-based authentication, or Windows Hello for Business, when users access applications tagged as Confidential or Highly Confidential. This protects sensitive applications even if a password or weaker MFA method is compromised through phishing. The control helps reduce unauthorized access to high-value assets.

**o DLP-002-2606-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData**
(Require compliant, secure workstation for confidential & highly confidential data)

**Description:** Blocks access to Confidential or Highly Confidential applications from devices that are not fully managed and specially secured. The policy uses device filters, such as a corporate secure client attribute, together with compliance state so that only approved secure endpoints can access sensitive data. This helps ensure that high-sensitivity data is accessed only from hardened and monitored devices, such as Privileged Access Workstations. Prerequisite: Establish a reliable method to identify secure devices, such as Intune compliance policies, directory extension attributes, or dedicated device groups.

**o DLP-003-2606-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData**
(Allow access to CHC data only from specific countries/regions)

**Description:** Restricts access to Confidential or Highly Confidential applications based on geographic location. The script creates a named location, “Countries allowed for CHC data access,” initially including the United States and Switzerland. Access from outside the allowed countries is blocked. Organizations should adjust the country list to match data residency and compliance requirements. This control supports data sovereignty and limits access from untrusted regions.

**o DLP-004-2606-Block-AllApps-Guests-BlockAccessToCHCData**
(Block guest/external user access to confidential & highly confidential apps)

**Description:** Blocks guest and external users from accessing applications classified as Confidential or Highly Confidential. Because external identities typically do not require access to the organization’s most sensitive applications or data, this policy enforces access only for trusted internal identities. If certain contractor accounts should be treated similarly, they can be added to the policy scope.
These DLP policies require each sensitive application to be assigned the DataSensitivity: Classification custom attribute with the appropriate value. Conditional Access uses an application filter referencing those values to include the relevant applications dynamically.
  
![Picture7](/pics/Picture7.png) 
 
## Persona-based Access Control  

![Picture8](/pics/Picture8.png) 

Persona-based access control categorizes users by their job function, behavior, and risk level. Unlike traditional role-based access, which grants permissions based on predefined roles, persona-based access adapts to real-time conditions.  

Organizations define personas that reflect how users interact with systems. Corporate employees using company devices might have seamless access, while remote workers could face stricter authentication. Third-party contractors should only access specific resources for limited periods, and privileged users require additional security layers. Guest users need minimal, temporary access.  

Once personas are established, access conditions must align with security risks. A corporate employee logging in from an office device may not need multi-factor authentication (MFA), while a remote worker using an unmanaged laptop might. Privileged users should undergo real-time risk analysis, and contractors' access should be tightly controlled with time-based restrictions.
 
### Defined Personas
1.	**Corporate Employee** – Part- or Full-time employees using company-managed devices to access corporate resources. These users may work from the office, from home, or other remote locations. Zero Trust measures should include continuous identity verification, device compliance checks, and behavioral monitoring. Even when accessing from within the corporate network, employees should undergo periodic authentication challenges. Least privilege principles should be enforced, ensuring employees only access what is necessary for their role.
   
Conditional Access policies for corporate employees are covered by the baseline policies and the data sensitivity policies already.  

2.	**External Contractor** – Employees of partner organizations or vendors who require access to shared systems and have an internal user account. External contractors may work remotely or from the organization's premises and use either company-managed devices or access through company-managed VDI. Access should be logged and reviewed frequently. Contractors accessing from unmanaged devices should be required to use secure VDI environments rather than direct access to internal systems.
   
3.	**Privileged User** – IT administrators, executives, and other high-level personnel with access to critical systems, infrastructure, or sensitive company data. These users pose the highest risk if compromised. Zero Trust measures should include just-in-time (JIT) access, phising-resistent MFA, continuous monitoring, and real-time risk scoring. Privileged actions, such as modifying security settings or accessing sensitive data, should require additional verification steps. All privileged user activity should be logged and reviewed to prevent insider threats or credential misuse. Privileged Access Workstations are mandatory.
The following Entra ID roles are considered to be privileged:
 
Also add the Exchange Administrator role in Entra ID although it's recommended to avoid this role for Exchange administration but using the service-specific roles and Exchange RBAC.  

4.	**Guest User** – Users which don't have an internal account but authenticate against an external identity provider, typically in B2B scenarios. They usually operate from unmanaged devices. These users require highly restricted, time-limited access as they use mostly unmanaged devices. Zero Trust should enforce strict identity verification, sandboxed access to prevent interaction with critical systems, and automatic expiration of guest accounts. Guest users should never have persistent access and should be required to reauthenticate frequently.
   
5.	**Workload Identities** – A workload identity is an identity you assign to a software workload (such as an application, service, script, or container) to authenticate and access other services and resources. The terminology is inconsistent across the industry, but generally a workload identity is something you need for your software entity to authenticate with some system. For example, in order for GitHub Actions to access Azure subscriptions the action needs a workload identity which has access to those subscriptions. A workload identity could also be an AWS service role attached to an EC2 instance with read-only access to an Amazon S3 bucket.
     
In Microsoft Entra, workload identities are applications, service principals, managed identities, agent identities and agent users.

**o PER-001-2606-Allow-AllApps-Admins-PhishingResistantMFA**
(Require phishing-resistant MFA for privileged role administrators)

**Description:** Requires users in privileged administrative roles to authenticate with phishing-resistant MFA through an authentication strength condition. The policy targets highly privileged Microsoft Entra roles and allows only strong methods such as FIDO2 security keys or certificate-based authentication. This reduces the likelihood that phishing can compromise administrative accounts. Before enforcement, ensure all affected administrators have registered phishing-resistant credentials to avoid lockout.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-admin-phish-resistant-mfa">Require phishing-resistant multifactor authentication for administrators</a>

**o PER-002-2606-Block-AllApps-Admins-AllowSpecificCountriesOnly**
(Allow privileged role admin access only from specific countries/locations)

**Description:** Limits privileged administrator sign-ins to trusted geographic locations. The script creates a named location, “Countries allowed for admin access,” with the United States and Switzerland as default examples. Sign-ins from outside those countries are blocked, while required services such as Azure AD device registration or Intune enrollment can remain globally accessible. This reduces the risk of unauthorized administrative access from unexpected regions.

**o PER-003-2606-Block-AllApps-Admins-HighSignInRisk**
(Block privileged role users with high sign-in risk)

**Description:** Blocks sign-ins by privileged role users when Microsoft Entra ID Protection identifies high sign-in risk. For privileged accounts, the policy denies access rather than allowing MFA remediation, because compromised administrative credentials can have significant impact. This helps stop suspicious administrative sign-ins before access to critical systems is granted.

**o PER-004-2606-Block-AllApps-Admins-HighUserRisk**
(Block privileged role users with high user risk)

**Description:** Blocks privileged role users when Microsoft Entra ID Protection marks their account as high user risk, indicating likely compromise. Unlike standard users, who may be required to reset their password, privileged users are blocked until an administrator remediates the risk. This prevents potentially compromised administrative accounts from being used for high-impact actions.
**o PER-005-2606-Block-AllApps-Admins-RequireCompliantDevice**
(Require compliant device for privileged role user access)

**Description:** Blocks privileged role users from accessing applications unless they use an Intune-compliant or hybrid joined device. Because administrative accounts are high-value targets, this policy prevents privileged access from personal or unmanaged endpoints. It applies device compliance requirements specifically to administrative roles, reducing exposure from risky devices.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-alt-admin-device-compliand-hybrid">Require compliant device or Microsoft Entra hybrid joined device for administrators</a>

**o PER-001-2606-Allow-AllApps-Admins-PhishingResistantMFA**
(Require phishing-resistant MFA for privileged role administrators)

**Description:** Requires users in privileged administrative roles to authenticate with phishing-resistant MFA through an authentication strength condition. The policy targets highly privileged Microsoft Entra roles and allows only strong methods such as FIDO2 security keys or certificate-based authentication. This reduces the likelihood that phishing can compromise administrative accounts. Before enforcement, ensure all affected administrators have registered phishing-resistant credentials to avoid lockout.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-admin-phish-resistant-mfa">Require phishing-resistant multifactor authentication for administrators</a>

**o PER-002-2606-Block-AllApps-Admins-AllowSpecificCountriesOnly**
(Allow privileged role admin access only from specific countries/locations)

**Description:** Limits privileged administrator sign-ins to trusted geographic locations. The script creates a named location, “Countries allowed for admin access,” with the United States and Switzerland as default examples. Sign-ins from outside those countries are blocked, while required services such as Azure AD device registration or Intune enrollment can remain globally accessible. This reduces the risk of unauthorized administrative access from unexpected regions.

**o PER-003-2606-Block-AllApps-Admins-HighSignInRisk**
(Block privileged role users with high sign-in risk)

**Description:** Blocks sign-ins by privileged role users when Microsoft Entra ID Protection identifies high sign-in risk. For privileged accounts, the policy denies access rather than allowing MFA remediation, because compromised administrative credentials can have significant impact. This helps stop suspicious administrative sign-ins before access to critical systems is granted.

**o PER-004-2606-Block-AllApps-Admins-HighUserRisk**
(Block privileged role users with high user risk)

**Description:** Blocks privileged role users when Microsoft Entra ID Protection marks their account as high user risk, indicating likely compromise. Unlike standard users, who may be required to reset their password, privileged users are blocked until an administrator remediates the risk. This prevents potentially compromised administrative accounts from being used for high-impact actions.

**o PER-005-2606-Block-AllApps-Admins-RequireCompliantDevice**
(Require compliant device for privileged role user access)

**Description:** Blocks privileged role users from accessing applications unless they use an Intune-compliant or hybrid joined device. Because administrative accounts are high-value targets, this policy prevents privileged access from personal or unmanaged endpoints. It applies device compliance requirements specifically to administrative roles, reducing exposure from risky devices.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-alt-admin-device-compliand-hybrid">Require compliant device or Microsoft Entra hybrid joined device for administrators</a>

**o PER-006-2606-Block-AllApps-Admins-RequireSecureCompliantDevice**
(Require secure, compliant workstation for privileged role user access)

**Description:** Further restricts privileged access to known Privileged Access Workstations or similarly hardened devices that are also compliant. The script uses a device attribute filter, such as device.extensionAttribute1 = “PAW,” together with compliance state. This ensures that privileged roles can be used only from devices specifically configured for sensitive administrative tasks.

**o PER-007-2606-Block-AllApps-Agents-HighRisk**
(Block high-risk workload identity (service principal) sign-ins)

**Description:** Extends Conditional Access protections to workload identities by blocking token issuance for service principals marked as high risk by Microsoft Entra ID Protection. If an application identity appears compromised, access to resources is denied. This helps protect automation and service accounts from malicious use. Note: Conditional Access for workload identities requires Microsoft Entra Workload Identities Premium.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/workload-identity">Conditional Access for workload identities</a>

**o PER-008-2606-BlockAllApps-AgentUsers-HighRisk**
(Block high-risk sign-ins by agent-assisted or autonomous user sessions)

**Description:** Addresses scenarios where an autonomous or assistive agent acts on behalf of a user. If a sign-in in an agent context is marked as high risk, the policy blocks the session. This helps prevent compromised or suspicious agent-assisted sessions from accessing resources. This capability may depend on Conditional Access for agents preview features or specific licensing conditions.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/agent-id">Conditional Access for agents</a>

**o PER-009-2606-Block-AllApps-Externals-RequireCompliantSecureVDI**
(Require compliant, secure VDI for external user access)

**Description:** Requires guest and external users to access cloud resources through an approved Virtual Desktop Infrastructure when they are not using a managed device. The policy blocks direct access to cloud apps except the designated VDI service, such as Azure Virtual Desktop. Once connected to a managed VDI host, users can access resources from a controlled environment. This reduces data leakage risk from unmanaged external endpoints. Prerequisite: Deploy an approved VDI solution such as Azure Virtual Desktop or Windows 365 and enforce MFA as needed.

**o PER-010-2606-Block-AdminPortals-Guests-AdminPortals**
(Block guest users from all administrative portals)

**Description:** Blocks guest and external users from accessing Microsoft administrative portals, including the Azure portal, Microsoft 365 admin center, and Intune admin center. This prevents external identities from reaching high-privilege management interfaces. In cross-tenant collaboration scenarios, guest accounts should not need access to administrative tools, and this policy enforces that separation.
Conditional Access Insights and Reporting
