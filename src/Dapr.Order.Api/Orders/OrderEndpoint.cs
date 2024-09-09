using Dapr.Client;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace Dapr.Order.Api.Orders;

[ApiController]
[Route("api/order")]
public class OrderEndpoint
{
    private readonly ILogger<OrderEndpoint> _logger;
    private readonly OrderEventPublisher _eventPublisher;

    public OrderEndpoint(ILogger<OrderEndpoint> logger, OrderEventPublisher eventPublisher)
    {
        _logger = logger;
        _eventPublisher = eventPublisher;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(string id)
    {
        this._logger.LogInformation("Received request for {id}", id);

        return new OkResult();
    }

    [HttpPost("")]
    public async Task<IActionResult> CreateOrder()
    {
        // TODO: Code to store in order repository
        
        var orderId = Guid.NewGuid().ToString();

        await this._eventPublisher.PublishOrderCreatedEventFor(orderId);
        
        return new OkResult();
    }
}