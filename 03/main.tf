data "aws_vpc" "vpc" {
    tags = {
        Name = "nova-vpc-test-use1"
    }
}

data "aws_subnet" "subnet" {
    tags = {
        Name = "nova-vpc-test-private-01-use1"
    }
}

resource "aws_instance" "example" {
  ami           = "ami-b374d5a5"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.subnet.id

  tags = {
    Name = "nova-rf-tfexam"
  }
}

resource "aws_instance" "import" {
  ami           = "ami-b374d5a5"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.subnet.id

  tags = {
    Name = "nova-rf-tfexam-import"
  }
}