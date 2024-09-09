using Dapr.Order.Api.Orders;
using Dapr.Order.Api.PublicEventTranslator;

var builder = WebApplication.CreateSlimBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddDaprClient();
builder.Services.AddSingleton<OrderEventPublisher>();
builder.Services.AddControllers();

var app = builder.Build();

// Dapr will send serialized event object vs. being raw CloudEvent
app.MapSubscribeHandler();
app.UseCloudEvents();

app.AddEventTranslatorEndpoints();

app.MapControllers();

app.Run();

