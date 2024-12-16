resource "mysql_database" "db" {
  name = var.db_name
}

## Create a Database User
resource "mysql_user" "db" {
  user               = var.db_user
  host               = "%"
  plaintext_password = random_password.password.result
}

## Grant the user access to the database
resource "mysql_grant" "db" {
  user       = mysql_user.db.user
  host       = mysql_user.db.host
  database   = mysql_database.db.name
  privileges = var.db_privileges
}