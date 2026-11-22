using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Data;

public class MovieDbContext : DbContext
{
    public MovieDbContext(DbContextOptions<MovieDbContext> options)
        : base(options)
    {
    }

    public DbSet<Title> Titles => Set<Title>();
    public DbSet<Person> Persons => Set<Person>();
    public DbSet<OmdbExtra> OmdbExtras => Set<OmdbExtra>();
}