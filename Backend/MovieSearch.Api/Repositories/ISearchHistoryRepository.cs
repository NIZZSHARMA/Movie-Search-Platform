using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface ISearchHistoryRepository
{
    Task<int> CountAsync(
        long userId,
        CancellationToken cancellationToken = default);

    Task<List<UserSearchHistory>> GetPageAsync(
        long userId,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<UserSearchHistory?> GetByIdAsync(
        long userId,
        long searchId,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        long userId,
        long searchId,
        CancellationToken cancellationToken = default);

    Task ClearAsync(
        long userId,
        CancellationToken cancellationToken = default);
}