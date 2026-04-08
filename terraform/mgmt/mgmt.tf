// BYOK – the cluster already exists externally, so the mgmt module is just a
// stub that provides the outputs expected by console.tf without provisioning anything.
// certmanager_ready sequences the self-signed CA creation inside the module.
module "mgmt" {
  source            = "./cluster"
  db_url            = "postgres://postgres:mysecretpassword@my-postgres-postgresql.default.svc.cluster.local:5432/postgres"
  certmanager_ready = helm_release.certmanager.id
}
