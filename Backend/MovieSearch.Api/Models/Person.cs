using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MovieSearch.Api.Models;

[Table("person", Schema = "movie")]
public class Person
{
    [Key]
    [Column("nconst")]
    public string Nconst { get; set; } = null!;

    [Column("primary_name")]
    public string? PrimaryName { get; set; }

    [Column("birth_year")]
    public int? BirthYear { get; set; }

    [Column("death_year")]
    public int? DeathYear { get; set; }
}