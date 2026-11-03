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