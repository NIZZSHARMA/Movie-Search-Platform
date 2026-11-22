using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface ITitleBookmarkRepository
{
    Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default);

    Task<List<Title>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<bool> ExistsAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default);

    Task<bool> AddAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        long userId,
        string tconst,
        CancellationToken cancellationToken = default);
}