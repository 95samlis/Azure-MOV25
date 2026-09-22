# V38 - Infrastructure as Code med ARM Templates


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

---

### Storage Account

Ett Storage Account används för att lagra de ärenden som skickas in via webbformuläret.

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "apiVersion": "2023-01-01",
  "name": "[parameters('storageName')]"
}
```

### Blob Container

I Storage Account skapas en container med namnet `arenden` där Flask-applikationen sparar inkomna ärenden.

```json
{
  "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
  "name": "[concat(parameters('storageName'), '/default/arenden')]"
}
```

### User Assigned Managed Identity

En User Assigned Managed Identity används för att ge applikationen åtkomst till Blob Storage utan att lagra några lösenord eller nycklar.

```json
{
  "type": "Microsoft.ManagedIdentity/userAssignedIdentities",
  "name": "id-novatrix-app"
}
```

### Virtual Network och Subnät

Ett virtuellt nätverk skapades för att organisera infrastrukturen. Två subnät definierades:

- `snet-web` för webbservern
- `snet-db` reserverat för databastjänster

```json
{
  "type": "Microsoft.Network/virtualNetworks",
  "name": "[parameters('vnetName')]"
}
```

### Network Security Group

En Network Security Group (NSG) skapades för att styra vilken trafik som får nå den virtuella maskinen. Regler skapades för att tillåta HTTP (80), HTTPS (443) och SSH (22).

### Public IP och NIC

VM:n behöver en publik IP-adress för att kunna nås via webbläsare och SSH. Ett nätverkskort kopplar VM:n till nätverket.

### Virtual Machine

En Ubuntu Linux VM provisioneras för att köra webbservern och Flask-applikationen.

```json
{
  "type": "Microsoft.Compute/virtualMachines",
  "name": "[parameters('vmName')]"
}
```

### VM Extension

En Custom Script Extension används för att automatisera den initiala konfigurationen av servern. Extensionen installerar Nginx och Git, klonar GitHub-repot `Azure-MOV25`, kopierar webbplatsfilen `indexv2.html` från V37 och startar webbservern efter deployment.

### Role Assignment

Managed Identity tilldelas rollen **Storage Blob Data Contributor** på Blob-containern. Detta gör att Flask-applikationen kan läsa och skriva ärenden i Blob Storage utan att använda lagringsnycklar eller lösenord.

```json
{
  "type": "Microsoft.Authorization/roleAssignments"
}
```

### Output

Output-värdet `storageId` returnerar resurs-ID:t för Storage Account så att det enkelt kan användas av andra templates eller automatiserade deploymentsteg.

```json
{
  "outputs": {
    "storageId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageName'))]"
    }
  }
}
```

---

## Parametrar

För att göra templaten återanvändbar parametriserades variabla värden istället för att hårdkodas i koden. Exempel på parametrar är namn på Storage Account, Virtual Machine, Virtual Network, användarnamn och SSH-nyckel.

Parametervärdena lagras i filen `azuredeploy.parameters.json`, vilket gör att samma template kan användas i olika miljöer genom att endast parameterfilen ändras.

```json
{
  "storageName": {
    "value": "stnovatrixv388"
  },
  "vmName": {
    "value": "vm-novatrix-web-v38"
  }
}
```

---
