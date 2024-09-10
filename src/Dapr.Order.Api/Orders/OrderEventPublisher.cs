using Dapr.Client;

namespace Dapr.Order.Api.Orders;

public class OrderEventPublisher
{
    private readonly DaprClient _daprClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<OrderEventPublisher> _logger;

    public OrderEventPublisher(DaprClient daprClient, IConfiguration configuration, ILogger<OrderEventPublisher> logger)
    {
        _daprClient = daprClient;
        _configuration = configuration;
        _logger = logger;
    }
    
    public async Task PublishOrderCreatedEventFor(Order order)
    {
        var pubSubName = _configuration["Messaging:PubSubName"];
        var topicName = _configuration["Messaging:OrderCreatedTopicName"]; 
        
        _logger.LogInformation("Publishing to {pubSubName} with topic {topicName}", pubSubName, topicName);
        
        await _daprClient.PublishEventAsync(pubSubName,
            topicName, new OrderCreatedEvent()
            {
                Order = order.AsDTO()
            });
    }
}