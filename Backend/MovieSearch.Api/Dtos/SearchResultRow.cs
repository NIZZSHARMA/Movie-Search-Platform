namespace MovieSearch.Api.Dtos;

public class SearchResultRow
{
    public string? Id { get; set; }

    public string? Name { get; set; }

    public string? Plot { get; set; }

    public long TotalCount { get; set; }
}