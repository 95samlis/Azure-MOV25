#v35 – IAM och identitet

**SAMUEL LISSBRO**

### Syfte och översikt

Syftet med denna uppgift är att sätta upp identiteter och behörigheter för Novatrix Azure-miljö genom att använda **Microsoft Entra ID** och **Azure RBAC**. 

Målet är att tillämpa principen om least privilege så att användare endast får den åtkomst som krävs för sina arbetsuppgifter. En Managed Identity för applikationen förbereds också inför kommande integration med Azure Storage.

---

## Entra ID - Användare

Användarkonton skapades för driftteamet och utvecklingsteamet i Novatrix Azure-miljö.

### Kommandon

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

## Entra ID – Säkerhetsgrupper

Två säkerhetsgrupper skapades för att hantera behörigheter via grupper istället för enskilda användare. RBAC-roller tilldelas grupperna, vilket gör behörighetshanteringen enklare.

### Kommandon

Skapar säkerhetsgruppen Azure-Drift.

```bash
az ad group create \
  --display-name "Azure-Drift" \
  --mail-nickname "Azure-Drift"
```
Skapar säkerhetsgruppen Azure-Developer.

```bash
az ad group create \
  --display-name "Azure-Developer" \
  --mail-nickname "Azure-Developer"
```

Användarna lades därefter till i respektive grupp.

### Verifiering

```bash
az ad group list --output table
```

Visar samtliga grupper i Entra ID.

---


## RBAC – Behörigheter

För att följa principen om least privilege tilldelades roller till grupper istället för enskilda användare.

### Hämta Resource Group-ID (Scope)

```bash
az group show \
  --name rg-novatrix-v34 \
  --query id \
  -o tsv
```

Hämtar det unika ID:t för resursgruppen som används som scope vid rolltilldelning.

Resultat:

```text
/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34
```

### Hämta Object ID för grupperna

```bash
az ad group show \
  --group Azure-Drift \
  --query id \
  -o tsv
```

Hämtar Object ID för säkerhetsgruppen Azure-Drift.

```bash
az ad group show \
  --group Azure-Developer \
  --query id \
  -o tsv
```

Hämtar Object ID för säkerhetsgruppen Azure-Developer.

---

### Contributor – Azure-Drift

```bash
az role assignment create \
  --assignee-object-id 0c96802f-918c-4e39-828a-154f01d162d0 \
  --assignee-principal-type Group \
  --role Contributor \
  --scope "/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34"
```

#### Motivering

Azure-Drift tilldelades rollen Contributor eftersom driftpersonalen behöver kunna hantera resurser inom resursgruppen. Rollen ger tillräckliga rättigheter för drift och administration utan att ge möjlighet att ändra behörigheter för andra användare.

---

### Reader – Azure-Developer

```bash
az role assignment create \
  --assignee-object-id e73e5139-01e9-4c01-afb3-bb6ea0940446 \
  --assignee-principal-type Group \
  --role Reader \
  --scope "/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34"
```

#### Motivering

Azure-Developer tilldelades rollen Reader eftersom utvecklarna behöver kunna se och kontrollera resurserna vid felsökning och utveckling, men inte göra några ändringar i miljön. På så sätt får de tillgång till den information de behöver och minskar risken för oavsiktliga förändringar i miljön.

---

## Verifiering av RBAC

Rolltilldelningarna verifierades med Azure CLI.

```bash
az role assignment list \
  --scope "/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34" \
  --output table
```
Behörigheterna verifierades även via Azure Portal under **Access Control (IAM) → Check access** samt genom kontroll av användarnas gruppmedlemskap.

## Resultat

<img width="1876" height="334" alt="RBAC01" src="https://github.com/user-attachments/assets/b3177567-d021-467f-99ea-90b0c915adab" />

---
