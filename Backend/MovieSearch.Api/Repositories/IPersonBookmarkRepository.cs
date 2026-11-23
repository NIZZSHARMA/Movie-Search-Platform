using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface IPersonBookmarkRepository
{
    Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default);

    Task<List<Person>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<bool> ExistsAsync(
        long userId,
        string nconst,
        CancellationToken cancellationToken = default);

    Task<bool> AddAsync(
        long userId,
        string nconst,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        long userId,
        string nconst,
        CancellationToken cancellationToken = default);
}