# Define a custom Cosmos DB role
resource "azurerm_cosmosdb_sql_role_definition" "custom_cosmos_role" {
  name                = "CustomCosmoDBRole"                                      # Role name
  resource_group_name = data.azurerm_resource_group.flask_container_rg.name      # Resource group name
  account_name        = azurerm_cosmosdb_account.candidate_account.name          # Cosmos DB account name
  type                = "CustomRole"                                             # Role type
  assignable_scopes   = [azurerm_cosmosdb_account.candidate_account.id]          # Assignable scopes

  permissions {
    data_actions = [                                 # Data actions allowed
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}