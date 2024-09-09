namespace Dapr.Order.Api.PublicEventTranslator;

public record PublicOrderCreatedEventV1
{
    public string OrderId { get; set; }
}