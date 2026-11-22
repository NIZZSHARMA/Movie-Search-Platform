namespace MovieSearch.Api.Dtos;

public class CreditDto
{
    public string? Url { get; set; }

    public required string Tconst { get; set; }

    public int Ordering { get; set; }

    public required string Nconst { get; set; }

    public string? PersonUrl { get; set; }

    public string? PrimaryName { get; set; }

    public string? Category { get; set; }

    public string? Job { get; set; }

    public string? Characters { get; set; }
}