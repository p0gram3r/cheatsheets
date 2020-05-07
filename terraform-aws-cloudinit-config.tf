data "aws_subnet_ids" "all" {
  vpc_id = var.vpc_id
}

module "amzn2" {
    source = "../modules/ami"
    distribution = "amzn2"
}

data "template_file" "elastic_repo" {
  template = file("resource/elastic.repo")
}
 

data "template_file" "auditbeat_yml" {
  template     = file("resource/auditbeat.yml")
  vars = { logstash_ip = var.logstash_ip_addr }
}

data "template_file" "filebeat_yml" {
  template     = file("resource/filebeat.yml")
  vars = { logstash_ip = var.logstash_ip_addr }
}

data "template_file" "metricbeat_yml" {
  template     = file("resource/metricbeat.yml")
  vars = { logstash_ip = var.logstash_ip_addr }
}

data "template_file" "nginx_2_config" {
  template     = file("resource/nginx-2-default.conf")
}

data "template_cloudinit_config" "init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "sudo yum -y update"
  }
  
  part {
    content_type = "text/x-shellscript"
    content      = "mkdir ~/.aws"
  }

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
write_files:
  - content: |
      ${base64encode(data.template_file.elastic_repo.rendered)}
    encoding: b64
    owner: root:root
    path: /etc/yum.repos.d/elastic.repo
    permissions: '0750'
  - content: |
      ${base64encode(data.template_file.auditbeat_yml.rendered)}
    encoding: b64
    owner: root:root
    path: /tmp/auditbeat.yml
    permissions: '0750'
  - content: |
      ${base64encode(data.template_file.filebeat_yml.rendered)}
    encoding: b64
    owner: root:root
    path: /tmp/filebeat.yml
    permissions: '0750'
  - content: |
      ${base64encode(data.template_file.metricbeat_yml.rendered)}
    encoding: b64
    owner: root:root
    path: /tmp/metricbeat.yml
    permissions: '0750'
  - content: |
      ${base64encode(data.template_file.nginx_2_config.rendered)}
    encoding: b64
    owner: root:root
    path: /tmp/nginx_conf_d_default_conf
    permissions: '0750'
  - content: |
      [default]\nregion=${var.aws_region}
    encoding: b64
    path: ~/.aws/config
    permissions: '0750'
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo yum install -y auditbeat-7.1.1-1.x86_64"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo cp /tmp/auditbeat.yml /etc/auditbeat/auditbeat.yml"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo systemctl enable auditbeat"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo systemctl start auditbeat"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo yum install -y filebeat-7.1.1-1.x86_64"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo cp /tmp/filebeat.yml /etc/filebeat/filebeat.yml"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo filebeat modules enable system"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo systemctl enable filebeat"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo systemctl start filebeat"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo yum install -y metricbeat-7.1.1-1.x86_64"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo cp /tmp/metricbeat.yml /etc/metricbeat/metricbeat.yml"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo systemctl enable metricbeat"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo systemctl start metricbeat"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo amazon-linux-extras install nginx1.12 -y"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo cp /tmp/nginx_conf_d_default_conf /etc/nginx/conf.d/default.conf"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "sudo service nginx start"
  }

}

resource "aws_instance" "nginx-2-instance" {
  ami                    = module.amzn2.ami_id
  instance_type          = var.nginx-2-instance_type
  subnet_id              = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids = [aws_security_group.nginx-2-sg.id]
  key_name               = aws_key_pair.nginx-2-keypair.key_name
  iam_instance_profile   = aws_iam_instance_profile.nginx-2_iam_profile.name
  tags = {
    Name = "Nginx-2"
  }
  user_data = "${data.template_cloudinit_config.init.rendered}"
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.nginx-2-ssh_private_key_file)
    agent       = false
    host        = aws_instance.nginx-2-instance.private_ip
  }
}

resource "aws_key_pair" "nginx-2-keypair" {
  key_name   = "nginx-2-keypair"
  public_key = file(var.nginx-2-ssh_public_key_file)
}

resource "aws_iam_instance_profile" "nginx-2_iam_profile" {
  name = "nginx-2_iam_profile"
  role = aws_iam_role.nginx-2_iam_role.name
}

resource "aws_iam_role" "nginx-2_iam_role" {
  name               = "nginx-2_iam_role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "nginx-2_iam_role_attachment" {
  role       = aws_iam_role.nginx-2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_security_group" "nginx-2-sg" {
  name = "nginx-2-sg"

  description = "Nginx-2 internal security group."
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nginx-2-lb-sg" {
  name = "nginx-2-lb-sg"

  description = "Nginx-2 loadbalancer security group."
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = [
      "212.41.245.2/32",
    ]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      "212.41.245.2/32",
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "nginx-2-ssl" {
  name        = "nginx-2-ssl-lb-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

}

resource "aws_lb_target_group" "nginx-2" {
  name        = "nginx-2-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

}

resource "aws_alb" "nginx-2" {
  name               = "nginx-2"
  internal           = false
  load_balancer_type = "application"
  subnets            = tolist(split(",", replace(replace(replace(var.public_subnets,"\"", ""), "[", ""), "]", "")))
  #subnets            = tolist(data.aws_subnet_ids.all.ids)
  security_groups    = ["${aws_security_group.nginx-2-lb-sg.id}"]

}

resource "aws_lb_target_group_attachment" "nginx-2ssl" {
  target_group_arn = "${aws_lb_target_group.nginx-2-ssl.arn}"
  target_id        = "${aws_instance.nginx-2-instance.id}"
  port             = 443
}

resource "aws_lb_target_group_attachment" "nginx-2" {
  target_group_arn = "${aws_lb_target_group.nginx-2.arn}"
  target_id        = "${aws_instance.nginx-2-instance.id}"
  port             = 80
}

resource "aws_lb_listener" "nginx-2-ssl-listener" {
  load_balancer_arn = "${aws_alb.nginx-2.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.nginx-2-ssl.arn}"
  }
}

resource "aws_lb_listener" "nginx-2-listener" {
  load_balancer_arn = "${aws_alb.nginx-2.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.nginx-2.arn}"
  }
}
