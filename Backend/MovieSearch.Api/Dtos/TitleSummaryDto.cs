namespace MovieSearch.Api.Dtos;

public class TitleSummaryDto
{
    public string? Url { get; set; }

    public required string Tconst { get; set; }

    public string? PrimaryTitle { get; set; }

    public string? TitleType { get; set; }

    public int? StartYear { get; set; }
}