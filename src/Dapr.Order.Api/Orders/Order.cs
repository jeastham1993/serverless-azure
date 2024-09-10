namespace Dapr.Order.Api.Orders;

public class Order
{
    public int OrderId { get; set; }
    
    public string OrderNumber { get; set; }

    public OrderDTO AsDTO()
    {
        return new OrderDTO()
        {
            OrderNumber = this.OrderNumber,
            OrderId = this.OrderId
        };
    }
}