using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public class TitleRepository : ITitleRepository
{
    private readonly MovieDbContext _context;

    public TitleRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<Title?> GetByIdAsync(
        string tconst,
        CancellationToken cancellationToken = default)
    {
        return _context.Titles
            .AsNoTracking()
            .SingleOrDefaultAsync(
                title => title.Tconst == tconst,
                cancellationToken);
    }

    public Task<int> CountAsync(
        CancellationToken cancellationToken = default)
    {
        return _context.Titles.CountAsync(cancellationToken);
    }

    public Task<List<Title>> GetPageAsync(
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return _context.Titles
            .AsNoTracking()
            .OrderBy(title => title.Tconst)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public Task<OmdbExtra?> GetOmdbExtraAsync(
    string tconst,
    CancellationToken cancellationToken = default)
{
    return _context.OmdbExtras
        .AsNoTracking()
        .SingleOrDefaultAsync(
            extra => extra.Tconst == tconst,
            cancellationToken);
}
public Task<List<string>> GetGenresAsync(
    string tconst,
    CancellationToken cancellationToken = default)
{
    return _context.TitleGenres
        .AsNoTracking()
        .Where(item => item.Tconst == tconst)
        .OrderBy(item => item.Genre)
        .Select(item => item.Genre)
        .ToListAsync(cancellationToken);
}

}