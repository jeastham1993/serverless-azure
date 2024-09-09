using Dapr;
using Dapr.Client;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDaprClient();

var app = builder.Build();

// needed for Dapr pub/sub routing
app.MapSubscribeHandler();
app.UseCloudEvents();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var daprClient = app.Services.GetRequiredService<DaprClient>();
var ordersHttpClient = DaprClient.CreateInvokeHttpClient(appId: "orders");

app.MapPost("/order-created",
    [Topic("orders", "orders.orderCreated.v1")] async (
        CreatedEventV1 evt) =>
    {
        app.Logger.LogInformation($"Received event for order {evt.OrderId}");

        var res = await ordersHttpClient.GetAsync($"/order/{evt.OrderId}");
        
        app.Logger.LogInformation(res.StatusCode.ToString());
        app.Logger.LogInformation(await res.Content.ReadAsStringAsync());
    });

app.Run();

record CreatedEventV1
{
    public string OrderId { get; set; }
}