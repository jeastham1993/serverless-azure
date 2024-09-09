namespace Dapr.Order.Api.Orders;

public record OrderCreatedEvent
{
    public string OrderId { get; set; }
}