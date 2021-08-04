**1.1.0.0**

- Added optional parameter ForceReplaceAgent that uses the credentials supplied to delete an existing ARC agent with the same subscription, resource group and name in Azure before registering the agent
- Reports any errors to the DSC logs
- Calls azcmagent with correct parameters to disconnect successfully when needed

**1.0.1.0**

- Fixed links in manifest 

**1.0.0.0**

- Functional project to configure the AZ CM agent
- Example to install the agent, manage the service, and confiure the agent
- Unit tests
- Integration tests
- Project requirements
