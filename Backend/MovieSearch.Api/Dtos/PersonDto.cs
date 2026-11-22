namespace MovieSearch.Api.Dtos;

public class PersonDto
{
    public string? Url { get; set; }

    public required string Nconst { get; set; }

    public string? PrimaryName { get; set; }

    public int? BirthYear { get; set; }

    public int? DeathYear { get; set; }
}