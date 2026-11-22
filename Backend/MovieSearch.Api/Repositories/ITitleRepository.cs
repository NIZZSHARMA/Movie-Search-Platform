using MovieSearch.Api.Dtos;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface ITitleRepository
{
    Task<Title?> GetByIdAsync(
        string tconst,
        CancellationToken cancellationToken = default);

    Task<int> CountAsync(
        CancellationToken cancellationToken = default);

    Task<List<Title>> GetPageAsync(
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<OmdbExtra?> GetOmdbExtraAsync(
        string tconst,
        CancellationToken cancellationToken = default);

    Task<List<string>> GetGenresAsync(
        string tconst,
        CancellationToken cancellationToken = default);

    Task<int> CountCreditsAsync(
        string tconst,
        CancellationToken cancellationToken = default);

    Task<List<CreditDto>> GetCreditsPageAsync(
        string tconst,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<CreditDto?> GetCreditByIdAsync(
        string tconst,
        int ordering,
        CancellationToken cancellationToken = default);
}