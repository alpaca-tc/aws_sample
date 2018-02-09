resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.application_name}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

##
# public subnet
# インターネットゲートウェイと同じサブネット
# ALBやNAT Gatewayがここに含まれる
##
resource "aws_subnet" "public" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, 0 + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.application_name}-public-${count.index}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }

  tags {
    Name    = "${var.application_name}-public-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

# 踏み台サーバーを配置する
resource "aws_eip" "bastion" {
  vpc = true

  tags {
    Name    = "${var.application_name}-bastion-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = "${aws_instance.bastion.id}"
  allocation_id = "${aws_eip.bastion.id}"
}

# NATを配置する
# https://docs.aws.amazon.com/ja_jp/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html
resource "aws_eip" "nat-gateway" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc   = true

  tags {
    Name    = "${var.application_name}-nat-gateway-${count.index}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  allocation_id = "${element(aws_eip.nat-gateway.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.gateway"]

  tags {
    Name    = "${var.application_name}-nat-gateway-${count.index}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

##
# private-nat
# NATと接続したいプライベートなリソースのサブネット
# 外部からは接続できないが、外部には接続可能
# ECSやEC2などを配置する
##
resource "aws_subnet" "private-nat" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, 20 + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.application_name}-private-nat-${count.index}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_route_table" "private-nat" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.nat-gateway.*.id, count.index)}"
  }

  tags {
    Name    = "${var.application_name}-private-nat-${terraform.env}-${count.index}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

# ECSとNATをつなぐ
# https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/launch_container_instance.html
resource "aws_route_table_association" "private-nat" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.private-nat.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private-nat.*.id, count.index)}"
}

##
# private
# NATと接続しないプライベートなリソースのサブネット
# RDSやElastiCacheなどを配置する
##
resource "aws_subnet" "private" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, 30 + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.application_name}-private-${count.index}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_route_table" "private" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.application_name}-private-${terraform.env}-${count.index}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
