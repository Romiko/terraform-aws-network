resource "aws_subnet" "transit" {
  count                   = "${var.transit_subnet ? (length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)) : 0}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, var.newbits, count.index + var.transit_netnum_offset)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-Subnet-Transit-${upper(data.aws_availability_zone.az.*.name_suffix[count.index])}",
      "Scheme", "transit",
      "EnvName", "${var.name}"
    )
  )}"
}

resource "aws_route_table" "transit" {
  count  = "${var.transit_subnet ? 1 : 0}"
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-RouteTable-Transit",
      "Scheme", "transit",
      "EnvName", "${var.name}"
    )
  )}"
}

resource "aws_route" "transit_internet_route" {
  count                  = "${var.transit_subnet ? 1 : 0}"
  route_table_id         = "${aws_route_table.transit.*.id[0]}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "transit" {
  count          = "${var.transit_subnet ? (length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)) : 0}"
  subnet_id      = "${aws_subnet.transit.*.id[count.index]}"
  route_table_id = "${aws_route_table.transit.*.id[0]}"

  lifecycle {
    # ignore_changes        = ["subnet_id", "route_table_id"]
    create_before_destroy = true
  }
}
