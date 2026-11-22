using System.ComponentModel.DataAnnotations;

namespace MovieSearch.Api.Dtos;

public class CreateUserDto
{
    [Required]
    [StringLength(100, MinimumLength = 3)]
    public required string Username { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(254)]
    public required string Email { get; set; }

    [Required]
    [StringLength(128, MinimumLength = 8)]
    public required string Password { get; set; }
}