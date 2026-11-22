using System.ComponentModel.DataAnnotations;

namespace MovieSearch.Api.Dtos;

public class UpdateUserDto
{
    [Required]
    [StringLength(100, MinimumLength = 3)]
    public required string Username { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(254)]
    public required string Email { get; set; }

    [StringLength(128, MinimumLength = 8)]
    public string? Password { get; set; }
}