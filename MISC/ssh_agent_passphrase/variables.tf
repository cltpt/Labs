#################
## EC2 Details ##
#################
variable "ec2_ami" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
  default     = "ami-09988af04120b3591"
}

variable "ec2_instance_type" {
  type        = string
  description = "The instace type of the ec2 instance"
  default     = "t2.micro"
}

variable "ec2_iam_instance_profile" {
  type        = string
  description = "The IAM instance profile"
  default     = "ec2-ssm"
}

#################
## VPC Details ##
#################

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "priv_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "pub_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_az_priv" {
  type    = string
  default = "us-east-1a"
}

variable "subnet_az_pub" {
  type    = string
  default = "us-east-1b"
}