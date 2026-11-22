using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("title_genre", Schema = "movie")]
public class TitleGenre
{
    [Column("tconst")]
    public string Tconst { get; set; } = null!;

    [Column("genre")]
    public string Genre { get; set; } = null!;
}