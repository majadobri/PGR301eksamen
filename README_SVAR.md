# README_SVAR – PGR301 Eksamen 2026

Kandidatnummer: 62

## Oppgave 1A

Dockerfilen er basert på den vi lagde i Docker-labben, og er en multi-stage build:

1. **Build-steg:** Et Maven-image med Java 21 bygger JAR-filen.
2. **Runtime-steg:** Et lite image med bare Java 21 runtime (JRE). Her kopieres kun JAR-filen inn.

Maven, JDK og kildekoden blir dermed igjen i build-steget. Det ferdige imaget blir mindre og inneholder bare det som trengs for å kjøre appen.

### Slik kjører du containeren

Bygg imaget fra rotmappen i repoet:

```bash
docker build -t marija .
```

Start containeren:

```bash
docker run -p 9999:8080 \
  -e AWS_ACCESS_KEY_ID=<aws-access-key> \
  -e AWS_SECRET_ACCESS_KEY=<aws-secret-key> \
  -e AWS_REGION=eu-west-1 \
  -e S3_BUCKET=minbucket-62 \
  marija
```

Appen kjører på port 8080 inne i containeren, og `-p 9999:8080` gjør den tilgjengelig på localhost:9999. AWS-nøklene sendes inn når containeren starter, så de aldri ligger i selve imaget.

Test at det fungerer:

```bash
curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze
```

## Oppgave 1B

Workflow-filen ligger i `.github/workflows/docker.yml`, og bygger på workflowen fra Docker-labben.

Lenke til grønn kjøring: https://github.com/majadobri/PGR301eksamen/actions/runs/41659363324

Workflowen kjører bare ved push til `main`. Den bygger imaget og pusher det til ECR-repoet mitt, `marija`, som jeg opprettet med AWS CLI. AWS-nøklene ligger som GitHub Secrets.

### Tagging-strategi

Hvert image tagges med den korte commit-SHA-en, for eksempel `marija:efb348a`. Jeg valgte dette fordi:
- Hver commit får sin egen tag, så ingen bygg overskriver hverandre.
- Man ser nøyaktig hvilken kode som kjører, fordi taggen peker rett til en commit i GitHub.
- Det er enkelt å rulle tilbake til en tidligere versjon.
- Terraform kan deploye en bestemt versjon i oppgave 2. Med bare `latest` vet man ikke hva som faktisk kjører.

## Oppgave 2A

All Terraform-kode ligger i `infra/`. Jeg har delt den i flere filer etter tema:

- `providers.tf` – AWS-provider
- `backend.tf` – remote state (se 2B)
- `variables.tf` – region, kandidatnummer og image-tag
- `s3.tf` – S3-bucket for bildene (`minbucket-62`)
- `iam.tf` – task role for appen
- `ecs.tf` – ECS Express-tjenesten
- `outputs.tf` – URL til tjenesten, bucket-navn og task role

Tjenesten kjører imaget fra ECR-repoet `marija` med taggen som sendes inn i `image_tag`. Som execution role og infrastructure role bruker jeg de ferdige rollene i klassekontoen.

Appen må selv kunne kalle AWS-tjenester, så jeg har laget en egen task role (`wishifai-task-role-62`). Den har bare tilgangene appen trenger:

- `s3:PutObject` og `s3:GetObject` på min egen bucket
- `rekognition:DetectLabels` for å finne objekter i bildet
- `bedrock:InvokeModel` og `bedrock:Converse` for å lage gaveforslag

`S3_BUCKET` settes automatisk til navnet på bucketen Terraform lager, så den aldri må skrives inn for hånd.

Offentlig URL: https://wi-37b53dabe0e6491aa7aa5525a818722d.ecs.eu-west-1.on.aws

## Oppgave 2B

Terraform-state lagres i den delte bucketen `pgr301-terraform-state` med nøkkelen:

```
wishifai/62/terraform.tfstate
```

Kandidatnummeret i nøkkelen gjør at staten min ikke kolliderer med andre studenter.

Jeg har også slått på låsing av staten (`use_lockfile = true`), slik som i remote state-labben. Det betyr at bare én person kan endre infrastrukturen om gangen, så ingen overskriver hverandres endringer. I tillegg er state-filen kryptert (`encrypt = true`).