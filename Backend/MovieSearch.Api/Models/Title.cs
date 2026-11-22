using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("title", Schema = "movie")]
public class Title
{
    [Key]
    [Column("tconst")]
    public string Tconst { get; set; } = null!;

    [Column("title_type")]
    public string? TitleType { get; set; }

    [Column("primary_title")]
    public string? PrimaryTitle { get; set; }

    [Column("original_title")]
    public string? OriginalTitle { get; set; }

    [Column("is_adult")]
    public bool? IsAdult { get; set; }

    [Column("start_year")]
    public int? StartYear { get; set; }

    [Column("end_year")]
    public int? EndYear { get; set; }

    [Column("runtime_minutes")]
    public int? RuntimeMinutes { get; set; }

    [Column("base_average_rating", TypeName = "numeric(3,1)")]
    public decimal? BaseAverageRating { get; set; }

    [Column("base_num_votes")]
    public int? BaseNumVotes { get; set; }
}