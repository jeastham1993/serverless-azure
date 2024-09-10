using Dapr.PaymentProcessor.ProcessOrderCreated;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateSlimBuilder(args);
builder.Configuration
    .AddEnvironmentVariables();

builder.Services.AddDaprClient();

var otlpEndpoint = builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"];

if (!string.IsNullOrEmpty(otlpEndpoint))
{
    var otel = builder.Services.AddOpenTelemetry();
    otel.ConfigureResource(resource => resource
        .AddService(serviceName: "Dapr.PaymentProcessor"));
            
    otel.WithTracing(tracing =>
    {
        tracing.AddAspNetCoreInstrumentation();
        tracing.AddHttpClientInstrumentation();
        tracing.AddSource("Dapr.PaymentProcessor");
        tracing.AddOtlpExporter(otlpOptions =>
        {
            otlpOptions.Endpoint = new Uri(otlpEndpoint);
        });
    });   
}

var app = builder.Build();

// needed for Dapr pub/sub routing
app.MapSubscribeHandler();
app.UseCloudEvents();
app.AddOrderCompletedProcessing();

await app.RunAsync();