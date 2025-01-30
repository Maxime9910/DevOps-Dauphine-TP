provider "google" {
  project = "primeval-mark-441708-t2"
  region  = "us-central1"
}

# Activation de l'API
resource "google_project_service" "enable_services" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "artifactregistry.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  service = each.value
}

# Créer un dépôt Artifact Registry
resource "google_artifact_registry_repository" "wordpress_repo" {
  location      = "us-central1"
  repository_id = "website-tools"
  format        = "DOCKER"
}


# Création d'une base de données WordPress
resource "google_sql_database" "wordpress_db" {
  name     = "wordpress"
  instance = "main-instance"  # Cette instance a été créée dans la section TP Prep
}

# Créer un utilisateur WordPress 
resource "google_sql_user" "wordpress_user" {
  name     = "wordpress"
  instance = "main-instance"
  password = "ilovedevops"
}
