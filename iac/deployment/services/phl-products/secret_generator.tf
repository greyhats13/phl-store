resource "random_password" "password" {
  length           = 12
  override_special = "!#$%&*@"
  min_lower        = 3
  min_upper        = 3
  min_numeric      = 3
  min_special      = 0
}