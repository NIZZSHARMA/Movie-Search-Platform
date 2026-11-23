using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("user_title_rating", Schema = "framework")]
public class UserTitleRating
{
    [Key]
    [Column("rating_id")]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long RatingId { get; set; }

    [Column("user_id")]
    public long UserId { get; set; }

    [Column("tconst")]
    public string Tconst { get; set; } = null!;

    [Column("rating")]
    public short Rating { get; set; }

    [Column("rated_at")]
    public DateTime RatedAt { get; set; }
}