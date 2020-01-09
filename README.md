# Amathus

Amathus reads RSS feeds of some news sources, transforms them into a common format and exposes them behind a Web API. Written in ASP.NET Core and deployed to Cloud Run on Google Cloud.

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

Set some variables:

```bash
export PROJECT_ID="$(gcloud config get-value core/project)"
export SERVICE_NAME=amathus
```

Enable Cloud Build and Cloud Run:

```bash
gcloud services enable --project ${PROJECT_ID} \
    cloudbuild.googleapis.com \
    run.googleapis.com
```

Inside `Amathus` folder where `Amathus.sln` is:

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
