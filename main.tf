variable "ssh_key" {
  description = "intentionally left blank"
}

provider "aws" {
  region = "us-east-1"
}

resource "null_resource" "create_ssh_key_file" {
  provisioner "local-exec" {
    command = "echo ${var.ssh_key} > ssh_key_file"
  }
}

resource "aws_security_group" "test_sg" {
  name = "test_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outgoing traffic to anywhere.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test" {
  ami           = "ami-0885b1f6bd170450c"
  instance_type = "t2.micro"
  #user_data = base64encode("${path.module}/playbook/wget.yml") #put playbook on new instance
  key_name        = "farnejb"
  security_groups = ["${aws_security_group.test_sg.name}"]
}

resource "null_resource" "test1" {
    provisioner "local-exec" {
        command = "echo ${aws_instance.test.public_ip} >> ${path.module}/ips.txt"

    }
    depends_on = [ aws_instance.test ]
}

resource "time_sleep" "wait_120_sec" {
    depends_on = [null_resource.test1]
    create_duration = "120s"
}

resource "null_resource" "test2" {
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i ./ips.txt --private-key=${path.module}/ssh_key_file ${path.module}/playbook/wget.yml"
        #command = "echo ${aws_instance.test.public_ip} >> ${path.module}/ips.txt"

    }
    depends_on = [time_sleep.wait_120_sec]
}