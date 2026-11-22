using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("credit", Schema = "movie")]
public class Credit
{
    [Column("tconst")]
    public string Tconst { get; set; } = null!;

    [Column("ordering")]
    public int Ordering { get; set; }

    [Column("nconst")]
    public string Nconst { get; set; } = null!;

    [Column("category")]
    public string? Category { get; set; }

    [Column("job")]
    public string? Job { get; set; }

    [Column("characters")]
    public string? Characters { get; set; }
}