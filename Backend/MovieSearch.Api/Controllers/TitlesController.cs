using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Route("api/titles")]
public class TitlesController : ControllerBase
{
    private readonly ITitleRepository _repository;

    public TitlesController(ITitleRepository repository)
    {
        _repository = repository;
    }

    [HttpGet("{tconst}")]
    public async Task<IActionResult> GetById(
        string tconst,
        CancellationToken cancellationToken)
    {
        var title = await _repository.GetByIdAsync(
            tconst, cancellationToken);

        if (title is null)
        {
            return NotFound();
        }

        return Ok(new
        {
            url = Url.Action(
                nameof(GetById),
                new { tconst = title.Tconst }),
            title.Tconst,
            title.TitleType,
            title.PrimaryTitle,
            title.OriginalTitle,
            title.IsAdult,
            title.StartYear,
            title.EndYear,
            title.RuntimeMinutes
        });
    }
}