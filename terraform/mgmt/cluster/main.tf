# BYOK stub cluster module.
# The cluster already exists externally; this module only supplies the output
# attributes that console.tf depends on so that file can be used unchanged
# across all providers.

variable "db_url" {
  type      = string
  default   = ""
  sensitive = true
}

# Passed from the parent to sequence cert creation after certmanager is ready.
variable "certmanager_ready" {
  type    = string
  default = ""
}

resource "null_resource" "cluster" {}

output "cluster" {
  value = null_resource.cluster.id
}

output "ready" {
  value = null_resource.cluster.id
}

output "db_url" {
  value     = var.db_url
  sensitive = true
}

output "identity" {
  value = ""
}

# Create a self-signed CA and expose it as the 'plural' ClusterIssuer so the
# console helm chart's ingress annotations work out of the box.
resource "null_resource" "local_ca" {
  triggers = {
    certmanager_ready = var.certmanager_ready
  }
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f - <<'YAML'
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: selfsigned-issuer
      spec:
        selfSigned: {}
      YAML

      kubectl apply -f - <<'YAML'
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: local-ca
        namespace: cert-manager
      spec:
        isCA: true
        commonName: local-ca
        secretName: local-ca-secret
        privateKey:
          algorithm: RSA
          size: 2048
        issuerRef:
          name: selfsigned-issuer
          kind: ClusterIssuer
          group: cert-manager.io
      YAML

      kubectl wait --for=condition=Ready certificate/local-ca -n cert-manager --timeout=120s

      kubectl apply -f - <<'YAML'
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: plural
      spec:
        ca:
          secretName: local-ca-secret
      YAML
    EOT
  }
}

# Expose the local_ca resource ID so the root module can sequence
# inject_agent_ca after the CA has been created.
output "local_ca_id" {
  value = null_resource.local_ca.id
}


