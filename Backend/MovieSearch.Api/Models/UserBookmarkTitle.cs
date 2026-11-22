using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace MovieSearch.Api.Models;

[Table("user_bookmark_title", Schema = "framework")]
[PrimaryKey(nameof(UserId), nameof(Tconst))]
public class UserBookmarkTitle
{
    [Column("user_id")]
    public long UserId { get; set; }

    [Column("tconst")]
    public string Tconst { get; set; } = null!;
}