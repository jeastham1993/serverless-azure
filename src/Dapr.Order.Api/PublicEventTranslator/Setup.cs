using System.Text.Json;
using Dapr.Client;
using Dapr.Order.Api.Orders;
using Microsoft.Extensions.Caching.Distributed;

namespace Dapr.Order.Api.PublicEventTranslator;

public static class Setup
{
    public static WebApplication AddEventTranslatorEndpoints(this WebApplication app)
    {
        var daprClient = app.Services.GetRequiredService<DaprClient>();
        var cache = app.Services.GetRequiredService<IDistributedCache>();
        
        app.MapPost("/order-created",
            [Topic("orders", "ordercreated")] async (
                OrderCreatedEvent evt) =>
            {
                var pubSubName = app.Configuration["Messaging:Public:PubSubName"];
                var topicName = app.Configuration["Messaging:Public:OrderCreatedTopicName"];
                
                app.Logger.LogInformation("Caching order data");

                await cache.SetAsync(evt.Order.OrderId.ToString(), JsonSerializer.SerializeToUtf8Bytes(evt.Order));
                
                app.Logger.LogInformation("Publishing to {pubSubName} with topic {topicName}", pubSubName, topicName);
    
                await daprClient.PublishEventAsync(pubSubName, topicName, new PublicOrderCreatedEventV1()
                {
                    OrderId = evt.Order.OrderId.ToString()
                });
            });

        return app;
    }
}