variable "name" {
  type    = string
  default = "csafserver"
}

variable "project_id" {
  type    = string
  # Project id page: https://console.scaleway.com/project/settings
  default = "45f83910-f65a-4ba2-ba15-c37998528695"
}

variable "zone" {
  type    = string
  default = "fr-par-1"
}

variable "region" {
  type    = string
  default = "fr-par"
}

variable "package" {
  type    = string
  default = "DEV1-L"
}

variable "domain" {
  type    = string
  default = "csalab.cloud"
}