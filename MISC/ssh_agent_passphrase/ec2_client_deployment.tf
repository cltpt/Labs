resource "aws_instance" "ec2_client" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.private_sub.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids = ["${aws_security_group.ec2_sg.id}"]

  tags = {
    Name    = "ec2_client",
    Testing = "yes"
  }

  user_data = <<EOF
#!/bin/bash
mkdir /mykeys
touch /mykeys/mykey_rsa
echo 'inseryourkeyhere' > /mykeys/mykey_rsa
chmod 700 my_keyrsa
EOF
}