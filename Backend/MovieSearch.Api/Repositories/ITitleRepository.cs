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
    
}