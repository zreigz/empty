// BYOK – the cluster already exists externally, so the mgmt module is just a
// stub that provides the outputs expected by console.tf without provisioning anything.
module "mgmt" {
  source = "./cluster"
  db_url = "{{ .Context.DbUrl }}"
}

# ── Self-signed CA for local TLS ─────────────────────────────────────────────
# cert-manager cannot do ACME validation on a local/Kind cluster, so we create
# a self-signed CA and use it as the cluster issuer for the console certificate.
# null_resource + kubectl is used instead of kubernetes_manifest because
# kubernetes_manifest reads CRD schemas at plan time (before cert-manager installs them).

resource "null_resource" "local_ca" {
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
        name: local-ca-issuer
      spec:
        ca:
          secretName: local-ca-secret
      YAML
    EOT
  }

  depends_on = [helm_release.certmanager]
}
