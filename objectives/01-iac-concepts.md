# 1. Infrastructure as Code Concepts (IaC)

This section outlines concepts specific to infrastructure as code but not necessarily exclusive to Terraform. 

## Introduction to IaC

Infrastructure as Code (IaC) enables users to define, provision, manage, and deprovision infrastructure (e.g. compute, network, storage, firewalls) defined as code within definition file(s). Customers can achieve consistent and predictable environments through the use of a high-level configuration syntax (i.e. data model) and version control of infrastructure definitions. The use of version control ensures that infrastructure can be shared and reused and enables GitOps. 

The following outlines the core concepts associated with IaC:

*   **Defined in code** - infrastructure is described using a high-level configuration syntax
*   **Stored with version control** - source of truth for the desired configuration of infrastructure
*   **Idempotent and consistent** - this means that even if the code is applied multiple times, the result remains the same

This new provisioning and management model can be used throughout the infrastructure lifecycle, from initial provisioning and configuration to programmatic deprovisioning of resources. 

## IaC Patterns

IaC makes it easy to provision and apply infrastructure configurations by standardizing the workflow. This is accomplished by using a common syntax across a number of different infrastructure providers (e.g. AWS, GCP). 

*   **Systems are disposable** - [immutable infrastructure](https://technicloud.com/2018/01/09/delving-into-immutable-infrastructure/) restricts the impact of undocumented (made outside of version control) changes, this ensures consistency of configuration
*   **Reusable components** - write configuration using [DRY principle](https://thevaluable.dev/dry-principle-cost-benefit-example/); break the infrastructure into small modules that are reused
*   **Documented architecture** - code acts as source of truth for configuration, only minimal additional documentation required