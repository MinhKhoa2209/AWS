variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "enable_dms" {
  type = bool
}

variable "account_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "private_data_subnet_ids" {
  type = list(string)
}

variable "efs_security_group_id" {
  type = string
}

variable "docdb_security_group_id" {
  type = string
}

variable "documentdb_master_username" {
  type = string
}

variable "documentdb_instance_class" {
  type = string
}

variable "documentdb_instance_count" {
  type = number
}
