variable "environment" {
   description = "Name of this environment"
   default = "production"
}

variable "aws_access_key" {
    description = "Access key for AWS"
}

variable "aws_secret_key" {
    description = "Secret key for AWS"
}

variable "aws_region" {
    description = "Region where we will operate."
    default = "eu-west-1"
}

variable "aws_availability_zones" {
    description  = "Availability zones where we will operate."
    default =  "eu-west-1a,eu-west-1b,eu-west-1c,eu-west-1d"
}

variable "consul_servers" {
    description = "Addresses of the consul servers"
}

variable "ami" {
    description = "AMI to use for the nomad workers"
}

variable "consul_cluster_security_group" {
    description = "Security group for consul"
}

variable "key_name" {
    description = "SSH key name"
}

variable "public_subnet_ids" {
    description = "Public subnet IDs"
}

variable "public_subnet_cidrs" {
   description = "Public subnet CIDRs"
}

variable "public_subnet_availability_zones" {
  description = "Public subnet availability zones"
}

variable "private_subnet_ids" {
    description = "Private subnet IDs"
}

variable "private_subnet_cidrs" {
   description = "Private subnet CIDRs"
}

variable "private_subnet_availability_zones" {
  description = "Private subnet availability zones"
}

variable "vpc_cidr" {
    description = "VPC CIDR"
}

variable "vpc_id" {
    description = "VPC ID"
}

variable "instance_type" {
    description = "Instance type for the nomad workers"
    default = "c4.large"
}

variable "public_servers_count" {
    description = "Number of public workers to create"
    default = "1"
}

variable "private_servers_count" {
    description = "Number of private workers to create"
    default = "1"
}

variable "route53_zone_id" {
    description = "Zone id for route53 hosted zone"
}

variable "route53_domain_name" {
    description = "Route53 hosted zone apex"
}
