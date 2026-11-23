using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public class SearchHistoryRepository : ISearchHistoryRepository
{
    private readonly MovieDbContext _context;

    public SearchHistoryRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        return _context.UserSearchHistories.CountAsync(
            item => item.UserId == userId,
            cancellationToken);
    }

    public Task<List<UserSearchHistory>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return _context.UserSearchHistories
            .AsNoTracking()
            .Where(item => item.UserId == userId)
            .OrderByDescending(item => item.PerformedAt)
            .ThenByDescending(item => item.SearchId)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public Task<UserSearchHistory?> GetByIdAsync(
        long userId,
        long searchId,
        CancellationToken cancellationToken = default)
    {
        return _context.UserSearchHistories
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item => item.UserId == userId
                    && item.SearchId == searchId,
                cancellationToken);
    }

    public async Task<bool> DeleteAsync(
        long userId,
        long searchId,
        CancellationToken cancellationToken = default)
    {
        var count = await _context.UserSearchHistories
            .Where(item => item.UserId == userId
                && item.SearchId == searchId)
            .ExecuteDeleteAsync(cancellationToken);

        return count > 0;
    }

    public async Task ClearAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        await _context.UserSearchHistories
            .Where(item => item.UserId == userId)
            .ExecuteDeleteAsync(cancellationToken);
    }
}