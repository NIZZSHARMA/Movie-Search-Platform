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

    public DbSet<TitleGenre> TitleGenres => Set<TitleGenre>();

    public DbSet<Credit> Credits => Set<Credit>();

    public DbSet<TitleRating> TitleRatings => Set<TitleRating>();
    public DbSet<AppUser> Users => Set<AppUser>();

    public DbSet<UserBookmarkTitle> UserBookmarkTitles
    => Set<UserBookmarkTitle>();

    public DbSet<UserBookmarkPerson> UserBookmarkPersons
    => Set<UserBookmarkPerson>();

    public DbSet<UserTitleRating> UserTitleRatings
    => Set<UserTitleRating>();

    public DbSet<UserSearchHistory> UserSearchHistories
    => Set<UserSearchHistory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<TitleGenre>()
            .HasKey(item => new { item.Tconst, item.Genre });

        modelBuilder.Entity<Credit>()
            .HasKey(item => new { item.Tconst, item.Ordering });

        modelBuilder.Entity<TitleRating>()
            .HasNoKey()
            .ToView("title_rating", "movie");
    }
}