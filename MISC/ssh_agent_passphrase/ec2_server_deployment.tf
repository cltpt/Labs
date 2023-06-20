resource "aws_instance" "ec2_server" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.private_sub.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids = ["${aws_security_group.ec2_sg.id}"]
  key_name               = "MyTestKeyPairRSA"

  tags = {
    Name    = "ec2_server",
    Testing = "yes"
  }

  user_data = <<EOF
    #!/bin/bash
    EOF
}