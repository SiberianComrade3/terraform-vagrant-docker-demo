resource "tls_private_key" "infra_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# =============================================================

# Self-signed certificate for Grafana public-facing interface
resource "tls_self_signed_cert" "grafana_self_signed_cert" {
  private_key_pem = tls_private_key.infra_private_key.private_key_pem

  subject {
    common_name         = var.tls_subject["common_name"]
    organization        = var.tls_subject["organization"]
    organizational_unit = var.tls_subject["organizational_unit"]
    country             = var.tls_subject["country"]
    postal_code         = var.tls_subject["postal_code"]
  }

  ip_addresses = [openstack_networking_floatingip_v2.ext_float_ip_host.address]

  # 5 days
  validity_period_hours = 120
  is_ca_certificate     = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "cert_signing"
  ]
}

resource "openstack_keymanager_secret_v1" "grafana_private_key_secret" {
  name                 = "tf_grafana_private_key_secret"
  payload              = tls_private_key.infra_private_key.private_key_pem
  payload_content_type = "text/plain"
  secret_type          = "private"
}

resource "openstack_keymanager_secret_v1" "grafana_cert_secret" {
  name                 = "tf_grafana_cert_secret"
  payload              = tls_self_signed_cert.grafana_self_signed_cert.cert_pem
  payload_content_type = "text/plain"
  secret_type          = "certificate"
}

resource "openstack_keymanager_container_v1" "tls_grafana_container_secret" {
  name = "tf_tls_container"
  type = "certificate"

  secret_refs {
    name       = "private_key" # predefined name, do not change
    secret_ref = openstack_keymanager_secret_v1.grafana_private_key_secret.secret_ref
  }

  secret_refs {
    name       = "certificate" # predefined name, do not change
    secret_ref = openstack_keymanager_secret_v1.grafana_cert_secret.secret_ref
  }
}

# ==================================================
# SSH Keys
resource "openstack_compute_keypair_v2" "infra_keypair" {
  name = "tf_infra_keypair"
}

resource "local_sensitive_file" "infra_private_key" {
  content         = openstack_compute_keypair_v2.infra_keypair.private_key
  filename        = "${path.module}/${var.ssh_private_key}"
  file_permission = "0600"
}