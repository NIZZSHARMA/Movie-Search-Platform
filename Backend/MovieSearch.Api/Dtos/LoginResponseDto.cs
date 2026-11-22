namespace MovieSearch.Api.Dtos;

public class LoginResponseDto
{
    public required string AccessToken { get; set; }

    public string TokenType { get; set; } = "Bearer";

    public DateTime ExpiresAtUtc { get; set; }

    public required UserDto User { get; set; }
}