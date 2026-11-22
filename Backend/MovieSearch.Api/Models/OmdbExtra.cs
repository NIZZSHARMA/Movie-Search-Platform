using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("omdb_extra", Schema = "movie")]
public class OmdbExtra
{
    [Key]
    [Column("tconst")]
    public string Tconst { get; set; } = null!;

    [Column("plot")]
    public string? Plot { get; set; }

    [Column("poster")]
    public string? Poster { get; set; }
}