terraform {
  backend "azurerm" {
        resource_group_name  = "vmc-tfstate-rg"
        storage_account_name = "vmctfstatestg"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}

provider "azurerm" {
  features {}
}

# Creates a Resource Group to group the following resources
resource "azurerm_resource_group" "rg" {
  name     = "${var.appName}-${var.appServiceName}-${var.env}-rg"
  location = var.location
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "asp-${var.appName}-${var.appServiceName}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B2"
}

#Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                = "${var.appName}-${var.appServiceName}-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appserviceplan.id

  site_config {
    always_on = true
    application_stack {
      dotnet_version = "6.0"
    }
  }
}

# Create Azure Database for PostgreSQL server. Database will be automatically created by Todo API code
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${var.dbName}-${var.env}-psql"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "13"
  administrator_login    = "${var.dbAdmin}"
  administrator_password = "${var.dbPassword}"
  zone                   = "1"

  storage_mb = 32768

  sku_name   = "B_Standard_B1ms"
}

# Add firewall rule on your Azure Database for PostgreSQL server to allow other Azure services to reach it
resource "azurerm_postgresql_flexible_server_firewall_rule" "example" {
  name             = "AllowAllAzureServicesAndResourcesWithinAzureIps"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}