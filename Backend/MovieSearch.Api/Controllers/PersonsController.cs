using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Route("api/persons")]
public class PersonsController : ControllerBase
{
    private readonly IPersonRepository _repository;

    public PersonsController(IPersonRepository repository)
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

        var persons = await _repository.GetPageAsync(
            (int)offset, pageSize, cancellationToken);

        var items = persons.Select(person => new
        {
            url = Url.Action(
                nameof(GetById),
                new { nconst = person.Nconst }),
            person.Nconst,
            person.PrimaryName,
            person.BirthYear,
            person.DeathYear
        });

        return Ok(new
        {
            url = Url.Action(nameof(GetAll), new { page, pageSize }),
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

    [HttpGet("{nconst}")]
    public async Task<IActionResult> GetById(
        string nconst,
        CancellationToken cancellationToken)
    {
        var person = await _repository.GetByIdAsync(
            nconst, cancellationToken);

        if (person is null)
        {
            return NotFound();
        }

        return Ok(new
        {
            url = Url.Action(
                nameof(GetById),
                new { nconst = person.Nconst }),
            person.Nconst,
            person.PrimaryName,
            person.BirthYear,
            person.DeathYear
        });
    }
}