# Use Microsoft's official build .NET image.
# https://hub.docker.com/_/microsoft-dotnet-core-sdk/
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-alpine AS build
WORKDIR /app

# Copy local code to the container image.
COPY . ./

# Install production dependencies
# Restore as distinct layers
RUN dotnet restore Amathus.Reader
RUN dotnet restore Amathus.Web

# Build a release artifact.
RUN dotnet publish Amathus.Web -c Release -o out

# Use Microsoft's official runtime .NET image.
# https://hub.docker.com/_/microsoft-dotnet-core-aspnet/
# Note: Not using 'alpine' here due to some Firebase dependency
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS runtime
WORKDIR /app
COPY --from=build /app/out .

# Run the web service on container startup.
ENTRYPOINT ["dotnet", "Amathus.Web.dll"]
