# 3. Terraform Basics

This section focuses on exam objectives and assumes a working knowledge of Terraform and its constructs. To review syntax and structure, see [Hello, Terraform](https://technicloud.com/2020/04/28/hello-terraform/). 

## Installing Terraform

Terraform can be installed using the user’s terminal: 

```
## Mac OS
brew install terraform

## Windows
choco install terraform
```

Alternatively, the Terraform can be manually installed by downloading the binary and moving it to the `/usr/local/bin/terraform` directory. 

The `terraform` block type can be used to configure specific Terraform behaviors. For example, a user can specify a minimum Terraform version to use. 

```
terraform {
 # ...
}

terraform {
 required_providers {
   aws = "~> 1.0"
 }
}
```

Within a `terraform` block, only constant values may be used. This means that arguments cannot reference named objects (e.g. resources or input variables) and cannot use any of the built-in functions.

## Managing Providers

Terraform uses a plugin-based architecture to support hundreds of infrastructure and service providers. Initializing a configuration directory downloads and installs providers used in the configuration. Terraform plugins are compiled for a specific operating system and architecture, and any plugins in the root of the user’s plugins directory must be compiled for the current system. A provider is a plugin that Terraform uses to translate the API interactions with that platform or service.

Anyone can develop and distribute their own Terraform providers. Any non-certified or third-party providers must be manually installed, since `terraform init` cannot automatically download them.

### Finding and Fetching Providers

Terraform must initialize a provider before it can be used. The initialization process downloads and installs the provider's plugin so that it can later be executed. Terraform knows which provider(s) to download based on what is declared in the configuration files. For example: 

```
provider "aws" {
 region  = "us-west-2"
}
```

The provider block can contain the following meta-arguments:

*   `version` - constrains which provider versions are allowed
    *   Note: HashiCorp recommends using [provider requirements](https://www.terraform.io/docs/configuration/provider-requirements.html) instead
*   `alias` - enables using the same provider with different configurations (e.g. provisioning resources in multiple AWS regions)

By default, a plugin is downloaded into a subdirectory of the working directory so that each working directory is self-contained. As a consequence, if there are multiple configurations that use the same provider then a separate copy of its plugin will be downloaded for each configuration. To manually install a provider, move it to:

```
## Mac OS
~/.terraform.d/plugins

## Windows
%APPDATA%\terraform.d\plugins
```

Given that provider plugins can be quite large, users can optionally use a local directory as a shared plugin cache. This is enabled through using the `plugin_cache_dir` setting in[ the CLI configuration file](https://www.terraform.io/docs/commands/cli-config.html).

```
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```

This configuration ensures each plugin binary is downloaded only once.

### Using Multiple Providers

To instantiate the same provider for multiple configurations, use the `alias` argument. For example, the AWS provider requires specifying the region argument. The following code block demonstrates how `alias` can be used to provision resources across multiple regions using the same configuration files. 

```
provider "aws" {
	region = "us-east-1"
}

provider "aws" {
	region = "us-west-1"
	alias = "ca"
}

resource "aws_vpc" "vpc-ca" {
	cidr_block = "10.0.0.0/16"
	provider   = "aws.ca"
}
```

Providers are released on a separate rhythm from Terraform itself, and so each provider has its own version number. For production use, consider constraining the acceptable provider versions in the configuration to ensure that new versions with breaking changes will not be automatically installed by `terraform init` in future.

## Versioning

The `required_version` setting can be used to constrain which versions of Terraform can be used with the configuration. If the current version of Terraform does not match the requirement, then a process will error and exit without taking actions. Here’s an example of dependency pinning for a version:

```
terraform {
  required_version = ">= 0.14.3"
}
```

Use `terraform --version` in a terminal to determine the current version. 

The value for `required_version` is a string containing a comma-delimited list of constraints. Each constraint is an operator followed by a version number. The following operators are allowed.

<table>
  <tr>
   <td><strong>Operator</strong>
   </td>
   <td><strong>Usage</strong>
   </td>
   <td><strong>Example</strong>
   </td>
  </tr>
  <tr>
   <td><code>=</code> (or no operator)
   </td>
   <td>Use exact version
   </td>
   <td><code>"= 0.14.3"</code>
<p>
Must use v0.14.3 
   </td>
  </tr>
  <tr>
   <td><code>!=</code>
   </td>
   <td>Version not equal
   </td>
   <td><code>"!=0.14.3"</code>
<p>
Must not use v0.14.3 
   </td>
  </tr>
  <tr>
   <td><code>></code> or <code>>=</code> or <code>&lt;</code> or <code>&lt;=</code>
   </td>
   <td>Version comparison
   </td>
   <td><code>">= 0.14.3"</code>
<p>
Must use a version greater than or equal to v0.14.3
   </td>
  </tr>
  <tr>
   <td><code>~></code>
   </td>
   <td>Pessimistic constraint operator that both both the oldest and newest version allowed
   </td>
   <td><code>"~>= 0.14"</code>
<p>
Must use a version greater than or equal to v0.14 but less than v0.15 (which includes v0.14.3)
   </td>
  </tr>
</table>

Similarly, a provider version requirement can be specified. The following is an example limited the version of AWS provider:

```
provider "aws" {
	region = "us-west-2"
	version = ">=3.1.0"
}
```

It is recommended to use these operators in production to avoid accidental upgrades. 

## Provisioners

Provisioners can be used to model specific actions on the local machine or on a remote machine. For example, a provisioner can enable uploading files, running shell scripts, or installing or triggering other software (e.g. configuration management) to conduct initial setup on an instance. Provisioners are defined within a resource block:

```
resource "aws_instance" "example" {
 ami           = "ami-b374d5a5"
 instance_type = "t2.micro"

 provisioner "local-exec" {
   command = "echo hello > hello.txt"
 }
}
```

Multiple provisioner blocks can be used to define multiple provisioning steps.

```
Note: HashiCorp recommends that provisioners should only be used as a last resort. 
```

### Types of Provisioners

This section will cover the various types of generic provisioners. There are also vendor specific provisioners for configuration management tools (e.g. Salt, Puppet). 

#### File

The file provisioner is used to copy files or directories from the machine executing Terraform to the newly created resource. 

```
resource "aws_instance" "web" {
  # ...

  provisioner "file" {
    source      = "conf/myapp.conf"
    destination = "/etc/myapp.conf"
  }
}
```

The file provisioner supports both ssh and winrm type connections.

#### `local-exec` 

The `local-exec` provisioner runs by invoking a process local to the user’s machine running Terraform. This is used to do something on the machine running Terraform, not the resource provisioned. For example, a user may want to create an SSH key on the local machine. 


```
resource "null_resource" "generate-sshkey" {
    provisioner "local-exec" {
        command = "yes y | ssh-keygen -b 4096 -t rsa -C 'terraform-kubernetes' -N '' -f ${var.kubernetes_controller.["private_key"]}"
    }
}
```

#### `remote-exec`

Comparatively, `remote-exec` which invokes a script or process on a remote resource after it is created. For example, this may be used to bootstrap a newly provisioned cluster or to run a script. 

```
resource "aws_instance" "example" {
 key_name      = aws_key_pair.example.key_name
 ami           = "ami-04590e7389a6e577c"
 instance_type = "t2.micro"

connection {
   type        = "ssh"
   user        = "ec2-user"
   private_key = file("~/.ssh/terraform")
   host        = self.public_ip
 }

provisioner "remote-exec" {
   inline = [
     "sudo amazon-linux-extras enable nginx1.12",
     "sudo yum -y install nginx",
     "sudo systemctl start nginx"
   ]
 }
}
```

Both SSH and winrm connections are supported.

### Provisioner Triggers

By default, provisioners are executed when the defined resource is created and during updates or other parts of the lifecycle. It is intended to be used for bootstrapping a system. If a provisioner fails at creation time, the resource is marked as tainted. Terraform will plan to destroy and recreate the tainted resource at the next `terraform apply` command. 

By default, when a provisioner fails, it will also cause the `terraform apply` command to fail. The `on_failure` parameter can be used to specify different behavior. 

```
resource "aws_instance" "web" {
 # ...

 provisioner "local-exec" {
   command  = "echo The server's IP address is ${self.private_ip}"
   on_failure = "continue"
 }
}

```
Note: Expressions in provisioner blocks cannot refer to the parent resource by name. Use the self object to represent the provisioner's parent resource (see previous example). 
```

Additionally, provisioners can also be configured to run when the defined resource is destroyed. This is configured by specifying when = “destroy” within the provisioner block. 

```
resource "aws_instance" "web" {
  # ...

  provisioner "local-exec" {
    when    = "destroy"
    command = "echo 'Destroy-time provisioner'"
  }
}
```

By default, a provisioner only runs at creation. To run a provisioned at deletion, it must be explicitly defined. 