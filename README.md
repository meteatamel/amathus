# Amathus

Amathus reads RSS feeds of some news sources, transforms them into a common format and exposes them behind a Web API. Written in ASP.NET Core and deployed to Cloud Run on Google Cloud.

## Run locally

### Amathus.Web

Inside `Amathus.Web` folder:

```bash
dotnet run
```

### Amathus.Reader

Inside `Amathus.Reader` folder:

```bash
dotnet run
```

### Amathus.Converter

Inside 'Amathus.Converter' folder:

```bash
dotnet run
```

## Run Docker image locally

Inside `Amathus` folder where `Amathus.sln` is.

### Amathus.Web

Build image:

```bash
docker build -t amathus-web -f Amathus.Web/Dockerfile .
```

Run image:

```bash
docker run -p 8080:8080 amathus-web
```

### Amathus.Reader

Build image:

```bash
docker build -t amathus-reader -f Amathus.Reader/Dockerfile .
```

Run image:

```bash
docker run -p 8080:8080 amathus-reader
```

### Amathus.Converter

Build image:

```bash
docker build -t amathus-converter -f Amathus.Converter/Dockerfile .
```

Run image:

```bash
docker run -p 8080:8080 amathus-converter
```

## Deploy to Cloud Run

Make sure `gcloud` points to the right project and you're in `Amathus` folder where `Amathus.sln` is.

Enable Cloud Build and Cloud Run (one time):

```bash
scripts/enable
```

### Amathus.Web

Build:

```bash
scripts/build web
```

Deploy:

```bash
scripts/deploy web
```

### Amathus.Reader

Build:

```bash
scripts/build reader
```

Deploy:

```bash
scripts/deploy reader
```

(One time) Deploy Scheduler job to invoke it:

```bash
scripts/schedule reader
```

### Amathus.Converter

Build:

```bash
scripts/build converter
```

Deploy:

```bash
scripts/deploy converter
```

TODO: Setup Cloud Storage and Pub/Sub

