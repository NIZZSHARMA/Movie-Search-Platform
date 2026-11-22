using System.ComponentModel.DataAnnotations;

namespace MovieSearch.Api.Dtos;

public class LoginDto
{
    [Required]
    [StringLength(100, MinimumLength = 3)]
    public required string Username { get; set; }

    [Required]
    [StringLength(128, MinimumLength = 8)]
    public required string Password { get; set; }
}