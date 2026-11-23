using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface IUserRatingRepository
{
    Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default);

    Task<List<UserTitleRating>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<UserTitleRating?> GetByTitleAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default);

    Task<UserTitleRating> SetAsync(
        long userId,
        string tconst,
        int rating,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default);
}