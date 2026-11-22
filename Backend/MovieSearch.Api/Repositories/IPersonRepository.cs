using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface IPersonRepository
{
    Task<Person?> GetByIdAsync(
        string nconst,
        CancellationToken cancellationToken = default);

    Task<int> CountAsync(
        CancellationToken cancellationToken = default);

    Task<List<Person>> GetPageAsync(
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<int> CountTitlesAsync(
        string nconst,
        CancellationToken cancellationToken = default);

    Task<List<Title>> GetTitlesPageAsync(
        string nconst,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);
}