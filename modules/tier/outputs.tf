output "subnet_cidr_block" {
  value = "${var.cidr_block}"
}

output "private_ip" {
    value = "${aws_instance.app.*.private_ip[0]}"
}

output "app_id" {
  value = "${aws_instance.app.*.id}"
}

output "elb_security" {
  value = "${aws_subnet.app-example.id}"
}

output "security_id" {
  value = "${aws_security_group.allow_all.id}"
}
