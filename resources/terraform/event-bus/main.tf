## Event Bus
resource "kubernetes_manifest" "event_bus" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "EventBus"
    metadata = {
      name      = "default"
      namespace = "default"
    }
    spec = {
      nats = {
        native = {
          replicas = 1
        }
      }
    }
  }
}
