using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace MovieSearch.Api.Models;

[Keyless]
public class TitleRating
{
    [Column("tconst")]
    public string Tconst { get; set; } = null!;

    [Column("average_rating")]
    public decimal? AverageRating { get; set; }

    [Column("num_votes")]
    public long NumVotes { get; set; }
}