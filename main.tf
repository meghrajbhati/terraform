provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami = "ami-40d28157"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, world" > index.html
              nohup busybox httpd -f -p "${var.server-port}" &
              EOF

  tags = {
      "Name" = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance-1"

    ingress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "HTTP"
      from_port = "${var.server-port}"
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      protocol = "tcp"
      security_groups = null
      self = null
      to_port = "${var.server-port}"
    } ]
    
}

variable "server-port" {
  description = "The port server will use for HTTP request"
}

output "public-ip" {
  value = "${aws_instance.example.public_ip}"
}