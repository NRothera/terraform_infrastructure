provider "aws" {
  region="eu-central-1"
}

resource "aws_vpc" "default" {
  cidr_block       = "10.3.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags {
    Name = "nick-app"
  }
}

resource "aws_internet_gateway" "nick-app" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "nick-app"
  }
}

resource "aws_route_table" "nick-app" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.nick-app.id}"
  }
  tags {
    Name = "nick-app"
  }
}

data "template_file" "app_init" {
  template = "${file("./scripts/app_user_data.sh")}"
  vars {
    db_ip = "${module.db-tier.private_ip}"
  }
}

module "app-tier" {
  name = "nick-app"
  source= "./modules/tier"
  vpc_id="${aws_vpc.default.id}"
  cidr_block="10.3.1.0/24"
  user_data="${data.template_file.app_init.rendered}"
  ami_id = "ami-a0cfabcf"
  route_table_id = "${aws_route_table.nick-app.id}"
  map_public_ip_on_launch = true

  ingress = [{
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = "0.0.0.0/0"
  }]
}

module "db-tier" {
  name="db"
  source="./modules/tier"
  vpc_id="${aws_vpc.default.id}"
  route_table_id = "${aws_vpc.default.main_route_table_id}"
  cidr_block="10.3.2.0/24"
  user_data=""
  ami_id = "ami-f125429e"

  ingress = [{
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    cidr_blocks = "${module.app-tier.subnet_cidr_block}"
  }]
}
