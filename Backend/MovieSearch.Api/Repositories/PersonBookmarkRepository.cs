using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;
using Npgsql;

namespace MovieSearch.Api.Repositories;

public class PersonBookmarkRepository : IPersonBookmarkRepository
{
    private readonly MovieDbContext _context;

    public PersonBookmarkRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        return _context.UserBookmarkPersons.CountAsync(
            bookmark => bookmark.UserId == userId,
            cancellationToken);
    }

    public Task<List<Person>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return (
            from bookmark in _context.UserBookmarkPersons.AsNoTracking()
            join person in _context.Persons.AsNoTracking()
                on bookmark.Nconst equals person.Nconst
            where bookmark.UserId == userId
            orderby person.Nconst
            select person)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public Task<bool> ExistsAsync(
        long userId,
        string nconst,
        CancellationToken cancellationToken = default)
    {
        return _context.UserBookmarkPersons.AnyAsync(
            bookmark => bookmark.UserId == userId
                && bookmark.Nconst == nconst,
            cancellationToken);
    }

    public async Task<bool> AddAsync(
        long userId,
        string nconst,
        CancellationToken cancellationToken = default)
    {
        if (await ExistsAsync(userId, nconst, cancellationToken))
        {
            return false;
        }

        var bookmark = new UserBookmarkPerson
        {
            UserId = userId,
            Nconst = nconst
        };

        _context.UserBookmarkPersons.Add(bookmark);

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
        string nconst,
        CancellationToken cancellationToken = default)
    {
        var deletedCount = await _context.UserBookmarkPersons
            .Where(bookmark => bookmark.UserId == userId
                && bookmark.Nconst == nconst)
            .ExecuteDeleteAsync(cancellationToken);

        return deletedCount > 0;
    }
}