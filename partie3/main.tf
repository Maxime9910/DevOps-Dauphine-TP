resource "google_cloud_run_service" "wordpress" {
  name     = "wordpress-cloudrun"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/primeval-mark-441708-t2/website-tools/wordpress-custom:latest"
        ports {
          container_port = 80
        }
        env {
          name  = "WORDPRESS_DB_HOST"
          value = "34.125.50.200"  # Cloud SQL 的公网 IP
        }
        env {
          name  = "WORDPRESS_DB_USER"
          value = "wordpress"
        }
        env {
          name  = "WORDPRESS_DB_PASSWORD"
          value = "ilovedevops"
        }
      }
      timeout_seconds = 300
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# 开放 Cloud Run 访问权限
data "google_iam_policy" "noauth" {
   binding {
      role = "roles/run.invoker"
      members = [
         "allUsers",
      ]
   }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = google_cloud_run_service.wordpress.location
   project     = google_cloud_run_service.wordpress.project
   service     = google_cloud_run_service.wordpress.name

   policy_data = data.google_iam_policy.noauth.policy_data
}

data "google_client_config" "default" {}

data "google_container_cluster" "gke_cluster" {
  name     = "gke-dauphine"
  location = "us-central1-a"
}

provider "kubernetes" {
  host                   = data.google_container_cluster.gke_cluster.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)
}

resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "wordpress"
      }
    }
    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }
      spec {
        container {
          image = "us-central1-docker.pkg.dev/${var.project_id}/website-tools/wordpress-custom:latest"
          name  = "wordpress"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = "34.125.50.200"
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = "wordpress"
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = "ilovedevops"
          }
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress-service"
  }
  spec {
    selector = {
      app = "wordpress"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

