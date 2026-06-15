

Version 1.1 Final

Daniel Metzger
Cloud Solution Architect Identity & Security
Microsoft Switzerland GmbH
 
## About this Conditional Access Framework

A well-planned Conditional Access deployment is essential for implementing an organization’s access strategy for applications and resources. In a mobile-first, cloud-first environment, users access organizational resources from many locations, devices, and applications. As a result, access decisions must consider more than who is requesting access; they must also account for location, device state, the requested resource, and other relevant signals.

Microsoft Entra Conditional Access uses signals such as identity, device, and location to make automated access decisions and enforce policies aligned with organizational requirements. These policies can require controls such as multifactor authentication (MFA), prompting users only when needed to strengthen security while preserving a smooth user experience.

![Picture1](/pics/Picture1.png)
 
This document presents a baseline Conditional Access policy framework based on recommended Microsoft Entra templates and extended with additional policies for privileged administrative activities and sensitive data access. It is intended as a starting point for broad implementation across all users. Organizations will typically customize the framework and add further policies to meet specific requirements, and not every policy will be enabled in every environment from the outset.

The framework provides guidance for configuring essential Conditional Access policies that improve security without disrupting operations. For example, it recommends excluding emergency “break-glass” accounts from all Conditional Access policies to avoid accidental lockouts. Directory synchronization service accounts should also be excluded to maintain uninterrupted identity synchronization. Policies should initially be deployed in Report-only mode so organizations can assess their impact through sign-in logs and Conditional Access insights before enforcement.

A PowerShell script is included to support rapid deployment of this Conditional Access framework. The script automates policy creation, helping ensure consistent and efficient application of access policies.
 
## The Conditional Access funnel model

![Picture2](/pics/Picture2.png) 

![Picture3](/pics/Picture3.png) 
 
## Baseline policies

Exclude break-glass emergency access accounts and directory synchronization accounts from all Conditional Access policies to reduce the risk of accidental tenant lockout. Break-glass accounts must remain available for emergency administration, while Microsoft Entra ID Directory Synchronization Accounts cannot satisfy MFA or device-based requirements by design. Deploy policies in Report-only mode first to assess their impact and adjust them as needed before enforcement, helping avoid unintended disruption.

The following baseline policies provide a core set of controls for protecting all users and sign-ins. They appear in the same order in which the deployment script creates them.

![Picture4](/pics/Picture4.png) 
 
**o BAS-001-2606-Block-AllResources-AllUsers-LegacyAuth**
(Block legacy authentication protocols that cannot enforce MFA)

**Description:** Blocks legacy authentication protocols, such as POP, IMAP, SMTP, and older Office clients, across all applications and users. Because these protocols do not support modern controls such as MFA or device compliance, they are frequently used in credential-based attacks. Blocking legacy authentication requires users to rely on modern authentication methods and helps remove a common attack path.

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication">Block legacy authentication with Conditional Access (https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-legacy-authentication)</a>

**o BAS-002-2606-Allow-AllResources-AllUsers-RequireMFA**
(Require multifactor authentication for all users)

**Description:** Requires all users to complete MFA when accessing any application, reducing the risk of account compromise. The policy enforces MFA for all sign-ins, with typical exclusions for break-glass and non-interactive service accounts such as directory synchronization accounts. Organization-wide MFA is strongly recommended because accounts protected by MFA are far less likely to be compromised.

Require multifactor authentication for all users

**o BAS-003-2606-Block-AllResources-AllUsers-UnsupportedPlatform**
(Block access from unknown or unsupported device platforms)

**Description:** Blocks access to all resources when the device platform is not recognized as Windows, macOS, Linux, iOS, or Android, including devices reported as “Unknown” or unsupported platforms such as Chrome OS. Because the device platform condition depends on the user agent string and is not strongly validated, this policy should be combined with controls such as device compliance or app protection to reduce the risk of user-agent spoofing.

Block unknown or unsupported device platform

**o BAS-004-2606-Allow-AllResources-AllUsers-NoPersistentBrowser**
(Disable persistent browser sessions and enforce reauthentication frequency on unmanaged devices)

**Description:** Prevents browser sessions from remaining signed in on personal or non-compliant devices. The policy applies to all users on devices that are not hybrid Azure AD joined or Intune compliant, sets persistent browser sessions to “Never,” and requires reauthentication every hour. This reduces the risk of unauthorized access from stale sessions, especially on unmanaged devices.

Require reauthentication and disable browser persistence

**o BAS-005-2606-Allow-AllResources-AllUsers-MFAforRiskySignIns**
(Require multifactor authentication for high-risk sign-in attempts)

**Description:** Requires MFA when Microsoft Entra ID Protection identifies a sign-in as high risk. Requiring users to reverify their identity during anomalous sign-ins helps interrupt illegitimate access attempts, even when a password has been compromised. If the user has not registered for MFA, the sign-in is blocked until registration or administrative remediation is completed.

Require multifactor authentication for elevated sign-in risk

**o BAS-006-2606-Allow-AllResources-AllUsers-PasswordChangeForHighRiskUsers**
(Require password change for high-risk user accounts)

**Description:** Requires users to change their password securely when Microsoft Entra ID Protection marks their account as high risk. Access to resources is blocked until the user resets the password and completes MFA, allowing the risk to be remediated. This helps limit damage from leaked or compromised credentials by ensuring they are rotated before further access is granted.

Require remediation for risky users

**o BAS-007-2606-Block-AllResources-AllUsers-RequireCompliantDevice**
(Require compliant device for all user access)

**Description:** Blocks access to cloud resources from devices that are not Intune compliant or hybrid Azure AD joined. The policy applies to internal users, with exclusions for emergency accounts and external or guest identities. Requiring device compliance helps prevent access from unmanaged or insecure endpoints; users on personal or non-compliant devices must enroll their device or use an approved access method.

Require device compliance with Conditional Access

**o BAS-008-2606-Block-AllResources-AllUsers-DeviceFlowAuthenticationTransfer**
(Block device code flow and authentication token transfer)*

**Description:** Blocks device code flow and authentication token transfer for all users. These flows can introduce bypass opportunities, especially in phishing scenarios or cross-device sign-ins. Blocking them helps ensure that authentication occurs through standard interactive methods governed by the organization’s Conditional Access controls.

Block authentication flows with Conditional Access policy

**o BAS-009-2606-Block-O365Apps-AllUsers-ElevatedInsiderRisk**
(Block access to Microsoft 365 apps for users flagged with elevated insider risk)

**Description:** Blocks access to Microsoft 365 applications when Microsoft Purview Insider Risk Management identifies a user with an elevated insider risk score. Insider risk signals can be used in Conditional Access decisions to restrict access when anomalous or risky activity is detected. This gives security teams time to investigate or require additional controls before normal access resumes. Prerequisite: Microsoft Purview Insider Risk Management must be enabled to generate the required risk signals.
**o BAS-010-2606-Allow-O365-AllUsers-ApplicationEnforcedRestrictions**
(Use application-enforced restrictions for Office 365 on unmanaged devices)

**Description:** Applies application-enforced restrictions for Office 365 cloud apps, typically when accessed from unmanaged or non-compliant devices. Supported services such as SharePoint Online, OneDrive, and Outlook on the web can then provide limited web-only access, such as viewing without downloading. SharePoint and Exchange restrictions must be configured in advance. This approach protects corporate data on unmanaged endpoints by allowing controlled access instead of full access.

Use application enforced restrictions for unmanaged devices

**o BAS-011-2606-Allow-AllResources-AllUsers-SecureSecurityInfoRegistration**
(Secure MFA & SSPR security info registration process)

**Description:** Requires MFA when users register or change security information for MFA or Self-Service Password Reset (SSPR). The policy protects the “Register security info” user action and helps prevent attackers with only a password from adding or changing authentication methods. Typical exclusions include break-glass accounts, guests, and Global Administrators to avoid setup issues. Prerequisite: Combined registration for MFA and SSPR should be enabled.

Protect security info registration with Conditional Access policy

**o BAS-012-2606-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions**
(Enforce additional session controls for Office 365 applications)

**Description:** Applies application-enforced restrictions to Office 365 apps, potentially together with an MFA requirement. This layered approach helps ensure that users accessing Office 365 from unmanaged or untrusted contexts meet strong authentication requirements while operating within limited application experiences. It works with configured cloud app restrictions to reduce data leakage risk on unmanaged devices.

**o	BAS012-Allow-AllApps-AllUsers-SecureSecurityInfoRegistration**  
(Securing security info registration)

Securing security info registration involves controlling how and when users register for multi-factor authentication (MFA) and self-service password reset (SSPR) within Microsoft Entra ID. This policy safeguardes the registration process, treating it as any other application within Conditional Access policies. Organizations with combined registration enabled can leverage this feature to ensure that the registration process remains protected from unauthorized access or misuse.

This approach allows administrators to enforce strict security measures during registration, such as requiring users to use secure authenticator apps or enabling passwordless phone sign-in. By securing this entry point, organizations reduce the risk of malicious actors exploiting the registration process as a vulnerability to bypass security protocols.

For this policy, organizations must have combined registration activated for Multi-Factor Authentication (MFA) and Self-Service Password Reset (SSPR).

**o	BAS013-Allow-O365Apps-AllUsers-ApplicationEnforcedRestrictions**  
(Use application enforced restrictions for O365 apps)

This policy applies to unmanaged and managed non-compliant devices.

Prior to setting up this Conditional Access policy, pre-requisite changes are required in SharePoint Online and Exchange Online:

o	Block or limit access to a specific SharePoint site or OneDrive
o	Limit access to email attachments in Outlook on the web and the new Outlook for Windows
o	Enforce idle session timeout on unmanaged devices

Application enforced restrictions for O365 apps allow organizations to implement policies that enhance security and control over their data and resources. These policies can block or limit access to specific SharePoint sites or OneDrive, restrict access to email attachments in Outlook on the web and the new Outlook for Windows, and enforce idle session timeouts on unmanaged devices. By leveraging these application enforced restrictions, organizations can tailor their access controls to meet specific security needs and ensure that sensitive information remains protected, mitigating risks associated with unauthorized access and data breaches.

**o	BAS014-Block-AllApps-AllUsers-RequireCompliantDevice**  
(Require compliant devices for all users)

This policy, which mandates the use of compliant devices for all users, ensures that only devices meeting the organization's security standards can access applications and data. By enforcing compliance, the policy mitigates risks associated with unauthorized access and data breaches, thereby protecting sensitive information.

The reasoning behind this policy is rooted in creating a secure digital environment. Requiring compliant devices eliminates vulnerabilities posed by unmanaged and potentially compromised devices, as these may not adhere to the organization's security protocols.
By default, each policy created from templates in Entra ID is created in report-only mode. We recommended organizations test and monitor usage, to ensure the intended result, before turning on each policy.


**o	BAS015-Block-AllApps-AllUsers-DeviceFlowAuthenticationTransfer**  
(Block device code flow and authentication transfer for guest users)  

This policy restricts users from utilizing device code flow and authentication transfer methods within the organization's applications. Device code flow is a method where a user initiates authentication on one device and completes it on another, commonly used in scenarios where input capabilities are limited. Authentication transfer allows a user to authenticate in one application and then use that authentication token to access another application. By blocking these methods for users, the policy aims to enhance security and prevent unauthorized access through potentially vulnerable authentication pathways, ensuring that only appropriate authentication mechanisms are used for user access.
 
## Data sensitivity-based Access Control
 
![Picture6](/pics/Picture6.png) 

To access Confidential and Highly Confidential applications, we recommend the following policies:  

**o	DLP001-Block-AllApps-AllUsers-RequireCompliantSecureDeviceforCHCData**  
(Require compliant and secure access workstation for confidential and highly confidential data)  

This policy ensures secure access to confidential and highly confidential data by requiring compliant and secure workstations. The reasoning behind this approach lies in minimizing the risk of unauthorized access and safeguarding sensitive information within controlled environments. By mandating workstations that adhere to strict security protocols, it reduces vulnerabilities posed by devices that may lack adequate protections or contain unauthorized software.  

Prerequisites for implementing this policy include the availability of secure workstations specifically configured to limit the number and type of applications installed. These workstations must be tailored to handle sensitive data exclusively, excluding potentially risky components such as email clients. Additionally, organizations must ensure the proper configuration and maintenance of these workstations to guarantee their effectiveness in protecting critical resources.  

**o	DLP002-Allow-AllApps-AllUsers-PhisingResistantMFAforCHCData**  
(Require phising-resistent MFA for confidential and highly confidential data)  

This policy mandates the use of phishing-resistant multi-factor authentication (MFA) for accessing confidential and highly confidential data. It ensures that users provide multiple secure forms of verification, such as hardware tokens, which are challenging for attackers to compromise.  

The reasoning behind this approach lies in minimizing the risks associated with phishing attacks. By requiring advanced authentication mechanisms, the policy significantly reduces the likelihood of unauthorized access, thereby protecting sensitive information from potential threats, including financial loss, reputational damage, and legal consequences.  

Prerequisites for implementing this policy include the availability of hardware tokens or similar secure verification tools.  

**o	DLP003-Block-AllApps-Guests-BlockAccessToCHCData**  
(Block access to highly confidential apps for non-employees)  

By default, this policy blocks GuestsOrExternalUsers from accessing confidential or highly confidential data. The policy can be modified to also include groups of users which have an internal account in the organization but are considered to be externals, such as contractors with a temporary hire.  

**o	DLP004-Block-AllApps-AllUsers-AllowSpecificCountriesOnlyForCHCData**  
(Allow access to CHC data only from specific countries)  

This policy is based on a named location 'Countries allowed for CHC data access' which is created by the PowerShell script and includes US (United States) and CH (Switzerland) by default. To change the countries allowed to access confidential or highly confidential data, the named location object must be edited.  

These policies necessitate the use of custom security attributes to ensure implementation and control. The attribute set is named DataSensitivity. It contains a multi-value attribute Classification with the values Highly Confidential and Confidential. The attributes are assigned to registered apps which contain highly confidential or confidential information.

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
     
In Microsoft Entra, workload identities are applications, service principals, and managed identities.

**o	PER001-Block-AllApps-Admins-RequireSecureCompliantDevice**  
(Require compliant and secure access workstation for privileged Entra ID roles)  

This policy mandates that privileged Entra ID roles must utilize compliant and secure access workstations, commonly referred to as Privileged Access Workstations (PAWs). The purpose of this requirement is to enhance security measures for individuals holding roles with elevated permissions, reducing the risk of unauthorized access, credential compromise, or insider threats. By enforcing the use of PAWs, the policy ensures that privileged activities are conducted in a controlled and secure environment, isolated from general-purpose devices that may be more susceptible to vulnerabilities.  

The reasoning behind this policy lies in the critical nature of privileged accounts within any organization. These accounts often have access to sensitive systems, infrastructure, and data, making them attractive targets for cyberattacks. Implementing PAWs mitgates risks by providing a dedicated, hardened workstation designed specifically for high-security operations, thereby minimizing attack vectors and ensuring adherence to Zero Trust principles.  

Prerequisites for this policy include the physical availability of Privileged Access Workstations to users assigned privileged Entra ID roles. These users must possess and log into the PAWs before accessing Azure portals or elevating their identity through Privileged Identity Management (PIM). Without a compliant PAW, users will be unable to fulfill the requirements of this policy, necessitating a break glass scenario if access is urgently required. Additionally, the enforcement of this policy must align with organizational processes for provisioning PAWs and training users to utilize them effectively.  

**o	PER002-Block-AllApps-Externals-RequireCompliantSecureVDI**  
(Require compliant and secure VDI for external users)  

This policy ensures that external users accessing corporate services must do so through managed Virtual Desktop Infrastructure (VDI) session hosts if they are using unmanaged devices. By enforcing this requirement, the policy aims to safeguard corporate data and resources by providing an additional layer of security through controlled virtual environments. It can be applied to Guest and External Users or specific security groups, depending on organizational needs.  

The reasoning for implementing this policy lies in mitigating risks associated with unmanaged devices, which are often more vulnerable to security threats. By requiring access via managed VDI session hosts, organizations can isolate corporate environments from potential vulnerabilities present on external users' devices, adhering to Zero Trust principles and ensuring secure access.  

Prerequisites for this policy include enabling the Microsoft.DesktopVirtualization resource provider on at least one Azure subscription. This is necessary for selecting target resources such as Azure Virtual Desktop, Microsoft Remote Desktop, and Windows Cloud Login. Additionally, Microsoft Entra multifactor authentication must be enforced for Azure Virtual Desktop sessions via Conditional Access policies to maintain a robust security posture.  

**o	PER003-Block-AllApps-Admins-AllowSpecificCountriesOnly**  
(Allow privileged Entra ID roles only from specific countries)  

This policy restricts access to privileged Entra ID roles based on specific countries. The named location object titled 'Countries allowed for admin access' is created using a PowerShell script and includes the United States and Switzerland by default. Organizations can modify this named location object to include or exclude specific countries, ensuring that highly privileged users can only access administrative portals and services from designated locations.  

The reasoning behind this policy rests on enhancing security by limiting access to sensitive roles from approved geographical areas. Such restrictions reduce the risk of unauthorized access that might arise from compromised credentials or devices in non-approved regions.  

Prerequisites for implementing this policy include configuring the named location object through PowerShell to specify the allowed countries. Administrators must ensure that the object is correctly edited to reflect the organization's geographic security requirements.  

**o	PER004-Block-AllApps-Admins-HighUserRisk**  
(Block privileged users with high user risk)  

This policy blocks access for users who hold one or more of the 28 highly privileged Entra ID roles if they are identified as having a high user risk. Its purpose is to mitigate risks associated with compromised accounts that could lead to unauthorized access to sensitive resources and significant security breaches. Unlike the standard approach of requiring password changes for high-risk users, this policy emphasizes stringent access control measures for privileged accounts, ensuring a higher level of security.  

The reasoning behind this policy is rooted in the critical nature of privileged roles within an organization. Compromise of these roles can result in severe consequences as they often have extensive access and control over organizational resources. By blocking access for these users when high risk is detected, the policy minimizes the potential impact of malicious activity stemming from compromised credentials.
 
**o	PER005-Block-AllApps-Admins-HighSignInRisk**  
(Block privileged users with high sign-in risk)  

The policy blocks access for users who hold one or more of the 28 highly privileged Entra ID roles if they are identified as having a high sign-in risk. It is designed to mitigate the severe consequences that could arise if a highly privileged role is compromised, as these roles typically have extensive access and control within the organization. By blocking access outright, the policy ensures that the risk of unauthorized actions stemming from compromised credentials is significantly reduced.  

The reasoning behind this policy emphasizes the critical importance of privileged accounts and the potential impact of malicious activity. Simply applying multi-factor authentication again in such scenarios is deemed insufficient due to the elevated risks associated with these roles. Blocking access for users exhibiting high sign-in risk provides a robust safeguard against exploitation.  

![Picture9](/pics/Picture9.png)  
 
## Conditional Access Insights and Reporting  
The Conditional Access insights and reporting workbook enables you to understand the impact of Conditional Access policies in your organization over time. During sign-in, one or more Conditional Access policies might apply, granting access if certain grant controls are satisfied or denying access otherwise. Because multiple Conditional Access policies might be evaluated during each sign-in, the insights and reporting workbook lets you examine the impact of an individual policy or a subset of all policies.  

![Picture10](/pics/Picture10.png) 
