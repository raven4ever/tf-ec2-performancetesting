# EC2 instance
data "aws_vpc" "main_vpc" {
  default = true
}

resource "aws_security_group" "perf_testing_sg" {
  name        = "perf_testing_sg"
  description = "PerformanceTesting"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "VNC from VPC"
    from_port   = 5900
    to_port     = 5900
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VNC from VPC"
    from_port   = 5901
    to_port     = 5901
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VNC from VPC"
    from_port   = 5902
    to_port     = 5902
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VNC from VPC"
    from_port   = 5903
    to_port     = 5903
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "PerformancetestingSG"
    CreatedWith = "Terraform"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "performance_tests" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  key_name      = "access_key"

  security_groups = [aws_security_group.perf_testing_sg.name]

  root_block_device {
    volume_size           = 50
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("/home/me/.ssh/access_key")
  }

  provisioner "file" {
    source      = "config/setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "file" {
    source      = "config/xstartup"
    destination = "/tmp/xstartup"
  }

  provisioner "file" {
    source      = "config/authorized_keys"
    destination = "/tmp/authorized_keys"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
    ]
  }

  tags = {
    Name        = "PortalPerformanceTesting"
    CreatedWith = "Terraform"
  }
}

# Public IP
resource "aws_eip" "public_ip" {
  vpc = true

  tags = {
    Name        = "PortalPerformanceTestingPublicIP"
    CreatedWith = "Terraform"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.performance_tests.id
  allocation_id = aws_eip.public_ip.id
}

output "connection_string" {
  value = "ssh -i .ssh/access_key ubuntu@${aws_eip.public_ip.public_ip}"
}
