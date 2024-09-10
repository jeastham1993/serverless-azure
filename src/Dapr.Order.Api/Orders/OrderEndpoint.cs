using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using JsonSerializer = System.Text.Json.JsonSerializer;

namespace Dapr.Order.Api.Orders;

[ApiController]
[Route("api/order")]
public class OrderEndpoint
{
    private readonly ILogger<OrderEndpoint> _logger;
    private readonly OrderEventPublisher _eventPublisher;
    private readonly OrdersDbContext _ordersContext;
    private readonly IDistributedCache _cache;

    public OrderEndpoint(ILogger<OrderEndpoint> logger, OrderEventPublisher eventPublisher, OrdersDbContext ordersContext, IDistributedCache cache)
    {
        _logger = logger;
        _eventPublisher = eventPublisher;
        _ordersContext = ordersContext;
        _cache = cache;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(int id)
    {
        var cachedOrderData = await this._cache.GetAsync(id.ToString());

        if (cachedOrderData is not null)
        {
            Activity.Current?.SetTag("cache.hit", true);
            var cachedOrder = JsonSerializer.Deserialize<OrderDTO>(cachedOrderData);

            return new OkObjectResult(cachedOrder);
        }
        
        Activity.Current?.SetTag("cache.hit", false);
        
        var order = await _ordersContext.Orders.FirstOrDefaultAsync(order => order.OrderId == id);

        if (order == null)
        {
            return new NotFoundResult();
        }

        return new OkObjectResult(order.AsDTO());
    }

    [HttpPost("")]
    public async Task<IActionResult> CreateOrder()
    {
        try
        {
            _logger.LogInformation("Creating new order");
            
            var order = new Order()
            {
                OrderNumber = "ORD123"
            };

            _ordersContext.Orders.Add(order);
            await _ordersContext.SaveChangesAsync();

            await this._eventPublisher.PublishOrderCreatedEventFor(order);
        
            return new OkObjectResult(order);
        }
        catch (Exception e)
        {
            _logger.LogError(e, "Failure storing order");
            return new BadRequestResult();
        }
    }
}