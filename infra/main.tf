
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "template_file" "public_user_data" {
  template = "${file("${path.module}/consul_update.sh.tpl")}"
  vars {
   region                 = "${var.aws_region}"
   server_addresses       = "${join(",",formatlist("#%s#",split(",",var.consul_servers)))}" 
   metadata               = "\"subnet\": \"public\""
  }
}

resource "template_file" "private_user_data" {
  template = "${file("${path.module}/consul_update.sh.tpl")}"
  vars {
   region                 = "${var.aws_region}"
   server_addresses       = "${join(",",formatlist("#%s#",split(",",var.consul_servers)))}" 
   metadata               = "\"subnet\": \"private\""
  }
}

resource "aws_security_group" "private_nomad_worker" {
    name = "nomad_worker_security_group"
    description = "Security group for private nomad workers"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "public_nomad_worker" {
    name = "nomad_worker_security_group"
    description = "Security group for public nomad workers"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "frontend" {
    name = "frontend_security_group"
    description = "Security group for ELB"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "frontend_allow_all" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = "${aws_security_group.frontend.id}"
}

resource "aws_security_group_rule" "frontend_to_nomad_worker" {
    type = "egress"
    from_port = 8080
    to_port = 8081
    protocol = "tcp"

    security_group_id = "${aws_security_group.frontend.id}"
    source_security_group_id = "${aws_security_group.public_nomad_worker.id}"
}

resource "aws_launch_configuration" "public_nomad_worker" {
  instance_type          = "${var.instance_type}"
  image_id               = "${var.ami}"
  key_name               = "${var.key_name}"
  security_groups        = ["${var.consul_cluster_security_group}","${aws_security_group.public_nomad_worker.id}"]
  user_data              = "${template_file.public_user_data.rendered}"
  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_launch_configuration" "private_nomad_worker" {
  instance_type          = "${var.instance_type}"
  image_id               = "${var.ami}"
  key_name               = "${var.key_name}"
  security_groups        = ["${var.consul_cluster_security_group}","${aws_security_group.private_nomad_worker.id}"]
  user_data              = "${template_file.private_user_data.rendered}"
  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_elb" "frontend" {
  name = "nomad-elb"
  subnets =  ["${split(",", var.public_subnet_ids)}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  security_groups = ["${aws_security_group.frontend.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8081/health"
    interval = 30
  }
  tags {
    Name = "frontend-elb"
  }
}

resource "aws_autoscaling_group" "public_nomad_workers" {
  name                 = "public_nomad_worker_asg"
  launch_configuration = "${aws_launch_configuration.public_nomad_worker.name}"
  load_balancers = ["${aws_elb.frontend.name}"]
  min_size         = "${var.public_servers_count}"
  max_size         = "${var.public_servers_count}"
  vpc_zone_identifier  = ["${split(",", var.public_subnet_ids)}"]
  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "private_nomad_workers" {
  name                 = "private_nomad_worker_asg"
  launch_configuration = "${aws_launch_configuration.private_nomad_worker.name}"
  min_size         = "${var.private_servers_count}"
  max_size         = "${var.private_servers_count}"
  vpc_zone_identifier  = ["${split(",", var.private_subnet_ids)}"]
  lifecycle {
      create_before_destroy = true
  }
}
resource "aws_route53_record" "www" {
  zone_id = "${var.route53_zone_id}"
  name = "${var.route53_domain_name}"
  type = "A"

  alias {
    name = "${aws_elb.frontend.dns_name}"
    zone_id = "${aws_elb.frontend.zone_id}"
    evaluate_target_health = true
  }
}
