using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace MovieSearch.Api.Models;

[Table("user_bookmark_person", Schema = "framework")]
[PrimaryKey(nameof(UserId), nameof(Nconst))]
public class UserBookmarkPerson
{
    [Column("user_id")]
    public long UserId { get; set; }

    [Column("nconst")]
    public string Nconst { get; set; } = null!;
}