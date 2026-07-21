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

variable "enable_cloudfront_waf" {
  type = bool
}

variable "cloudfront_price_class" {
  type = string
}

variable "api_endpoint" {
  type = string
}
