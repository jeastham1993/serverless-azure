using Dapr.Order.Api.Adapters;
using Dapr.Order.Api.Orders;
using Dapr.Order.Api.PublicEventTranslator;
using Microsoft.EntityFrameworkCore;
using Momento.Sdk.Auth;
using Momento.Sdk.Config;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateSlimBuilder(args);
builder.Configuration
    .AddEnvironmentVariables();

builder.Services.AddDaprClient();
builder.Services.AddControllers();
builder.Services.AddSingleton<OrderEventPublisher>();
builder.Services.AddDbContext<OrdersDbContext>(options =>
{
    var connectionString = builder.Configuration["OrdersDbConnectionString"];
    options.UseNpgsql(connectionString);
});

builder.Services.AddMomentoCache(options =>
{
    options.Configuration = Configurations.InRegion.LowLatency.Latest();
    options.CredentialProvider = new EnvMomentoTokenProvider("MOMENTO_API_KEY");
    options.DefaultTtl = TimeSpan.FromMinutes(1);
    options.CacheName = "dapr.orders.api";
});

var otlpEndpoint = builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"];

if (!string.IsNullOrEmpty(otlpEndpoint))
{
    var otel = builder.Services.AddOpenTelemetry();
    otel.ConfigureResource(resource => resource
        .AddService(serviceName: "Dapr.Order.Api"));
            
    otel.WithTracing(tracing =>
    {
        tracing.AddAspNetCoreInstrumentation();
        tracing.AddHttpClientInstrumentation();
        tracing.AddEntityFrameworkCoreInstrumentation();
        tracing.AddSource("Dapr.Order.Api");
        tracing.AddOtlpExporter(otlpOptions =>
        {
            otlpOptions.Endpoint = new Uri(otlpEndpoint);
        });
    });   
}

var app = builder.Build();

using var scope = app.Services.CreateScope();
var dbContext = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
await dbContext.Database.MigrateAsync();

// Dapr will send serialized event object vs. being raw CloudEvent
app.MapSubscribeHandler();
app.UseCloudEvents();

app.AddEventTranslatorEndpoints();

app.MapControllers();

await app.RunAsync();

