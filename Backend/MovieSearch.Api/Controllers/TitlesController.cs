using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Dtos;
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

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        const int defaultPageSize = 10;
        const int maximumPageSize = 100;

        if (page < 1)
        {
            return BadRequest(new
            {
                message = "Page must be at least 1."
            });
        }

        if (pageSize < 1 || pageSize > maximumPageSize)
        {
            pageSize = defaultPageSize;
        }

        var offset = ((long)page - 1) * pageSize;

        if (offset > int.MaxValue)
        {
            return BadRequest(new
            {
                message = "Requested page is too large."
            });
        }

        var totalCount = await _repository.CountAsync(
            cancellationToken);

        var totalPages = (int)Math.Ceiling(
            totalCount / (double)pageSize);

        var titles = await _repository.GetPageAsync(
            (int)offset, pageSize, cancellationToken);

        var items = titles.Select(title => new TitleSummaryDto
        {
            Url = Url.Action(
                nameof(GetById),
                new { tconst = title.Tconst }),
            Tconst = title.Tconst,
            PrimaryTitle = title.PrimaryTitle,
            TitleType = title.TitleType,
            StartYear = title.StartYear
        });

        return Ok(new
        {
            url = Url.Action(
                nameof(GetAll),
                new { page, pageSize }),
            page,
            pageSize,
            totalCount,
            totalPages,
            previous = page > 1 && page - 1 <= totalPages
                ? Url.Action(
                    nameof(GetAll),
                    new { page = page - 1, pageSize })
                : null,
            next = page < totalPages
                ? Url.Action(
                    nameof(GetAll),
                    new { page = page + 1, pageSize })
                : null,
            items
        });
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
        var extra = await _repository.GetOmdbExtraAsync(
         title.Tconst, cancellationToken);

        return Ok(new TitleDetailsDto
        {
            Url = Url.Action(
                nameof(GetById),
                new { tconst = title.Tconst }),
            Tconst = title.Tconst,
            TitleType = title.TitleType,
            PrimaryTitle = title.PrimaryTitle,
            OriginalTitle = title.OriginalTitle,
            IsAdult = title.IsAdult,
            StartYear = title.StartYear,
            EndYear = title.EndYear,
            RuntimeMinutes = title.RuntimeMinutes,
            Plot = extra?.Plot,
            Poster = extra?.Poster
        });
    }
}