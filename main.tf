provider "aws" {
  region="eu-central-1"
}

data "template_file" "app_init" {
  template = "${file("./scripts/app_user_data.sh")}"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.3.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags {
    Name = "nick-app"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "main"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
  tags {
    Name = "main"
  }
}

module "app-tier" {
  name = "nick-app"
  source= "./modules/tier"
  vpc_id="${aws_vpc.main.id}"
  cidr_block="10.3.0.0/24"
  user_data="${data.template.app_init.rendered}"
  ami_id = "ami-a0cfabcf"
  route_table_id = "${aws_route_table.r.id}"
}
