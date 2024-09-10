using Microsoft.EntityFrameworkCore;

namespace Dapr.Order.Api.Orders;

public class OrdersDbContext : DbContext
{
    public OrdersDbContext(DbContextOptions<OrdersDbContext> options) : base(options){}
    
    public DbSet<Order> Orders { get; set; }
    
    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Order>(order =>
        {
            order.HasKey("OrderId");
        });
    }

}