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
  ami_id = "ami-0a94f865"
  route_table_id = "${aws_route_table.nick-app.id}"
  map_public_ip_on_launch = true
  machine_count = 2

  ingress = [{
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = "0.0.0.0/0"
  }]
}

module "db-tier" {
  name="nick-db"
  machine_count = 1
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

resource "aws_elb" "nick-load" {
  name               = "nick-load-balancing"



  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${module.app-tier.app_id}"]
  subnets = ["${module.app-tier.elb_security}"]
  security_groups = ["${module.app-tier.security_id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "nick-terraform-elb"
  }
}

resource "aws_launch_configuration" "as_conf" {
  name          = "nick-launch"
  image_id      = "ami-0a94f865"
  instance_type = "t2.micro"
  user_data     = "${data.template_file.app_init.rendered}"
  security_groups = ["${module.app-tier.security_id}"]

}


resource "aws_autoscaling_group" "nick-scaling" {


  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.as_conf.name}"
  load_balancers            = ["${aws_elb.nick-load.name}"]
  vpc_zone_identifier       = ["${module.app-tier.elb_security}"]
  wait_for_capacity_timeout = "6m"

  tag {
    key                 = "Name"
    value               = "nick-elb-scaling"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

}
