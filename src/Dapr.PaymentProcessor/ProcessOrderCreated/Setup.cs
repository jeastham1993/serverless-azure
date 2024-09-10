using Dapr.Client;

namespace Dapr.PaymentProcessor.ProcessOrderCreated;

public static class Setup
{
    public static WebApplication AddOrderCompletedProcessing(this WebApplication app)
    {
        var ordersHttpClient = DaprClient.CreateInvokeHttpClient("orders");
        
        app.MapPost("/order-created",
            [Topic("public", "orders.ordercreated.v1")] async (
                OrderCreatedEvent evt) =>
            {
                var res = await ordersHttpClient.GetAsync($"/api/order/{evt.OrderId}");
        
                app.Logger.LogInformation(res.StatusCode.ToString());
                app.Logger.LogInformation(await res.Content.ReadAsStringAsync());
            });

        return app;
    }
}