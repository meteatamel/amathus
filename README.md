# Amathus

## Run code locally
Inside `Amathus.Web` folder:

```bash
dotnet run
```

## Run Docker image locally

Inside `Amathus` folder where `Amathus.sln` is:

Build image:

```bash
docker build -f Amathus.Web/Dockerfile -t amathus . 
```

Run image:

```bash
docker run -p 8080:8080 amathus
```
 
