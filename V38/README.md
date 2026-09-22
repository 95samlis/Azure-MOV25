# V37 - Infrastructure as Code med ARM Templates


**Samuel Lissbro** 


## Syfte

Syftet med uppgiften var att använda Infrastructure as Code (IaC) med ARM Templates för att automatisera uppsättningen av Novatrix kundtjänstmiljö i Azure.

Genom att beskriva infrastrukturen som kod kan miljön återskapas på samma sätt varje gång, utan att man behöver klicka sig fram manuellt i Azure Portal. Koden versionshanteras i GitHub, vilket gör det enkelt att se vad som ändrats över tid.

## ARM Template

Jag skapade en ARM-template som provisionerar centrala delar av Novatrix miljö.

Följande resurser skapas:

- Storage Account
- Blob Container (arenden)
- User Assigned Managed Identity
- Virtual Network (VNet)
- Subnet för webbserver (snet-web)
- Subnet för databas (snet-db)
- Network Security Group (NSG)
- Public IP Address
- Network Interface (NIC)
- Linux Virtual Machine
- VM Extension för installation av Nginx
- Role Assignment (Storage Blob Data Contributor)

