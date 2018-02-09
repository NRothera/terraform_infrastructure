variable "vpc_id" {
  description = "The VPC ID to launch the tiered architecture into"
}

variable "map_public_ip_on_launch" {
  default = false
}

variable "cidr_block" {
  description = "The CIDR block to launch the tiered architecture into"
}

variable "name" {
  description = "name to be used for tagging instances"
}

variable "user_data" {
  description = "user data to supply to the instance"
}

variable "route_table_id" {
  description = "table data to supply to the instance"
}

variable "ami_id" {
  description = "ami id for instance"
}

variable "ingress" {
  type = "list"
}
