using Dapr.Client;
using Dapr.Order.Api.Orders;

namespace Dapr.Order.Api.PublicEventTranslator;

public static class Setup
{
    public static WebApplication AddEventTranslatorEndpoints(this WebApplication app)
    {
        var daprClient = app.Services.GetRequiredService<DaprClient>();
        
        app.MapPost("/order-created",
            [Topic("orders", "orderCreated")] async (
                OrderCreatedEvent evt) =>
            {
                var pubSubName = app.Configuration["Messaging:Public:PubSubName"];
                var topicName = app.Configuration["Messaging:Public:OrderCreatedTopicName"];
                
                app.Logger.LogInformation("Publishing to {pubSubName} with topic {topicName}", pubSubName, topicName);
    
                await daprClient.PublishEventAsync(pubSubName, topicName, new PublicOrderCreatedEventV1()
                {
                    OrderId = evt.OrderId
                });
            });

        return app;
    }
}