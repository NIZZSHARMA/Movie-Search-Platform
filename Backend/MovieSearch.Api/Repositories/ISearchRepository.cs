using MovieSearch.Api.Dtos;

namespace MovieSearch.Api.Repositories;

public interface ISearchRepository
{
    Task<List<SearchResultRow>> SearchTitlesAsync(
        long userId,
        string query,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<List<SearchResultRow>> SearchPersonsAsync(
        long userId,
        string query,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<List<SearchResultRow>> SearchStructuredAsync(
        long userId,
        string title,
        string plot,
        string character,
        string personName,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default);
}