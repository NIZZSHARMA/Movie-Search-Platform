using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;
using Npgsql;

namespace MovieSearch.Api.Repositories;

public class TitleBookmarkRepository : ITitleBookmarkRepository
{
    private readonly MovieDbContext _context;

    public TitleBookmarkRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        return _context.UserBookmarkTitles.CountAsync(
            bookmark => bookmark.UserId == userId,
            cancellationToken);
    }

    public Task<List<Title>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return (
            from bookmark in _context.UserBookmarkTitles.AsNoTracking()
            join title in _context.Titles.AsNoTracking()
                on bookmark.Tconst equals title.Tconst
            where bookmark.UserId == userId
            orderby title.Tconst
            select title)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public Task<bool> ExistsAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default)
    {
        return _context.UserBookmarkTitles.AnyAsync(
            bookmark => bookmark.UserId == userId
                && bookmark.Tconst == tconst,
            cancellationToken);
    }

    public async Task<bool> AddAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default)
    {
        if (await ExistsAsync(userId, tconst, cancellationToken))
        {
            return false;
        }

        var bookmark = new UserBookmarkTitle
        {
            UserId = userId,
            Tconst = tconst
        };

        _context.UserBookmarkTitles.Add(bookmark);

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
        catch (DbUpdateException exception)
            when (exception.InnerException is PostgresException
            {
                SqlState: PostgresErrorCodes.UniqueViolation
            })
        {
            _context.Entry(bookmark).State = EntityState.Detached;
            return false;
        }
    }

    public async Task<bool> DeleteAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default)
    {
        var deletedCount = await _context.UserBookmarkTitles
            .Where(bookmark => bookmark.UserId == userId
                && bookmark.Tconst == tconst)
            .ExecuteDeleteAsync(cancellationToken);

        return deletedCount > 0;
    }
}