using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public class UserRatingRepository : IUserRatingRepository
{
    private readonly MovieDbContext _context;

    public UserRatingRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        return _context.UserTitleRatings.CountAsync(
            item => item.UserId == userId,
            cancellationToken);
    }

    public Task<List<UserTitleRating>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return _context.UserTitleRatings
            .AsNoTracking()
            .Where(item => item.UserId == userId)
            .OrderBy(item => item.Tconst)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public Task<UserTitleRating?> GetByTitleAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default)
    {
        return _context.UserTitleRatings
            .AsNoTracking()
            .SingleOrDefaultAsync(
                item => item.UserId == userId
                    && item.Tconst == tconst,
                cancellationToken);
    }

    public async Task<UserTitleRating> SetAsync(
        long userId,
        string tconst,
        int rating,
        CancellationToken cancellationToken = default)
    {
        if (rating < 1 || rating > 10)
        {
            throw new ArgumentOutOfRangeException(nameof(rating));
        }

        await using var transaction =
            await _context.Database.BeginTransactionAsync(
                cancellationToken);

        // Parameters are passed separately from the SQL text.
        // The database function updates both rating and history.
        await _context.Database.ExecuteSqlInterpolatedAsync(
            $"SELECT movie.rate({userId}, {tconst}, {rating})",
            cancellationToken);

        var saved = await _context.UserTitleRatings
            .AsNoTracking()
            .SingleAsync(
                item => item.UserId == userId
                    && item.Tconst == tconst,
                cancellationToken);

        await transaction.CommitAsync(cancellationToken);

        return saved;
    }

    public async Task<bool> DeleteAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default)
    {
        await using var transaction =
            await _context.Database.BeginTransactionAsync(
                cancellationToken);

        // Use the same title lock as movie.rate.
        await _context.Database.ExecuteSqlInterpolatedAsync(
            $"SELECT tconst FROM movie.title WHERE tconst = {tconst} FOR UPDATE",
            cancellationToken);

        var deletedCount = await _context.UserTitleRatings
            .Where(item => item.UserId == userId
                && item.Tconst == tconst)
            .ExecuteDeleteAsync(cancellationToken);

        await transaction.CommitAsync(cancellationToken);

        return deletedCount > 0;
    }
}