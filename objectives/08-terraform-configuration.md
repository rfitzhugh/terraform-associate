# 8. Reading, Generating, and Modifying Configuration

This section focuses on exam objectives and assumes a working knowledge of Terraform and its data model. To review syntax and structure, see [Hello, Terraform](https://technicloud.com/2020/04/28/hello-terraform/). 

## Inputs and Outputs

This section outlines input and output variables and their usage.

### Input Variables

Input variables are a means to parameterize Terraform configurations. This is particularly useful for abstracting away sensitive values. These are defined using the variable block type:

```
variable "region" {
 default = "us-east-2"
}
```

To then reference and use this variable, the syntax is `var.region` (in this example). See usage below:

```
provider "aws" {
 region = var.region
}
```

There are three ways to assign configuration variables: 

*   **Command-line flags** - use a command similar to `terraform apply -var 'region=us-east-2'`
*   **File** - for persistent variable values, create a file called `terraform.tfvars` with the variable assignments; different files can be created for different environments (e.g. dev or prod)
*   **Environment variables** - Terraform reads environment variables in the form of `TF_VAR_name` to find the variable value. For example, the `TF_VAR_region` variable can be set in the shell to set the Terraform variable for a region
    *   Environment variables can only populate string-type variables; list and map type variables must be populated using another mechanism.
*   **Interactively** - if `terraform apply` is executed with any variable unspecified, Terraform prompts users to input the values interactively; while these values are not saved, it does provide a convenient workflow when getting started

Strings and numbers are the most commonly used variables, but lists (arrays) and maps (hashtables or dictionaries) can also be used. Lists are defined either explicitly or implicitly, shown in the following example.

```
## Declare implicitly by using brackets []
variable "cidrs" { 
  default = []
}

## Declare explicitly with 'list'
variable "cidrs" { 
  type = list 
}

## Specify list values in terraform.tfvars file
cidrs = [ "10.0.0.0/16", "10.1.0.0/16" ]
```

A map is a key/value data structure that can contain other keys and values. Maps are a way to create variables that are lookup tables. 

```
## Declare variables
variable "region" {}
variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-b374d5a5"
    "us-west-2" = "ami-fc0b939c"
  }
}

## Reference variables
resource "aws_instance" "example" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"
}
```

The above mechanisms for setting variables can be used together in any combination. If the same variable is assigned multiple values, Terraform uses the last value it finds, overriding any previous values. Terraform loads variables in the following order, with later sources taking precedence over earlier ones:

1. environment variables
2. the `terraform.tfvars` file, if present
3. the `terraform.tfvars.json` file, if present
4. any `*.auto.tfvars` or `*.auto.tfvars.json` files, processed in lexical order of their filenames
5. any `-var` and `-var-file` options on the command line, in the order provided (this includes variables set by a Terraform Cloud workspace)

Note that the same variable cannot be assigned multiple values within a single source.

### Output Variables

An output variable is a way to organize data to be easily queried and shown back to the Terraform user. Outputs are a way to tell Terraform what data is important and should be referenceable. This data is output when `apply` is called and can be queried using the terraform output command.

```
## Define Resources
resource "aws_instance" "example" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.example.id
}

## Define Output
output "ip" {
  value = aws_eip.ip.public_ip
}
```

The example specifies to output the `public_ip` attribute. Run `terraform apply` to populate the output. The output can also be viewed by using the `terraform output ip` command, with `ip` in this example referencing the defined output. 

### Managing Secrets

Some providers, such as AWS, allow users to store credentials in a separate configuration file. It is a good practice in these instances to store credential keys in a config file such as `.aws/credentials` and not in the Terraform code. 

Vault is a secrets management system that allows users to secure, store and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API.

It is recommended that the `terraform.tfstate` or `.auto.tfvars` files should be ignored by Git when committing code to a repository. The `terraform.tfvars` file may contain sensitive data, such as passwords or IP addresses of an environment that should not be shared with others.

## Common Constructs

This section outlines common data model constructs and their usage.

### Resource Configuration

Resources are the most important element in the Terraform language. Each resource block describes one or more infrastructure objects, such as a compute instance. 

```
resource "aws_instance" "web" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"
}
```

A resource block declares a resource of a given type (`"aws_instance"`) with a given local name (`"web"`). The name is used to refer to this resource from elsewhere in the same Terraform module. 

#### Addressing

A Resource Address is a string that references a specific resource in a larger infrastructure. An address is made up of two parts:

```
[module path][resource spec]
```

A resource spec addresses a specific resource in the config. It takes the form of:

```
resource_type.resource_name[resource index]
```

In which these constructs are defined as:

*   `resource_type` - type of the resource being addressed
*   `resource_name` - user-defined name of the resource
*   `resource index]` - an optional index into a resource with multiple instances, surrounded by square braces `[` and `]`.

For full reference to values, see [here](https://www.terraform.io/docs/configuration/expressions/references.html). 

#### Dynamic Blocks

Some resource types include repeatable nested blocks in their arguments. Users can dynamically construct repeatable nested blocks like `setting` using a special `dynamic` block type, which is supported inside `resource`, `data`, `provider`, and `provisioner` blocks:

```
resource "aws_elastic_beanstalk_environment" "bean" {
  name                = "tf-beanstalk"
  application         = "${aws_elastic_beanstalk_application.tftest.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.11.4 running Go 1.12.6"

  dynamic "setting" {
    for_each = var.settings
    content {
      namespace = setting.value["namespace"]
      name = setting.value["name"]
      value = setting.value["value"]
    }
  }
}
```

A `dynamic` block acts similar to a `for` expression, but instead produces nested blocks rather than a complex typed value. It iterates over a given complex value, and generates a nested block for each element of that complex value.

### Data Sources

Data Sources are the way for Terraform to query a platform (e.g. AWS) and retrieve data (e.g. API request to get information). The use of data sources enables Terraform configuration to make use of information defined outside of this Terraform configuration. A provider determines what data sources are available alongside its set of resource types.

```
data "aws_ami" "example" {
  most_recent = true

  owners = ["self"]
  tags = {
    Name   = "app-server"
    Tested = "true"
  }
}
```

A data block lets Terraform read data from a given data source type (`aws_ami`) and export the result under the given local name (`example`). Data source attributes are interpolated with the syntax `data.TYPE.NAME.ATTRIBUTE`. To reference the data source example above, use `data.aws_ami.example.id`.

### Built-in Functions

The Terraform language includes a number of built-in functions that you can call from within expressions to transform and combine values. The general syntax for function calls is a function name followed by comma-separated arguments in parentheses:

```
max(5, 12, 9)
```

The following is a non-exhaustive list of built-in functions:

*   `filebase64(path)` - reads the contents of a file at the given path and returns as a base64-encoded string
*   `formatdate(spec, timestamp)` - converts a timestamp into a different time format
*   `jsonencode({"hello"="world"})` - encodes a given value to a string using JSON syntax
*   `cidrhost("10.12.127.0/20", 16)` - calculates a full host IP address for a given host number within a given IP network address prefix
*   `file` - reads the contents of a file and returns as a string
*   `flatten` - takes a list and replaces any elements that are list with a flattened sequence of the list contents
*   `lookup` - retrieves the value of a single element from a map, given its key. If the given key does not exist, a the given default value is returned instead

Note: The Terraform language does not support user-defined functions, therefore only the built-in functions are available for use.

## Structural Types

A complex type groups multiple values into a single value. There are two categories of complex types:

*   **Collection types** for grouping _similar_ values
    *   `list(...)` - a sequence of values identified by consecutive whole numbers starting with zero
    *   `map(...)` - a collection of values where each is identified by a string label
    *   `set(...)` - a collection of unique values that do not have any secondary identifiers or ordering
*   **Structural types** for grouping potentially _dissimilar_ values
    *   `object(...)` - a collection of named attributes that each have their own type
    *   `tuple(...)` - a sequence of elements identified by consecutive whole numbers starting with zero, where each element has its own type

This section outlines structural types. For more information about complex types, see [here](https://www.terraform.io/docs/configuration/types.html#complex-types).

### Tuples

The difference between a tuple and a list is that a list requires one type (string or numbers) to be specified. Comparatively, tuples enable the use of multiple data-types. The schema for tuple types is `[<TYPE>, <TYPE>, ...]` with a pair of square brackets containing a comma-separated series of types.

```
variable "tuple" {
    type = tuple([string, number, bool])
    default = ["beer", 8, true]
}
```

A tuple type of `tuple([string, number, bool])` would match a value like `["beer", 8, true]`.

### Objects

The difference between objects and maps is that a map requires one type (string or numbers) to be specified. Comparatively, objects enable the use of multiple data-types. The schema for object types is `{ <KEY> = <TYPE>, <KEY> = <TYPE>, ... }` with a pair of curly braces containing a comma-separated series of `<KEY> = <TYPE>` pairs.

```
variable "object" {
    type = object({name = string, port = list(number)})
    default = {
        name = "example"
        port = [22, 80, 8080]
    }
}
```

Both objects and tuples enable users to have multiple values of several distinct types to be grouped as a single value.