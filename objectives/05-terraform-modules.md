# 5. Interacting with Terraform Modules

A Terraform module is a set of .tf configuration files contained in a single directory. When Terraform commands are run directly from such a directory, it is considered the root module. Thus, every Terraform configuration could be considered part of a module. This structure may resemble the following:

```
project-terraform-files/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
```

Modules are loaded from a local or remote source. Terraform supports a variety of remote sources, including the Terraform Registry, most version control systems, HTTP URLs, and Terraform Cloud or Terraform Enterprise private module registries. The following types of modules are commonly used: 

*   **Root Module** - exists for every Terraform configuration, consists of resources defined in the .tf files in the main working directory
*   **Child Module** - module that has been referenced by another module; a module (usually root) can reference (i.e. call) other modules to include their resources in the configuration
*   **Published Module** - module that has been made available through a public or private registry

When using child modules, the file structure may resemble 

```
project-terraform-files
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
│
└─── module-example01
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   
└─── module-example02
│   ├── provider.tf
│   ├── data-sources.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
```

The `../project-terraform-files/main.tf` file would contain references to the child modules. A local path begins with either `./` or `../` to indicate that a local path is intended:

```
module "vpc" {
  source = "./vpc"
}
```

The [Terraform Registry](https://registry.terraform.io/) makes it easy to find and use HashiCorp verified modules. By default, only verified modules are shown in search results, however, unverified modules can be viewed by using the filters. 

Modules on the public Terraform Registry can be referenced using a registry source address of the form `&lt;NAMESPACE>/&lt;NAME>/&lt;PROVIDER>`, as shown in the following example:

```
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>= 2.0"	
}
```

For modules hosted in other registries, add the source address with a `&lt;HOSTNAME>/` prefix:

```
module "vpc" {
  source = "github.com/example/tf-modules/vpc"
  version = "2.64.0"
}
```

After adding a module or subdirectory to a Terraform configuration, remember to execute again `terraform init` to initialize the module. The modules are downloaded and stored in the `.terraform/modules` directory. For additional registry examples, please visit [Module Sources](https://www.terraform.io/docs/modules/sources.html). 

## Versioning

Each module in the registry is versioned. These versions syntactically must follow [semantic versioning](http://semver.org/).

## Inputs, Outputs, and Variables

The configuration that calls a module is responsible for setting the input values, which are passed as arguments in the module block. Input variables serve as parameters for a Terraform module, allowing aspects of the module to be customized without modifying the module’s code. It is common that most of the arguments to a module block will set variable values. Input variables allow modules to be shared between different configurations. 

When navigating the Terraform Registry, there is an Inputs tab for each module that describes all of the [input variables](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.21.0?tab=inputs) supported.

```
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = var.name_env
  }
}
```

A resource defined in a module is encapsulated, so referencing the module cannot directly access its attributes. A child module can declare an output value to export select values to be accessible by the parent module. The contents of the `outputs.tf` file may contain code block(s) similar to:  

```
output "vpc_public_subnets" {
  description = "IDs of the VPC's public subnets"
  value       = module.vpc.public_subnets
}
```

Module outputs are typically passed to other parts of the Terraform configuration or defined as outputs in the root module. Wherein, the output values are specified as: 

```
module.<MODULE NAME>.<OUTPUT NAME>
```

More information about modules can be found [here](https://www.terraform.io/docs/configuration/blocks/modules/index.html).