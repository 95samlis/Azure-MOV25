# V40 – Virtualiseringsnivåer

**Samuel Lissbro**

## Syfte

Syftet med uppgiften är att köra en del av Novatrix kundtjänst på en annan virtualiseringsnivå än den tidigare VM-baserade lösningen samt att jämföra virtuella maskiner, containers och serverless-tjänster.

## Motivering av vald lösning

Jag valde att köra kundtjänstens webbapplikation som en `Docker`-container i `Azure Container Instance (ACI)`. Eftersom applikationen ska vara tillgänglig för användarna behövs en lösning som kan köras hela tiden och nås via en publik adress.

Applikationen är relativt liten och passar därför bra för en containerbaserad lösning. Genom att använda en container kunde applikationen paketeras som en container-image med samma körmiljö från utveckling till drift. Lösningen blev samtidigt enkel att distribuera i Azure utan att en egen `VM` behövde administreras.

Serverless hade också varit ett möjligt alternativ för applikationen. Jag valde dock en containerlösning eftersom hela applikationen kunde paketeras i en `Docker`-image som sparas i `Azure Container Registry (ACR)` och kan återanvändas vid framtida distributioner.

---

### Skapa ACR

För att kunna lagra applikationens `Docker`-image skapade jag ett `Azure Container Registry (ACR)`. Här lagras imagen innan den används för att skapa en container i `ACI` där applikationen senare körs. ACR fungerar som ett privat containerregister som gör det möjligt för `ACI` att hämta rätt image vid deployment.

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

### Virtuell maskin 

En virtuell maskin är en komplett server med eget operativsystem. Applikationen körs på servern och användaren ansvarar själv för uppdateringar, säkerhet, konfiguration och underhåll.

En VM ger hög kontroll eftersom användaren har tillgång till hela servern och OS:et. Det går att installera egna program, ändra inställningar, konfigurera nätverk och anpassa miljön efter appens behov. Därför används VM ofta när en applikation har särskilda krav eller när äldre system behöver flyttas till molnet utan större förändringar.

### Fördelar

- Hög kontroll över servern och operativsystemet
- Passar äldre applikationer
- Kan anpassas efter egna behov
- Stöd för många olika program och operativsystem

### Nackdelar

- Kräver mer administration
- Ansvar för uppdateringar och säkerhet
- Skalning är långsammare
- Kostar även när maskinen inte används

### Exempel

Ett företag har en äldre Windows-applikation som kräver särskilda inställningar i operativsystemet. Då kan en Azure VM vara ett bra val eftersom företaget får full kontroll över servern och kan installera och konfigurera programvaran efter egna behov.

---

### Containers

En container innehåller appen och det som behövs för att den ska fungera. Den har inget eget operativsystem utan delar operativsystem med värden. Därför startar den snabbt och använder mindre resurser än en VM.

### Fördelar

- Startar snabbt
- Tar mindre resurser än en VM
- Samma container fungerar i olika miljöer
- Enkel att flytta mellan olika system
  
### Nackdelar

- Mindre kontroll än en VM
- Kräver kunskap om Docker och containers
- Kan vara svårare att felsöka
  
### Exempel

Ett företag har en webbapplikation som ska köras i både test- och produktionsmiljö. Genom att använda en container kan samma version av appen köras överallt. I Azure kan containern till exempel köras i `ACI`.

Om ett företag ska lansera en ny kundportal kan det vara praktiskt att använda containrar istället för att sätta upp och underhålla egna servrar. Det gör att appen kan köras på samma sätt oavsett miljö och förenklar både drift och uppdateringar.

---

### Serverless

Med serverless skriver man bara koden och låter molnet sköta resten. Det finns ingen server som behöver installeras eller underhållas. Koden är händelsestyrt, till exempel när ett formulär skickas in eller en fil laddas upp.

### Fördelar

- Ingen server att hantera
- Kan hantera fler användare automatiskt när belastningen ökar
- Betalar bara när funktionen används
- Kräver lite administration
  
### Nackdelar

- Minst kontroll över miljön
- Kan bli långsammare vid första anropet (cold start)
- Passar inte alla typer av applikationer
  
### Exempel

Ett företag har ett kontaktformulär på sin webbplats. När en användare skickar in formuläret startas en Azure Function som sparar informationen i en databas eller ett lagringskonto. När jobbet är klart avslutas funktionen automatiskt.
