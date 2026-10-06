# V40 – Virtualiseringsnivåer

**Samuel Lissbro**

## Syfte

Syftet med uppgiften är att köra en del av Novatrix kundtjänst på en annan virtualiseringsnivå än den tidigare VM-baserade lösningen samt att jämföra virtuella maskiner, containers och serverless-tjänster.

## Motivering av vald lösning

Jag valde att köra kundtjänstens webbapplikation som en `Docker`-container i `Azure Container Instance (ACI)`. Eftersom applikationen ska vara tillgänglig för användarna behövs en lösning som kan köras hela tiden och nås via en publik adress.

Applikationen är relativt liten och passar därför bra för en containerbaserad lösning. Genom att använda en container kunde applikationen paketeras som en container-image med samma körmiljö från utveckling till drift. Lösningen blev samtidigt enkel att distribuera i Azure utan att en egen `VM` behövde administreras.

---

### Skapa ACR

För att kunna lagra applikationens `Docker`-image skapade jag ett `Azure Container Registry (ACR)`. Här lagras imagen innan den används för att skapa en container i `ACI` där applikationen senare körs. ACR fungerar som ett privat containerregister som gör det möjligt för ACI att hämta rätt image vid deployment.

### Registrera resursleverantör

```bash
az provider register --namespace Microsoft.ContainerRegistry
```

Registrerar resursleverantören `Microsoft.ContainerRegistry` i prenumerationen.

### Kommando

```bash
az acr create --resource-group rg-novatrix --name novatrixacr388 --sku Basic
```

Skapar ett ACR med namnet `novatrixacr388` i resursgruppen `rg-novatrix`.

Nivån `Basic` valdes eftersom den räcker för lösningens omfattning.

## Aktivera administratörskonto i ACR

För att `ACI` skulle kunna hämta container-imagen från registret aktiverades administratörskontot i `ACR`. Detta gör det möjligt att använda användarnamn och lösenord för autentisering mot registret.

### Aktivera administratörskontot

```bash
az acr update --name novatrixacr388 --admin-enabled true
```

Aktiverar administratörskontot i `ACR`.

### Hämta inloggningsuppgifter

```bash
az acr credential show --name novatrixacr388
```

Visar användarnamn och lösenord för registret. Uppgifterna används senare när containern skapas och behöver åtkomst till den lagrade imagen.

---

## Bygga container-imagen

När `Dockerfile` och appen var färdiga byggdes en container-image och lagrades i `ACR`.

```bash
az acr build --registry novatrixacr388 --image novatrix-app:v1 .
```

Kommandot bygger en container-image utifrån projektets `Dockerfile` och lagrar den i `ACR` med namnet `novatrix-app:v1`.

### Exponera port 80

I `Dockerfile` exponerades port `80`.

```dockerfile
EXPOSE 80
```

Port `80` valdes eftersom det är standardporten för `HTTP`-trafik och gör att applikationen kan nås via webbläsare.

### Anpassa Flask-applikationen

För att applikationen skulle kunna nås via webben konfigurerades `Flask` att använda port `80` och ta emot anslutningar utanför containern.

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

`host='0.0.0.0'` gör att applikationen kan ta emot externa anslutningar, medan `port=80` gör att samma port används i både `Flask` och containern.

---

## Skapa container i ACI

När container-imagen hade byggts och lagrats i `ACR` skapades en container i `Azure Container Instances (ACI)`.

```powershell
az container create `
  --resource-group rg-novatrix `
  --name novatrix-app `
  --image novatrixacr388.azurecr.io/novatrix-app:v1 `
  --os-type Linux `
  --cpu 1 `
  --memory 1 `
  --ports 80 `
  --dns-name-label novatrix-app388 `
  --registry-username novatrixacr388 `
  --registry-password "MITT_ACR_LÖSENORD" `
  --environment-variables ACCOUNT_KEY="MIN_STORAGE_ACCOUNT_KEY"
```

Kommandot skapar en container baserad på imagen `novatrix-app:v1` från `ACR`. Containern tilldelas `1 vCPU`, `1 GB RAM` och exponeras via port `80` med ett publikt DNS-namn.

### Miljövariabel för Storage Account

```text
ACCOUNT_KEY="DIN_STORAGE_ACCOUNT_KEY"
```

`ACCOUNT_KEY` används för att ansluta applikationen till `Azure Blob Storage` utan att lagringsnyckeln behöver sparas i koden.

---

## Verifiering

För att verifiera att containern hade startats korrekt användes följande kommando:

```bash
az container show `
  --resource-group rg-novatrix `
  --name novatrix-app `
  --query "{State:instanceView.state,FQDN:ipAddress.fqdn}"
```

<img width="800" height="130" alt="container-running png" src="https://github.com/user-attachments/assets/46c5bb1f-3ba0-4910-9a98-04986df47278" />

Resultatet visar att containern har status `Running` och att den tilldelats den publika adressen `novatrix-app388.swedencentral.azurecontainer.io`.

---

## Verifiering av applikationen

För att verifiera att den containerbaserade lösningen fungerade öppnades applikationen via den publika adress som tilldelats av `Azure Container Instances (ACI)`.

Ett testärende skickades därefter in tillsammans med en bifogad bild.

<img width="900" height="550" alt="Skärmbild 2026-10-06 032735" src="https://github.com/user-attachments/assets/625fa805-bb11-442a-bc99-9f499877bfdc" />


Efter inskick verifierades att ärendet och den uppladdade filen hade sparats i `Azure Blob Storage`.

<img width="1250" height="410" alt="Skärmbild 2026-10-06 032831" src="https://github.com/user-attachments/assets/2dd5f8f5-a0f8-43d0-b7c7-0ada53024bf3" />


Resultatet visar att applikationen som körs i `ACI` kan ta emot ärenden och lagra information i `Azure Blob Storage`.

# Jämförelse mellan VM, Containers och Serverless
