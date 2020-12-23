# 4. Using the Terraform CLI

This section outlines scenarios to use certain CLI commands. See [Navigating the Terraform Workflow](/06-terraform-workflow.md) for information about common operations. 

## `terraform fmt`

The `terraform fmt` command is used to reformat Terraform configuration files in a canonical format and style. Using this command applies a subset of the Terraform language style conventions, along with other minor adjustments for readability. The following are common flags that may be used:



*   `terraform fmt -diff` - to output differences in formatting
*   `terraform fmt -recursive` - apply format to subdirectories
*   `terraform fmt -list=false` - when formatting many files across a number of directories, use this to not list files formatted using command

The canonical format may change between Terraform versions, so it is a good practice to proactively run `terraform fmt` after upgrading. This should be done on any modules along with other changes being made to adopt the new version.

## `terraform taint`

The `terraform taint` command manually marks a Terraform-managed resource as tainted, which marks the resource to be destroyed and recreated at the next `apply` command. Command usage resembles:

```
terraform taint [options] address

terraform taint aws_security_group.allow_all
```

To taint a resource inside a module: 

```
terraform taint "module.kubernetes.aws_instance.k8_node[4]"
```

The address argument is the address of the resource to mark as tainted. The address is in the [resource address syntax](https://www.terraform.io/docs/internals/resource-addressing.html). When tainting a resource, Terraform reads from the default state file (`terraform.tfstate`). To specify a different path, use:

```
terraform taint -state=path
```

This command does not modify infrastructure, but does modify the state file in order to mark a resource as tainted. Once a resource is marked as tainted, the next `plan` will show that the resource is to be destroyed and recreated. The next `apply` will implement this change.

Forcing the recreation of a resource can be useful to create a certain side-effect not configurable in the attributes of a resource. For example, re-running provisioners may cause a node to have a different configuration or rebooting the machine from a base image causes new startup scripts to execute.

The `terraform untaint` command is used to unmark a Terraform-managed resource as tainted, restoring it as the primary instance in the state.

```
terraform untaint aws_security_group.allow_all
```

Similarly, this command does not modify infrastructure, but does modify the state file in order to unmark a resource as tainted.

## `terraform import`

The `terraform import` command is used to import existing resources to be managed by Terraform. Effectively this imports existing infrastructure (created by other means) and allows Terraform to manage the resource, including destroy. The `terraform import` command finds the existing resource from ID and imports it into the Terraform state at the given `address`. Command usage resembles:

```
terraform import [options] address ID

terraform import aws_vpc.vpcimport vpc-0a1be46f8g9
```

The `ID` is dependent on the resource type being imported. For example, for AWS instances the `ID` resembles `i-abcd1234` whereas the zone `ID` for AWS Route53 resembles `L34ZFG4AUGOZ1M`.

Because any resource address is valid, the `import` command can import resources into modules as well directly into the root of state. Note that resources can be imported directly into modules.

## `terraform workspace`

Workspaces are technically equivalent to renaming a state file. Each Terraform configuration has an associated backend that defines how operations are executed and where persistent data (e.g. Terraform state) is stored. This persistent data stored in the backend belongs to a workspace. A default configuration has only one workspace named `default` with a single Terraform state. Some backends support multiple named workspaces, allowing multiple states to be associated with a single configuration. Command usage resembles:

```
terraform workspace list
terraform workspace new <name>
terraform workspace show
terraform workspace select <name>
terraform workspace delete <name>
```

Keep in mind that the `default` workspace cannot be deleted. Workspaces can be specified within configuration code. This example uses the workspace name as a tag. 

```
resource "aws_instance" "example" {
 tags = {
   Name = "web - ${terraform.workspace}"
 }

 # ... other arguments
}
```

A common use case for multiple workspaces is to create a parallel, distinct copy of a set of infrastructure in order to test a set of changes before modifying the main production infrastructure. For example, a developer working on a complex set of infrastructure changes might create a new temporary workspace in order to freely experiment with changes without affecting the default workspace.

For a local state configuration, Terraform stores the workspace states in a directory called `terraform.tfstate.d`.

## `terraform state`

There are cases in which the Terraform state needs to be modified. Rather than modify the state directly, the `terraform state` commands should be used instead. 

The `terraform state list` command is used to list resources within the state

The command will list all resources in the state file matching the given addresses (if any). If no addresses are given, then all resources are listed. To specify a resource:

```
terraform state list aws_instance.bar
```

The `terraform state pull` command is used to manually download and output the state from remote state. This command downloads the state from its current location and outputs the raw format to `stdout`. While this command also works with local state, it is not very useful because users can see the local file. 

The `terraform state mv` command is used to move items in the state. It can be used for simple resource renaming, moving items to and from a module, moving entire modules, and more. Because this command can also move data to a completely new state, it can be used to refactor one configuration into multiple separately managed Terraform configurations.

```
terraform state mv [options] SOURCE DESTINATION
terraform state mv 'aws_instance.worker' 'aws_instance.helper'
```

The `terraform state rm` command is used to remove items from the state. 

```
terraform state rm 'aws_instance.worker'
terraform state rm 'module.compute'
```

It is important to note that items removed from the Terraform state are not physically destroyed, these items are simply no longer managed by Terraform. For example, if an AWS instance is deleted from the state, the AWS instance will continue running, but `terraform plan` will no longer manage that instance.

## Verbose Logging

Terraform has detailed logs that can be enabled by setting the `TF_LOG` environment variable to any value. This will cause detailed logs to appear on stderr.

Users can set `TF_LOG` to one of the log levels `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` to change the verbosity of the logs. `TRACE` is the most verbose and it is the default if `TF_LOG` is set to something other than a log level name.

To persist logged output users can set `TF_LOG_PATH` in order to force the log to always be appended to a specific file when logging is enabled. Note that even if `TF_LOG_PATH` is set, `TF_LOG` must be set in order for any logging to be enabled.