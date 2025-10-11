

############################################
# aws-ha-webapp — VPC Module
############################################

# ---- VPC ----
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# ---- Internet Gateway ----
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}

# ---- Public Subnets ----
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = element(var.azs, tonumber(each.key))
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-${element(var.azs, tonumber(each.key))}"
    Tier = "public"
  })
}

# ---- NAT Gateways + EIPs ----
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  depends_on    = [aws_internet_gateway.this]

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-${each.key}"
  })
}

# ---- Private App Subnets ----
resource "aws_subnet" "private_app" {
  for_each = { for idx, cidr in var.private_app_subnets : idx => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(var.azs, tonumber(each.key))

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-${element(var.azs, tonumber(each.key))}"
    Tier = "app"
  })
}

# ---- Private DB Subnets ----
resource "aws_subnet" "private_db" {
  for_each = { for idx, cidr in var.private_db_subnets : idx => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(var.azs, tonumber(each.key))

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-${element(var.azs, tonumber(each.key))}"
    Tier = "db"
  })
}

# ---- Route Tables ----
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---- Private App Route Tables (NAT per AZ) ----
resource "aws_route_table" "private_app" {
  for_each = aws_nat_gateway.this
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = each.value.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private_app" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

# ---- Private DB Route Tables (no Internet) ----
resource "aws_route_table" "private_db" {
  for_each = aws_subnet.private_db
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private_db" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db[each.key].id
}