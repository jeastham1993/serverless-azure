namespace Dapr.Order.Api.Orders;

public record OrderCreatedEvent
{
    public OrderDTO Order { get; set; }
}