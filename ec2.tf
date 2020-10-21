provider "aws" {
  access_key = "ACCESS_KEY"
  secret_key = "SECRET_ACCESS_KEY"
  region     = "ap-south-1"
}

resource "tls_private_key" "VerginiaKey" {
 algorithm = "RSA"
}
resource "aws_key_pair" "generated_key" {
 key_name = "VerginiaKey"
 public_key = "${tls_private_key.VerginiaKey.public_key_openssh}"
 depends_on = [
  tls_private_key.VerginiaKey
 ]
}
resource "local_file" "key" {
 content = "${tls_private_key.VerginiaKey.private_key_pem}"
 filename = "VerginiaKey.pem"
 file_permission ="0400"
 depends_on = [
  tls_private_key.VerginiaKey
 ]
}

resource "aws_vpc" "VPCAuomate" {
 cidr_block = "172.32.0.0/16"
 instance_tenancy = "default"
 enable_dns_hostnames = "true"
 
 tags = {
  Name = "VPCAuomate"
 }
}

resource "aws_security_group" "sg_automate" {
 name = "sg_automate"
 description = "This firewall allows SSH, HTTP and MYSQL"
 vpc_id = "${aws_vpc.VPCAuomate.id}"
 
 ingress {
  description = "SSH"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 tags = {
  Name = "sg_automate"
 }
}

resource "aws_subnet" "public" {
 vpc_id = "${aws_vpc.VPCAuomate.id}"
 cidr_block = "172.32.0.0/24"
 availability_zone = "ap-south-1a"
 map_public_ip_on_launch = "true"
 
 tags = {
  Name = "my_public_subnet"
 } 
}
resource "aws_subnet" "private" {
 vpc_id = "${aws_vpc.VPCAuomate.id}"
 cidr_block = "172.32.1.0/24"
 availability_zone = "ap-south-1b"
 
 tags = {
  Name = "my_private_subnet"
 }
}


resource "aws_internet_gateway" "internet_gateway_name" {
 vpc_id = "${aws_vpc.VPCAuomate.id}"
 
 tags = { 
  Name = "internet_gateway_name"
 }
}

resource "aws_route_table" "name_of_rt" {
 vpc_id = "${aws_vpc.VPCAuomate.id}"
 
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.internet_gateway_name.id}"
 }
 
 tags = {
  Name = "name_of_rt"
 }
}

resource "aws_route_table_association" "a" {
 subnet_id = "${aws_subnet.public.id}"
 route_table_id = "${aws_route_table.name_of_rt.id}"
}
resource "aws_route_table_association" "b" {
 subnet_id = "${aws_subnet.private.id}"
 route_table_id = "${aws_route_table.name_of_rt.id}"
}

resource "aws_instance" "example" {
 ami = "ami-0e306788ff2473ccb"
 instance_type = "t2.micro"
 key_name = "${aws_key_pair.generated_key.key_name}"
 vpc_security_group_ids = [ "${aws_security_group.sg_automate.id}" ]
 subnet_id = "${aws_subnet.public.id}"
 
 tags = {
  Name = "example"
 }
}
