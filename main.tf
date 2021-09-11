provider "aws" {
  region = "us-east-1"
  version = "v2.70.0"
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-40d28157"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, world" > index.html
              nohup busybox httpd -f -p "${var.server-port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance-1"

    ingress = {
      cidr_blocks = [ "0.0.0.0/0" ]      
      from_port = "${var.server-port}"    
      protocol = "tcp"      
      to_port = "${var.server-port}"
    }
    
    lifecycle {
      create_before_destroy = true
    }
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"  
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  
  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"
   
  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name = "terraform-asg-example"  
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server-port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 30
    timeout = 3
    target = "HTTP:${var.server-port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server-port" {
  description = "The port server will use for HTTP request"
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}