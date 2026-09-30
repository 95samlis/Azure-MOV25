# V39 - Automation och integration


**Samuel Lissbro** 

## Syfte 

Syftet var att koppla samman Azure och Microsoft 365 med hjälp av Power Automate. När ett ärende skickas in via formuläret ska ett automatiskt flöde triggas som hämtar ärendedata och skickar en notifiering via e-post till ansvarig person i Microsoft 365-miljön. Detta skapar en automatiserad kedja från inskickat ärende till hantering av kundtjänst.

---

## Ändringar i backend.py

Backenden hade sedan tidigare stöd för att spara ärenden som JSON-filer i Azure Blob Storage. För att även kunna hantera bilagor utökades lösningen med stöd för filuppladdning.

### Mottagning av bilaga

Backenden uppdaterades för att läsa den uppladdade filen från formuläret:

```python
image = request.files.get("bild")
```

### Uppladdning till Azure Blob Storage

Om en fil finns bifogad skapas ett unikt filnamn baserat på ärendets ID och originalfilens namn.

```python
image_name = f"{entry_id}_{image.filename}"
```

Filen laddas därefter upp som en separat blob i containern `arenden`.

```python
image_blob.upload_blob(
    image.read(),
    overwrite=True
)
```

### Utökad JSON-struktur

JSON-filen kompletterades med information om den uppladdade bilden:

```json
{
  "image": image_url,
  "image_name": image_name
}
```

### Motivering

Power Automate behövde kunna hitta både ärendedata och tillhörande bilaga i Azure Blob Storage. Genom att spara både bildens URL och blobnamn kunde flödet senare hämta rätt fil och bifoga den i e-postmeddelandet som skickas till kundtjänst. Lösningen innebar att ärendedata och bilagor lagras separat men fortfarande kan kopplas samman via informationen som sparas i JSON-filen.

---

## Steg 1 – Trigger från Azure Blob Storage

Flödet startar med triggern **"När en blob läggs till eller ändras (enbart egenskaper) (V2)"**.

Triggern övervakar containern `arenden` i Azure Blob Storage. När backend-applikationen sparar en ny JSON-fil för ett inskickat ärende upptäcker Power Automate förändringen och startar flödet automatiskt.

### Konfiguration

För att Power Automate skulle kunna läsa från Azure Storage skapades en anslutning mot Storage Account `stnovatrixv388`.

```text
Storage Account: stnovatrixv388
Container: arenden
Trigger: När en blob läggs till eller ändras (enbart egenskaper) (V2)
```

Anslutningen autentiserades med Storage Account-nyckeln från Azure.

### Motivering

Genom att använda Azure Blob Storage som triggerpunkt skapas en automatisk koppling mellan webbapplikationen och Microsoft 365. När ett nytt ärende sparas i lagringskontot startas flödet utan manuell hantering.

## Steg 2 - Villkor

Eftersom containern får in både JSON-filer och PNG-bilder aktiverades triggern för båda filtyperna. Flödet försökte då behandla PNG-filer som JSON, vilket ledde till fel i mitt fall. Därför lades villkoret "body/Name slutar med .json" till för att endast bearbeta JSON-filer. Falskt-grenen lämnades tom eftersom flödet bara ska hantera JSON-filer. Om filen inte är en JSON-fil (till exempel en PNG-bild) ska inget hända, och flödet avslutas direkt.

---

## Steg 3 - Parse JSON

### Syfte
Åtgärden **Parse JSON** används för att tolka innehållet i JSON-filen så att fälten kan användas som dynamiskt innehåll i resten av flödet.

### Content

När filen läses från Azure Blob Storage tas innehållet emot i Base64-format. Därför används uttrycket nedan för att omvandla innehållet till vanlig text innan det parsas.

```text
base64ToString(body('Read_Json_File')?['$content'])
```

### Schema

Schemat beskriver vilka fält som finns i JSON-filen och vilken datatyp varje fält har.

```json
{
  "type": "object",
  "properties": {
    "id": {
      "type": "string"
    },
    "name": {
      "type": "string"
    },
    "mail": {
      "type": "string"
    },
    "message": {
      "type": "string"
    },
    "created": {
      "type": "string"
    },
    "image": {
      "type": "string"
    },
    "image_name": {
      "type": "string"
    }
  }
}
```

Dessa värden används senare för att skapa e-postmeddelanden och hantera eventuella bilagor.

### Resultat

Så här ser flödet ut efter att JSON-filen har lästs in och ärendedatan har extraherats.

<img width="900" height="430" alt="image" src="https://github.com/user-attachments/assets/c7bbb193-df80-41c5-ba10-e9352f999b48" />

---

## Steg - 4 Villkor 2


Detta villkor används för att kontrollera om ärendet innehåller en bild som ska bifogas i e-postmeddelandet.

Efter att JSON-filen har lästs in finns flera fält tillgängliga, bland annat `image_name`. Detta fält innehåller filnamnet på bilden om en bild har bifogats tillsammans med ärendet.

Villkoret kontrollerar därför om `image_name` inte är tomt.

- **Sant (True)** – Ett filnamn finns i `image_name`. Flödet fortsätter då med att hämta bilden från Blob Storage och bifoga den i e-postmeddelandet.
- **Falskt (False)** – Fältet `image_name` är tomt. Det betyder att ingen bild finns kopplad till ärendet och e-postmeddelandet skickas utan bilaga.

Detta villkor behövs för att flödet ska kunna hantera både ärenden med bild eller utan bild. 


### Falskt-gren – Skicka e-post

Om villkoret **Check if Image Exists** är falskt betyder det att fältet `image_name` är tomt och att ingen bild har bifogats i ärendet.

Därför behöver flödet inte läsa någon bild från Blob Storage eller lägga till någon bilaga i e-postmeddelandet. Istället skickas endast informationen från JSON-filen:

- Namn
- E-postadress
- Meddelande

Denna gren säkerställer att ärenden utan bilder fortfarande hanteras korrekt och att e-postmeddelandet skickas utan att flödet försöker använda en bilaga som inte finns.

---

## Testresultat – Ärende utan bilaga

Ett testärende utan bifogad bild skickades för att verifiera Falskt-grenen. Eftersom fältet `image_name` var tomt skickades e-postmeddelandet utan bilaga.

<img width="600" height="400" alt="Skärmbild 2026-09-30 225840" src="https://github.com/user-attachments/assets/f200f933-19b0-4654-ad5a-a79b8ab02516" />

<img width="386" height="688" alt="Skärmbild 2026-09-30 231840" src="https://github.com/user-attachments/assets/d959633d-8488-4631-900f-7293ec7d1a0a" />


<img width="1956" height="500" alt="Skärmbild 2026-09-30 225910" src="https://github.com/user-attachments/assets/e65a54e3-261a-4756-963a-25f2f6dbc193" />

---

## Sant-gren – Skicka e-post med bilaga

Om villkoret **Check if Image Exists** är sant betyder det att fältet `image_name` innehåller ett värde och att en bild har bifogats i ärendet.

Flödet läser därför bildfilen från Azure Blob Storage och använder informationen från den parsade JSON-filen för att skapa e-postmeddelandet.

Bilden bifogas sedan till e-postmeddelandet tillsammans med följande information:

- Namn
- E-postadress
- Meddelande

Denna gren säkerställer att ärenden med bifogade bilder skickas vidare med korrekt bilaga.


## Extract Image Filename

### Syfte

Åtgärden **Extract Image Filename** används för att hämta namnet på den bifogade bildfilen från JSON-datan.

### Indata

Åtgärden använder informationen från **Extract Ticket Data**.

### Resultat

Steget hämtar värdet från fältet `image_name`. Filnamnet används senare för att läsa in rätt bild från Azure Blob Storage och bifoga den i e-postmeddelandet.

## Read Attached Image

### Syfte

Åtgärden **Read Attached Image** används för att läsa den bild som har bifogats i ärendet från Azure Blob Storage.

### Blob-sökväg

För att hitta rätt bildfil används följande uttryck:

```text
concat('arenden/', body('Extract_Ticket_Data')?['image_name'])
```

Uttrycket kombinerar mappnamnet `arenden/` med filnamnet som hämtas från fältet `image_name` i JSON-datan.

Om `image_name` exempelvis innehåller:

```text
skrivare.png
```

blir den fullständiga sökvägen:

```text
arenden/skrivare.png
```

### Resultat

Steget läser bildfilen från Azure Blob Storage och gör innehållet tillgängligt för nästa steg, där bilden bifogas i e-postmeddelandet.

---

## Send Notification Email

### Syfte

Åtgärden **Send Notification Email** skickar ett e-postmeddelande med informationen från ärendet och den bifogade bilden.

### Innehåll

Följande värden hämtas från den parsade JSON-datan och läggs in i e-postmeddelandet:

- **Name** → Avsändarens namn
- **Mail** → Avsändarens e-postadress
- **Message** → Ärendebeskrivningen

### Bilaga

För att bifoga bilden används följande värden:

#### Namn

```text
body('Extract_Ticket_Data')?['image_name']
```

Detta hämtar filnamnet från JSON-datan och används som bilagans namn i e-postmeddelandet.

#### Innehåll

```text
body('Read_Attached_Image')
```

Detta innehåller bildfilen som lästes från Azure Blob Storage i föregående steg och används som innehåll i bilagan.

### Resultat

E-postmeddelandet skickas med ärendeinformationen och den bifogade bilden. Genom att använda `image_name` som namn och innehållet från **Read Attached Image** säkerställs att rätt bild bifogas i e-postmeddelandet.

### Flödesstruktur

<img width="500" height="600" alt="Skärmbild 2026-09-30 234534" src="https://github.com/user-attachments/assets/d7f14153-356f-446f-81fa-a23c22275117" />


### 

