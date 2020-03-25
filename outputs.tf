output "lb-ip-address" {
  value = google_compute_global_address.external-address.address
}
