#v35 – IAM och identitet

**SAMUEL LISSBRO**

### Syfte och översikt

Syftet med denna uppgift är att sätta upp identiteter och behörigheter för Novatrix Azure-miljö genom att använda **Microsoft Entra ID** och **Azure RBAC**. 

Målet är att tillämpa *principen om least privilege* så att användare endast får den åtkomst som krävs för sina arbetsuppgifter. En *Managed Identity* för applikationen förbereds också inför kommande integration med Azure Storage.

---

## Entra ID - Användare

Användarkonton skapades för driftteamet och utvecklingsteamet i Novatrix Azure-miljö.

### kommandon

ommandona kördes via Azure CLI för att skapa användarna direkt i Microsoft Entra ID. Genom att använda CLI blir konfigurationen enkel att återanvändas eller automatisera vid behov.

Skapar användaren David för driftteamet.

```bash
az ad user create \
  --display-name "David (Drift)" \
  --user-principal-name drift-david@samuellissbrooutlook.onmicrosoft.com \
  --password "Temp_password!" \
  --force-change-password-next-sign-in true
```

Skapar användaren Erik för utvecklingsteamet.

```bash
az ad user create \
  --display-name "Erik (Developer)" \
  --user-principal-name dev-erik@samuellissbrooutlook.onmicrosoft.com \
  --password "Temp_password" \
  --force-change-password-next-sign-in true
```

Användarna fick temporära lösenord och tvingas byta lösenord vid första inloggningen.

## Verifiering

```bash
az ad user list --output table
```

Visar samtliga användare i Entra ID.

---


