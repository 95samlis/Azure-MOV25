## v34 – Compute: Driftsättning av Novatrix kundtjänst

**SAMUEL LISSBRO**

### Syfte

---

## Azure-miljö

Jag skapade resursgruppen `rg-novatrix-v34` i regionen `Sweden Central`.

Därefter skapade jag den virtuella servern `vm-novatrix-web` med:

- Ubuntu Server 24.04 LTS Gen2
- Standard_B2ats_v2
- Port 80 öppen för inkommande HTTP-trafik

### Verifiering

Den virtuella servern skapades utan fel och fick en publik IP-adress.

---

## SSH-anslutning

För att ansluta till servern laddade jag ner den privata SSH-nyckeln från Azure och konfigurerade filrättigheterna lokalt i PowerShell.

### Kommandon

```powershell
cd "C:\Azure\Vecka34\Nyckel_Ubuntu"
```

Navigerade till katalogen där SSH-nyckeln sparades.

```powershell
icacls "C:\Azure\Vecka34\Nyckel_Ubuntu\vm-novatrix-web_key.pem" /inheritance:r
```

Tog bort ärvda rättigheter från nyckelfilen.

```powershell
icacls .\vm-novatrix-web_key.pem /grant:r "${env:USERNAME}:R"
```

Gav endast mitt användarkonto läsbehörighet till nyckelfilen.

```powershell
ssh -i "C:\Azure\Vecka34\Nyckel_Ubuntu\vm-novatrix-web_key.pem" azureuser@135.225.105.195
```

Anslöt till den virtuella servern via SSH.

### Verifiering

SSH-anslutningen lyckades och jag fick tillgång till serverns Linux-terminal.

---

## Installation av Nginx

Efter anslutning till servern installerades webbservern Nginx.

### Kommandon

```bash
sudo apt update
```

Uppdaterade paketlistan från Ubuntu-repositorierna.

```bash
sudo apt install nginx -y
```

Installerade webbservern Nginx.

### Verifiering

För att verifiera installationen öppnades serverns publika IP-adress i en webbläsare.

Nginx standardsida visades, vilket bekräftade att webbservern var installerad och tillgänglig över nätverket.
