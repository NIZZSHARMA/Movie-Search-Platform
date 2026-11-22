using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface ITitleRepository
{
    Task<Title?> GetByIdAsync(
        string tconst,
        CancellationToken cancellationToken = default);
}