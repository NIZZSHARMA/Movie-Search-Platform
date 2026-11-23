using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("user_search_history", Schema = "framework")]
public class UserSearchHistory
{
    [Key]
    [Column("search_id")]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long SearchId { get; set; }

    [Column("user_id")]
    public long UserId { get; set; }

    [Column("query_text")]
    public string QueryText { get; set; } = null!;

    [Column("performed_at")]
    public DateTime PerformedAt { get; set; }
}