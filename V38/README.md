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

## Delmoment 3 – Deploya från kod

När ARM-templaten var färdig deployerades miljön med Azure CLI.

```powershell
az deployment group create `
  --resource-group rg-novatrix `
  --template-file V38/azuredeploy.json `
  --parameters "@V38/azuredeploy.parameters.json"
```

Deploymenten skapade samtliga resurser som definierades i templaten, bland annat Virtual Machine, Storage Account, Virtual Network, Managed Identity och Blob Container.

### Verifiering av resurser

Deploymenten skapade samtliga resurser som definierades i templaten, bland annat Virtual Machine, Storage Account, Network Security Group, Public IP, Managed Identity och Network Interface.

<img width="600" height="200" alt="Veri0tttttt" src="https://github.com/user-attachments/assets/ccdb375a-1e8a-4afd-9f4a-fca4abdf4bd6" />

<img width="1100" height="222" alt="534534534" src="https://github.com/user-attachments/assets/9bc0d7e7-d338-4792-9930-a9eb9e69b787" />

---

## Verifiering av webplats

Efter deployment verifierades att webbplatsen var nåbar via den publika IP-adressen och att formuläret kunde öppnas i en webbläsare.

<img width="750" height="450" alt="Skärmbild 2026-09-22 235144" src="https://github.com/user-attachments/assets/09f31b9d-9479-4c34-b41e-bbcf26793f3f" />


<img width="1852" height="584" alt="Skärmbild 2026-09-23 002229" src="https://github.com/user-attachments/assets/f66524a4-5ffa-4228-9e98-f2da80dffe60" />



## Verifiering av Blob Container

<img width="600" height="150" alt="adzfsffsfsf" src="https://github.com/user-attachments/assets/7de7e0b5-2965-4672-bcfe-d30f30d50371" />

## Verifiering av Virtual Network och subnät

<img width="2166" height="148" alt="verifiering subnät" src="https://github.com/user-attachments/assets/62b0bf8d-4989-4dea-9c39-15d1b9b5abc5" />


## Verifiering av rolltilldelning

<img width="2540" height="124" alt="fdgdgdzggfd" src="https://github.com/user-attachments/assets/fe43689c-5b14-409a-9e6c-b91ad5c966ea" />

## Verifiering av NSG och portar

<img width="2200" height="210" alt="verifiering brandvägg" src="https://github.com/user-attachments/assets/4f81d5c9-443f-437e-bf20-94ec6f1afe89" />

---


