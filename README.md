# Amathus

Amathus is a RSS reader and transformer. Written in ASP.NET Core Web and deploy to Cloud Run on Google Cloud.

## Run code locally
Inside `Amathus.Web` folder:

```bash
dotnet run
```

## Run Docker image locally

Go to `Amathus` folder where `Amathus.sln` is.

Build image:

```bash
docker build -t amathus . 
```

Run image:

```bash
docker run -p 8080:8080 amathus
```
 
## Deploy to Cloud Run

Go to `Amathus` folder where `Amathus.sln` is.

```bash
export PROJECT_ID="$(gcloud config get-value core/project)"
export SERVICE_NAME=amathus
```

Build:

```bash
gcloud builds submit \
  --tag gcr.io/${PROJECT_ID}/${SERVICE_NAME}
```

Deploy:

```bash
gcloud run deploy ${SERVICE_NAME} \
  --image gcr.io/${PROJECT_ID}/${SERVICE_NAME} \
  --platform managed \
  --allow-unauthenticated
```