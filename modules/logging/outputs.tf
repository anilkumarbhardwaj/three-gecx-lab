output "sink_writer_identity" {
  value = var.sink_destination != "" ? google_logging_project_sink.central[0].writer_identity : null
}
