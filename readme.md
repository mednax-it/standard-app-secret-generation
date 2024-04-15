# Standard App Secret Generation

This terraform exists to give a consistent way for Pediatrix to generate secrets for app registrations in Azure.

This is purposefully separated from the [sdbi-app-registrations](https://github.com/mednax-it/sdbi-app-registrations).  The secrets associated to applications and the app registration themselves have different life cycles.

## Usage

The terraform takes 4 arguments:

* `TF_VAR_app_registration_id` - This is the `Client Id` not the `Object Id` of the azure application registration.
* `TF_VAR_resource_group_name` - The resource group that the key vault resides in.
* `TF_VAR_key_vault_name` - The name of the key vault.
* `TF_VAR_key_name` - They key name the secret is or is intended to be stored under.

### Logic

The terraform will use the variables to check and see if the key already exists in the key vault.  If it does it does nothing.  If it does not it will create a new client secret that expires in 100 years and puts it in teh key vault with no human interaction.  No human is allowed to see the secret.
