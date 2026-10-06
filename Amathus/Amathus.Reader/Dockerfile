# Use Microsoft's official build .NET image.
# https://hub.docker.com/_/microsoft-dotnet-sdk/
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy local code to the container image.
COPY . ./

# Install production dependencies
# Restore as distinct layers
RUN dotnet restore Amathus.Common
RUN dotnet restore Amathus.Reader

# Build a release artifact.
RUN dotnet publish Amathus.Reader -c Release -o out

# Use Microsoft's official runtime .NET image.
# https://hub.docker.com/_/microsoft-dotnet-aspnet/
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/out .

# Run the web service on container startup.
ENTRYPOINT ["dotnet", "Amathus.Reader.dll"]
