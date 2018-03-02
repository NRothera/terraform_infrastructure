provider "aws" {
  region="eu-west-1"
}

resource "aws_vpc" "default" {
  cidr_block       = "10.0.0.0/16"

  tags {
    Name = "default"
  }
}

resource "aws_internet_gateway" "app-example" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "app-example"
  }
}

resource "aws_route_table" "app-example" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.app-example.id}"
  }

  tags {
    Name = "public-example"
  }
}


data "template_file" "app_init" {
  template = "${file("./scripts/app_user_data.sh")}"
}

module "app-tier" {
  name="app"
  source="./modules/tier"
  vpc_id="${aws_vpc.default.id}"
  route_table_id = "${aws_route_table.app-example.id}"
  cidr_block="10.0.0.0/24"
  user_data="${data.template_file.app_init.rendered}"
  ami_id = "ami-d3a3c8aa"
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
  cidr_block="10.0.1.0/24"
  user_data=""
  ami_id = "ami-d3a3c8aa"

  ingress = [{
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    cidr_blocks = "${module.app-tier.subnet_cidr_block}"
  }]
}

