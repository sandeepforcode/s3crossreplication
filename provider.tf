#---------------------
# Virgina
#---------------------
provider "aws" {
    alias = "source"
    region = "us-east-1"
}

#---------------------
# Oregon
#---------------------
provider "aws" {
    alias = "destination"
    region = "us-west-2"
}