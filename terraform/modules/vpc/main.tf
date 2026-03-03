resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                     = "${var.vpc_name}-public-${var.availability_zones[count.index]}"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name                              = "${var.vpc_name}-private-${var.availability_zones[count.index]}"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? var.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway ? var.nat_gateway_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  count = var.create_internet_gateway && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-rt"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_internet_gateway && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = var.create_nat_gateway ? var.nat_gateway_count : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-private-rt-${count.index + 1}"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_nat_gateway ? var.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % var.nat_gateway_count].id
}

# -------------------------------------------------------
# VPC Peering
# -------------------------------------------------------

locals {
  # Resolve the peering connection ID for use in route tables
  effective_peering_connection_id = var.create_peering_connection ? try(aws_vpc_peering_connection.requester[0].id, null) : var.peering_connection_id
}

# Requester: create the peering connection
resource "aws_vpc_peering_connection" "requester" {
  count = var.create_peering_connection ? 1 : 0

  vpc_id        = aws_vpc.this.id
  peer_vpc_id   = var.peer_vpc_id
  peer_region   = var.peer_region
  auto_accept   = false # Cross-region peering cannot be auto-accepted

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-peering-requester"
    Side = "requester"
  })
}

# Accepter: accept the incoming peering connection
resource "aws_vpc_peering_connection_accepter" "accepter" {
  count = var.accept_peering_connection ? 1 : 0

  vpc_peering_connection_id = var.peering_connection_id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-peering-accepter"
    Side = "accepter"
  })
}

# Route to peer VPC in public route table
resource "aws_route" "public_peering" {
  count = var.peer_vpc_cidr != null && local.effective_peering_connection_id != null && var.create_internet_gateway && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  route_table_id            = aws_route_table.public[0].id
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = local.effective_peering_connection_id
}

# Route to peer VPC in private route tables
resource "aws_route" "private_peering" {
  count = var.peer_vpc_cidr != null && local.effective_peering_connection_id != null && var.create_nat_gateway ? var.nat_gateway_count : 0

  route_table_id            = aws_route_table.private[count.index].id
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = local.effective_peering_connection_id
}
