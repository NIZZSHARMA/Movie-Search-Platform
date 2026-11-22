using MovieSearch.Api.Repositories;
using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;

var builder = WebApplication.CreateBuilder(args);
var connectionString =
    builder.Configuration.GetConnectionString("MovieDatabase")
    ?? throw new InvalidOperationException(
        "MovieDatabase connection string is missing.");

builder.Services.AddDbContext<MovieDbContext>(options =>
    options.UseNpgsql(connectionString));

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.Services.AddScoped<ITitleRepository, TitleRepository>();
var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
