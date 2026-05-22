variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "account_id" {
  type = string
}

variable "create_cloudfront_distribution" {
  type = bool
}

variable "api_endpoint" {
  type = string
}
