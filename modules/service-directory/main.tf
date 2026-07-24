# Module: service-directory — GECX private webhook path (workbook sheet 23)
# Namespace/service/endpoint pointing at the ILB frontend, plus PNA IAM
# for the Dialogflow/CES service agent. Firewall rule 300 (sheet 08) is
# the hard dependency — without it PNA calls silently fail.

resource "google_service_directory_namespace" "this" {
  provider     = google-beta
  project      = var.project_id
  namespace_id = var.namespace_id
  location     = var.region
}

resource "google_service_directory_service" "webhook" {
  provider   = google-beta
  namespace  = google_service_directory_namespace.this.id
  service_id = var.service_id
}

resource "google_service_directory_endpoint" "ilb" {
  provider    = google-beta
  service     = google_service_directory_service.webhook.id
  endpoint_id = "ilb-frontend"
  address     = var.ilb_ip
  port        = 443
  network     = "projects/${var.project_number}/locations/global/networks/${var.network_name}"
}

# Dialogflow/CES service agent: SD resolution + PNA into the VPC
resource "google_project_iam_member" "dialogflow_sd" {
  for_each = toset([
    "roles/servicedirectory.viewer",
    "roles/servicedirectory.pscAuthorizedService",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-dialogflow.iam.gserviceaccount.com"
}
