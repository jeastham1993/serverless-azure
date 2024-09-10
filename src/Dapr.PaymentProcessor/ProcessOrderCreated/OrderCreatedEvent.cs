namespace Dapr.PaymentProcessor.ProcessOrderCreated;

public record OrderCreatedEvent
{
    public string OrderId { get; set; }
}