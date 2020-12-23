# 9. Terraform Cloud and Enterprise Capabilities

Terraform Cloud (TFC) is a freemium, self-service SaaS platform that extends the capabilities of the open source Terraform CLI and adds collaboration and automation features. An overview of features and capabilities can be found [here](https://technicloud.com/2020/07/09/easy-collaboration-with-terraform-cloud/). 

## OSS versus Terraform Cloud

<table>
  <tr>
   <td><strong>Construct</strong>
   </td>
   <td><strong>OSS</strong>
   </td>
   <td><strong>Terraform Cloud</strong>
   </td>
   <td><strong>Enterprise</strong>
   </td>
  </tr>
  <tr>
   <td>Terraform Configuration
   </td>
   <td>Local or version control repo
   </td>
   <td>Version control repo or periodically updated via CLI/API
   </td>
   <td rowspan="4" >Same as Terraform Cloud, but also has the following features:
<ul>

<li>SAML/SSO

<li>Audit Logs

<li>Private Network Connectivity

<li>Clustering
</li>
</ul>
   </td>
  </tr>
  <tr>
   <td>Variable Values
   </td>
   <td>As .tfvars file, as CLI arguments, or in shell environment
   </td>
   <td>In workspace
   </td>
  </tr>
  <tr>
   <td>State
   </td>
   <td>On disk or in remote backend
   </td>
   <td>In workspace
   </td>
  </tr>
  <tr>
   <td>Credential and Secrets
   </td>
   <td>In shell environments or prompted
   </td>
   <td>In workspace, stored as sensitive variables
   </td>
  </tr>
</table>

## Sentinel

Sentinel is a policy as code framework that enables the same practices to be applied to enforcing and managing policy as used for infrastructure. These policies fall into a few categories:

*   Compliance - ensuring adherence to external standards like GDPR or PCI-DSS
*   Security - ensuring protection of data privacy and infrastructure integrity (i.e. exposing only certain ports)
*   Operational Excellence - preventing outages or service degradations (i.e. n+1 minimums)

Sentinel has been integrated into Terraform Enterprise. Find out more information about Sentinel [here](https://www.hashicorp.com/sentinel). 

## Module Registry

The [Module Registry](https://registry.terraform.io/) gives Terraform users easy access to templates for setting up and running infrastructure with verified and community modules.

Terraform Cloud's private module registry helps users share Terraform modules across an organization. It includes support for module versioning, a searchable and filterable list of available modules, and a configuration designer to help users build new workspaces faster.

By design, the private module registry works similarly to the public registry. 

## Workspaces

Using Terraform CLI, it is the working directory used to manage collections of resources. But, this is where Terraform Cloud differs: workspaces are used to collect and organize infrastructure instead of directories. A workspace contains everything Terraform needs to manage a given collection of infrastructure, and separate workspaces function like completely separate working directories.

```
Note: Terraform Cloud and Terraform CLI both have features called workspaces, but the features are slightly different. CLI workspaces are alternate state files in the same working directory; a convenience feature for using one configuration to manage multiple similar groups of resources.
```