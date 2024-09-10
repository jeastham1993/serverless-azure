namespace Dapr.Order.Api.Orders;

public record OrderDTO
{
    public int OrderId { get; set; }
    
    public string OrderNumber { get; set; }
}