FROM mcr.microsoft.com/dotnet/sdk:8.0 as build

WORKDIR /App
COPY . ./
RUN dotnet publish . -o out -c Release

FROM mcr.microsoft.com/dotnet/aspnet:8.0 as runtime
WORKDIR /App
COPY --from=datadog/serverless-init:1 / /app/
RUN chmod +x /app/dotnet.sh && /app/dotnet.sh
COPY --from=build /App/out .
EXPOSE 8080
ENTRYPOINT ["/app/datadog-init"]
CMD ["dotnet", "Dapr.PaymentProcessor.dll"]