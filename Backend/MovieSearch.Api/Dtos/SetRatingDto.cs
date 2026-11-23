using System.ComponentModel.DataAnnotations;

namespace MovieSearch.Api.Dtos;

public class SetRatingDto
{
    [Required]
    [Range(1, 10)]
    public int? Rating { get; set; }
}