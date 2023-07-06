variable "name" {
  type    = string
  default = "csafserver"
}

variable "package" {
  type    = string
  default = "S3.2XLARGE16"
}

variable "availability_zone" {
  type    = string
  default = "ap-singapore-1"
}

variable "region" {
  type    = string
  default = "ap-singapore"
}

variable "domain" {
  type    =  string
  default = "csalab.cloud"
}