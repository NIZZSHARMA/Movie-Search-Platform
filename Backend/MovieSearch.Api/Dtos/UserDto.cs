namespace MovieSearch.Api.Dtos;

public class UserDto
{
    public string? Url { get; set; }

    public long UserId { get; set; }

    public required string Username { get; set; }

    public required string Email { get; set; }
}