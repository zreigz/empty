variable "deletion_protection" {
    type    = bool
    default = true
}

module "mgmt" {
    source        = "./cluster"
    cluster_name  = "lukasz"
    admin_arn = "arn:aws:iam::312272277431:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_AdministratorAccess_63ff4a47c5786193"
    create_db     = true
    deletion_protection = "${var.deletion_protection}"
}

