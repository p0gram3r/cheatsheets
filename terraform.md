# The golden rule of Terraform
*The master branch of the live repository is a 1:1 representation of what’s actually deployed in production.*


## Preparation
- new, non-encrypted ssh key: `ssh-keygen -t ecdsa`
  - don't set passphrase, so automation tools can use it


## Workflow

```
# prepare
terraform init

# what's about to happen
terraform plan

# do the action
terraform apply
```


## State management
- current state is stored in a file called `tfstate`
  - either stored locally or on a central place (e.g. Amazon S3 bucket)
- use "import" command to define state of existing infrastructure
  - example: if you had created an IAM Role manually, you could define that IAM Role in a Terraform template using the aws_iam_role resource, run “terraform import” to tell Terraform to fetch the information for that IAM role and add it to its state file, and from then on, when you run “terraform plan”, Terraform will know that IAM Role already exists and not try to create it again.

## Modules
- any set of Terraform templates is a module
- to use a module in a template:
```
module "frontend" {
  source = "/modules/frontend-app"
}
```

#### Input variables
- declaration in module definition:
```
variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"  
}
variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  (...)
}
```

- definition in actual template
```
module "frontend" {
  source = "/modules/frontend-app"
  min_size = 1
  max_size = 2
}
```

#### Output variables
- modules can also have output variables! access using `module` prefix!
- declaration in module definition `/modules/frontend-app/outputs.tf`
```
output "asg_name" {
  value = "${aws_autoscaling_group.example.name}"
}
```

- usage in template:
```
module "frontend" {
  source = "/modules/frontend-app"
  min_size = 10
  max_size = 20
}

resource "aws_autoscaling_policy" "scale_out" {
  name = "scale-out-frontend-app"
  autoscaling_group_name = "${module.frontend.asg_name}"
  (...)
}
```

#### Module versioning
- if both your staging and production environment are pointing to the same module folder, changes in that folder will affect both environments on the very next deployment!
- solution: do not refer to local file path
  - Terraform supports other types of module sources, such as Git URLs, Mercurial URLs, and arbitrary HTTP URLs
- separate module and infrastructure templates into separate Git repos
  - `infrastructure-modules` = repo for modules. Use `git tag` to create a release with a specific version
  - `infrastructure-live` = repo for templates to define infrastructure
- to use a specific version:
```
module "frontend" {
  source = "git::git@github.com:gruntwork-io/infrastructure-modules.git/frontend-app?ref=v0.0.1"
  min_size = 1
  max_size = 2
}
```

#### Loading files within a module
- by default, Terraform interprets the path relative to the working directory
- use path variable in file paths to load a file that is part of the module
```
resource "aws_instance" "example" {
  ami = "ami-2d39803a"
  instance_type = "t2.micro"
  user_data = "${file("${path.module}/user-data.sh")}"
}
```

## Control statements and data types

#### Boolean
- in Terraform, a boolean true is converted to a 1 and a boolean false is converted to a 0
- use an unquoted true or false in Terraform code, it treats it as a 1 or 0, respectively

#### List
-
```
variable "azs" {
  description = "Run the EC2 Instances in these Availability Zones"
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

- to access a particular element:
```
availability_zone = "${element(var.azs, 2)}"
```

- element access will wrap automatically (using a mod function) if index is greater than list size
  - in a 3 element array: index 3 = 0; 4 = 1; ...


#### for-loops
- Terraform resource has a “meta-parameter” you can use called “count”. This parameter defines how many copies of the resource to create:
```
resource "aws_instance" "example" {
  count = 3
  ami = "ami-2d39803a"
  instance_type = "t2.micro"
}
```

- To set individual properties, use the `count.index` property:
```
resource "aws_instance" "example" {
  count = 3
  ami = "ami-2d39803a"
  instance_type = "t2.micro"

  tags {
    Name = "example-${count.index}"
  }
}
```

- once you’ve used count on a resource, it becomes a list of resources, rather than just one resource
  - use the “splat” syntax (`TYPE.NAME.*.ATTRIBUTE`) to define output variables
  ```
  output "public_ips" {
    value = ["${aws_instance.example.*.public_ip}"]
  }
  ```

- count has a significant limitation: you cannot use dynamic data
  - “dynamic data” = any data that is fetched from a provider (e.g. AWS) or is only available after a resource has been created (e.g. an output attribute of an EC2 Instance)
  - The cause is that Terraform tries to resolve all the count parameters BEFORE fetching any dynamic data

#### if-statements
- basically a for-loop with count 0 or 1:
```
resource "aws_eip" "example" {
  count = "${var.create_eip}"
  instance = "${aws_instance.example.id}"
}
```

#### if-else-statements
- use simple math in interpolation to calculate the value of `count`
```
resource "aws_eip" "thenBlock" {
  count = "${var.create_eip}"
  (...)
}
resource "aws_route53_record" "elseBlock" {
  count = "${1 - var.create_eip}"
  (...)
}
```

#### replace function
- replaces all instances of search in string with replacement. If search is wrapped in forward slashes, it is treated as a regular expression
```
replace(string, search, replacement)
```

- can be used to create conditions (1 and 0) as input for "if-statements":
```
count = "${replace(replace(var.instance_type, "/^[^t].*/", "0"), "/^t.*$/", "1")}"
```

#### concat function
- combines two lists into one:
```
user_data = "${element(concat(data.template_file.list_a.*.rendered, data.template_file.list_b.*.rendered), 0)}"
```

## Misc
- use `terraform fmt` command to format all files using the default Terraform code style. Ideally as pre-commit hook
- Terratest - a library for running automated tests against your infrastructure
- use `terraform plan -out=my.plan` to save the output of the plan command and `terraform apply my.plan` to run exactly these changes


## Additional material
- (A Comprehensive Guide to Terraform)[https://blog.gruntwork.io/a-comprehensive-guide-to-terraform-b3d32832baca]
