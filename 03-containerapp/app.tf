# ------------------------------------------
# Azure Container Apps Environment Setup
# ------------------------------------------

# Creates the environment for Azure Container Apps, which is a required component
# for hosting containerized applications in Azure Container Apps.

resource "azurerm_container_app_environment" "flask_env" {
  name                = "flask-env"                                             # Name of the container app environment
  resource_group_name = data.azurerm_resource_group.flask_container_rg.name     # Resource group in which the environment resides
  location            = data.azurerm_resource_group.flask_container_rg.location # Azure region for deployment
}

# ------------------------------------------
# User-Assigned Managed Identity
# ------------------------------------------

# Creates a user-assigned managed identity for the container app.
# This identity is used to authenticate with Azure services (e.g., Azure Container Registry, Cosmos DB).

resource "azurerm_user_assigned_identity" "containerapp" {
  location            = data.azurerm_resource_group.flask_container_rg.location # Same location as the resource group
  name                = "containerappmi"                                        # Name of the managed identity
  resource_group_name = data.azurerm_resource_group.flask_container_rg.name     # Resource group name
}

# -----------------------------------------------------------
# Role Assignment for Container App to Pull Images from ACR
# -----------------------------------------------------------

# Grants the container app's managed identity permission to pull images from Azure Container Registry.

resource "azurerm_role_assignment" "containerapp" {
  scope                = data.azurerm_container_registry.flask_acr.id             # Scope is the Azure Container Registry
  role_definition_name = "acrpull"                                                # Role that allows pulling container images
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id # Assigning the role to the managed identity
}

# ------------------------------------------
# Azure Container App Configuration
# ------------------------------------------

resource "azurerm_container_app" "flask_container_app" {
  name                         = "flask-container-app"                               # Name of the container app
  resource_group_name          = data.azurerm_resource_group.flask_container_rg.name # Resource group
  container_app_environment_id = azurerm_container_app_environment.flask_env.id      # Linking it to the container environment

  revision_mode = "Single" # Only one revision is active at a time, preventing multiple versions from running simultaneously

  # Assigning the user-assigned managed identity to the container app

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp.id] # Using the identity we created earlier
  }

  # Configuring the container registry for pulling images
  
  registry {
    server   = data.azurerm_container_registry.flask_acr.login_server # ACR login server URL
    identity = azurerm_user_assigned_identity.containerapp.id         # Managed identity to authenticate with ACR
  }

  # ------------------------------------------
  # Container Template Configuration
  # ------------------------------------------

  template {
    container {
      name   = "flask-app"                                                                            # Container name
      image  = "${data.azurerm_container_registry.flask_acr.name}.azurecr.io/flask-app:flask-app-rc1" # Image to pull from ACR
      cpu    = "0.25"                                                                                 # CPU allocation (vCPU)
      memory = "0.5Gi"                                                                                # Memory allocation (GiB)

      # Environment variables for the Flask app (connecting to CosmosDB)
      env {
        name  = "COSMOS_ENDPOINT"
        value = azurerm_cosmosdb_account.candidate_account.endpoint # CosmosDB endpoint
      }

      env {
        name  = "COSMOS_DATABASE_NAME"
        value = "CandidateDatabase" # Database name
      }

      env {
        name  = "COSMOS_CONTAINER_NAME"
        value = "Candidates" # Collection name in CosmosDB
      }

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.containerapp.client_id # Managed Identity Client ID
      }

      # ------------------------------------------
      # Health Checks - Ensuring High Availability
      # ------------------------------------------

      # Liveness probe - Checks if the app is still running.
      # If this fails, the container is restarted.
      liveness_probe {
        path             = "/gtg" # Health check endpoint
        port             = 8000   # The port the container listens on
        transport        = "HTTP" # HTTP-based health check
        interval_seconds = 10     # Check every 10 seconds
      }

      # Readiness probe - Ensures the container is ready to receive traffic.
      # If this fails, no traffic is sent to the container.
      readiness_probe {
        path             = "/gtg" # Same health check endpoint
        port             = 8000   # Same port
        transport        = "HTTP" # HTTP-based check
        interval_seconds = 5      # Check every 5 seconds to ensure readiness
      }
    }

    # Auto-scaling configuration
    min_replicas = 1 # At least 1 instance must always be running
    max_replicas = 3 # Scale up to a maximum of 3 instances
  }

  # ------------------------------------------
  # Ingress Configuration - Enabling External Access
  # ------------------------------------------

  ingress {
    external_enabled = true   # Makes the app publicly accessible
    target_port      = 8000   # Traffic is directed to port 8000 inside the container
    transport        = "auto" # Automatically determine transport method

    traffic_weight {
      latest_revision = true # Ensures traffic is always routed to the latest version of the app
      percentage      = 100  # All traffic goes to the latest revision
    }
  }
}

# ------------------------------------------
# Assign CosmosDB Role to Container App
# ------------------------------------------

# Grants the container app's managed identity access to CosmosDB with a custom role

resource "azurerm_cosmosdb_sql_role_assignment" "app_cosmosdb_role" {
  principal_id        = azurerm_user_assigned_identity.containerapp.principal_id   # Assigning the role to the container app's identity
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.custom_cosmos_role.id # Using a custom CosmosDB role definition
  scope               = azurerm_cosmosdb_account.candidate_account.id              # Applying the role at the CosmosDB account level
  account_name        = azurerm_cosmosdb_account.candidate_account.name            # Target CosmosDB account
  resource_group_name = data.azurerm_resource_group.flask_container_rg.name        # Resource group name
}
