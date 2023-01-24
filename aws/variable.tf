variable "name" {
  type    = string
  default = "csalab"
}

variable "package" {
  type    = string
  default = "t2.xlarge" # "t2.micro"
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "zone" {
  type    = string
  default = "ap-southeast-1a"
}

variable "domain" {
  type    = string
  default = "csalab.id"
}