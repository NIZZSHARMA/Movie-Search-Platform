using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("app_user", Schema = "framework")]
public class AppUser
{
    [Key]
    [Column("user_id")]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long UserId { get; set; }

    [Column("username")]
    public string Username { get; set; } = null!;

    [Column("email")]
    public string Email { get; set; } = null!;

    [Column("password_hash")]
    public string PasswordHash { get; set; } = null!;
}