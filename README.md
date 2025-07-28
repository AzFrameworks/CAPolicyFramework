

Version 1.1.1 Final

Daniel Metzger
Cloud Solution Architect Identity & Security
Microsoft Switzerland GmbH
 
## About this Conditional Access Framework

Careful planning of your Conditional Access deployment is important to implementing your organization's access strategy for applications and resources. In today's mobile-first, cloud-first environment, users access your organization's resources from various locations, devices, and applications. Consequently, focusing solely on who can access a resource is insufficient. Considerations must also include the user’s location, the device being used, the specific resource in question, and other relevant factors.

Microsoft Entra Conditional Access (CA) utilizes signals such as user identity, device, and location to make automated decisions and enforce access policies tailored to your organization. These CA policies can apply access controls like multifactor authentication (MFA). By utilizing CA policies, organizations can prompt users for MFA when necessary, thereby enhancing security while ensuring a seamless user experience.

![Picture1](/pics/Picture1.png)
 
This document introduces a base Conditional Access framework, which builds on templates available in Entra ID but adds additional policies to secure administrative work with highly privileged Entra ID roles and to safeguard access to sensitive data. The framework is thought to be a starting point for an implementation which covers all users. Customers most certainly will add more policies to meet specific needs, and not all policies in this framework will be enabled in all environments from the start.

The primary purpose of this framework is to provide guidelines on how to configure baseline policies to enhance security while maintaining operational efficiency. For instance, it recommends excluding break-glass accounts from all Conditional Access policies to prevent accidental lockouts. Additionally, it emphasizes the importance of setting policies to Report-only mode initially, allowing organizations to monitor the impact of these policies before enforcing them.

The framework leverages the capabilities of Microsoft Entra Conditional Access, enabling organizations to enforce their access policies based on various signals such as user identity, device type, and location. By using these signals, organizations can automate their access decisions, ensuring that security measures like multifactor authentication (MFA) are applied when necessary.

To facilitate the rapid deployment of this Conditional Access framework, a PowerShell script is available. This script streamlines the process, allowing for swift implementation without the need for in-depth manual configuration. It ensures that your access policies are applied efficiently and effectively, enhancing the security of your organization's resources.
 
## The Conditional Access funnel model

![Picture2](/pics/Picture2.png) 

![Picture3](/pics/Picture3.png) 

 
## Baseline policies
Exclude break-glass and directory sync accounts from all Conditional Access policies to prevent accidental lockouts. Break-glass accounts ensure admin access in emergencies, while directory sync accounts must remain unaffected for seamless identity synchronization.
Always set policies to Report-only mode first to monitor their impact before enforcing them. Analyze sign-in logs and Conditional Access insights to prevent disruptions.

![Picture4](/pics/Picture4.png) 
 
**o	BAS001-Block-AllApps-AllUsers-UnsupportedPlatform**  
(Block access for unknown or unsupported device platform)  

Users are blocked from accessing company resources when the device type is unknown or unsupported.

The device platform condition is based on user agent strings. Conditional Access policies using it should be used with another policy, like one requiring device compliance or app protection policies.

**o	BAS002-Block-O365Apps-AllUsers-ElevatedInsiderRisk**  
(Block access to Office365 apps for users with insider risk)  

Most users have a normal behavior that can be tracked. When they fall outside of this norm it could be risky to allow them to sign in. Organizations might want to block that user or ask them to review a specific terms of use policy. Microsoft Purview can provide an insider risk signal to Conditional Access to refine access control decisions. Insider risk management is part of Microsoft Purview. You must enable it before you can use the signal in Conditional Access.

**o	BAS003-Block-AllApps-Guests-AdminPortals**  
(Block guest user access to admin portals)

Blocks GuestsOrExternalUsers from accessing the 'MicrosoftAdminPortals' resources.

**o	BAS004-Block-AllApps-AllUsers-LegacyAuth**  
(Block legacy authentication)

Microsoft recommends that organizations block authentication requests using legacy protocols that don't support multifactor authentication. Based on Microsoft's analysis more than 97 percent of credential stuffing attacks use legacy authentication and more than 99 percent of password spray attacks use legacy authentication protocols. These attacks would stop with basic authentication disabled or blocked.

**o	BAS005-Allow-AllApps-AllUsers-NoPersistentBrowser**  
(No persistent browser session)

Protect user access on unmanaged devices by preventing browser sessions from remaining signed in after the browser is closed and setting a sign-in frequency to 1 hour.

**o	BAS006-Allow-AllApps-AllUsers-RequireApprovedClientApps**  
(Require approved client apps or app protection policies)

People regularly use their mobile devices for both personal and work tasks. While making sure staff can be productive, organizations also want to prevent data loss from applications on devices they may not manage fully. With Conditional Access, organizations can restrict access to approved (modern authentication capable) client apps with Intune app protection policies. For older client apps that may not support app protection policies, administrators can restrict access to approved client apps.

**o	BAS007-Block-AllApps-Admins-RequireCompliantDevice**  
(Require compliant device for administrators)

Microsoft Intune and Microsoft Entra work together to secure your organization through device compliance policies and Conditional Access. Device compliance policies are a way to ensure user devices meet minimum configuration requirements. The requirements can be enforced when users access services protected with Conditional Access policies.

**o	BAS008-Allow-AllApps-AllUsers-RequireMFA**  
(Require multifactor authentication for all users)

Microsoft provides multiple templates in Entra ID to configure multifactor authentication (MFA).

o	Require multifactor authentication for admins
o	Require multifactor authentication for Azure Management
o	Require multifactor authentication for guest access
o	Require multifactor authentication for all users

Implementing multifactor authentication (MFA) for all users, rather than for only a subset, is highly advisable as it substantially enhances organizational security by incorporating an additional layer of protection against unauthorized access. MFA necessitates that users provide multiple forms of verification prior to accessing sensitive information, thereby mitigating the risk of account compromise due to stolen passwords or other credentials.

**o	BAS009-Allow-AllApps-AllUsers-MFAforRiskySignIns**  
(Require multifactor authentication for risky sign-ins)

Requiring multifactor authentication for risky sign-ins serves as an effective measure to ensure the authenticity of user identity during sessions that deviate from established behavioral norms.

A sign-in risk represents the probability that a given authentication request isn't the identity owner. Organizations with Microsoft Entra ID P2 licenses can create Conditional Access policies incorporating Microsoft Entra ID Protection sign-in risk detections.
The Sign-in risk-based policy protects users from registering MFA in risky sessions. If users aren't registered for MFA, their risky sign-ins are blocked, and they see an AADSTS53004 error.

**o	BAS010-Allow-AllApps-AllUsers-PasswordChangeForHighRiskUsers**  
(Require password change for high-risk users)

Mandating password changes for high-risk accounts is a precautionary measure. This approach helps address the potential compromise of credentials, which might be indicated by breaches or other malicious activities. By requiring such changes, organizations can mitigate the risk of unauthorized access to sensitive systems and data, strengthening their overall security posture.

**o	BAS011-Allow-AllApps-Admins-PhisingResistentMFA**  
(Require phishing-resistant multifactor authentication for administrators)

Implementing phishing-resistant MFA significantly reduces the likelihood of unauthorized access compared to traditional MFA. Unlike normal MFA, which relies on methods such as SMS codes or basic authentication apps, phishing-resistant MFA employs stronger mechanisms such as hardware-based security keys, biometrics, or certificate-based authentication. These methods are inherently resistant to common phishing techniques and ensure that attackers cannot bypass authentication even if credentials are compromised.

![Picture5](/pics/Picture5.png) 
 
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

**o BAS015Block-AllApps-AllUsers-DeviceFlowAuthenticationTransfer**
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

**[DEPRECATED] o	PER006-Block-AllApps-Guests-DeviceFlowAuthenticationTransfer**  
(Block device code flow and authentication transfer for guest users)  

This policy restricts guest users from utilizing device code flow and authentication transfer methods within the organization's applications. Device code flow is a method where a user initiates authentication on one device and completes it on another, commonly used in scenarios where input capabilities are limited. Authentication transfer allows a user to authenticate in one application and then use that authentication token to access another application. By blocking these methods for guest users, the policy aims to enhance security and prevent unauthorized access through potentially vulnerable authentication pathways, ensuring that only appropriate authentication mechanisms are used for guest user access.
 
## Conditional Access Insights and Reporting  
The Conditional Access insights and reporting workbook enables you to understand the impact of Conditional Access policies in your organization over time. During sign-in, one or more Conditional Access policies might apply, granting access if certain grant controls are satisfied or denying access otherwise. Because multiple Conditional Access policies might be evaluated during each sign-in, the insights and reporting workbook lets you examine the impact of an individual policy or a subset of all policies.  

![Picture10](/pics/Picture10.png) 
