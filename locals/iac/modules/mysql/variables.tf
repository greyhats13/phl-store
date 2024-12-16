variable "db_name" {
  description = "The name of the database to create"
  type        = string
  
}

variable "db_user" {
  description = "The name of the database user to create"
  type        = string
}

variable "db_privileges" {
  description = "The privileges to grant to the database user"
  type        = list(string)
}