using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Models;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/users/{userId:long}/bookmarks/persons")]
public class PersonBookmarksController : ControllerBase
{
    private readonly IPersonBookmarkRepository _bookmarks;
    private readonly IPersonRepository _persons;
    private readonly IUserRepository _users;

    public PersonBookmarksController(
        IPersonBookmarkRepository bookmarks,
        IPersonRepository persons,
        IUserRepository users)
    {
        _bookmarks = bookmarks;
        _persons = persons;
        _users = users;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        long userId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        if (!IsCurrentUser(userId))
        {
            return Forbid();
        }

        if (page < 1)
        {
            return BadRequest(new
            {
                message = "Page must be at least 1."
            });
        }

        if (pageSize < 1 || pageSize > 100)
        {
            pageSize = 10;
        }

        var offset = ((long)page - 1) * pageSize;

        if (offset > int.MaxValue)
        {
            return BadRequest(new
            {
                message = "Requested page is too large."
            });
        }

        if (await _users.GetByIdAsync(
            userId, cancellationToken) is null)
        {
            return NotFound();
        }

        var totalCount = await _bookmarks.CountAsync(
            userId, cancellationToken);

        var totalPages = (int)Math.Ceiling(
            totalCount / (double)pageSize);

        var persons = await _bookmarks.GetPageAsync(
            userId, (int)offset, pageSize, cancellationToken);

        var items = persons
            .Select(person => ToResponse(userId, person))
            .ToList();

        return Ok(new
        {
            url = Url.Action(
                nameof(GetAll),
                new { userId, page, pageSize }),
            page,
            pageSize,
            totalCount,
            totalPages,
            previous = page > 1 && page - 1 <= totalPages
                ? Url.Action(
                    nameof(GetAll),
                    new { userId, page = page - 1, pageSize })
                : null,
            next = page < totalPages
                ? Url.Action(
                    nameof(GetAll),
                    new { userId, page = page + 1, pageSize })
                : null,
            items
        });
    }

    [HttpGet("{nconst}")]
    public async Task<IActionResult> GetById(
        long userId,
        string nconst,
        CancellationToken cancellationToken)
    {
        if (!IsCurrentUser(userId))
        {
            return Forbid();
        }

        if (await _users.GetByIdAsync(
            userId, cancellationToken) is null)
        {
            return NotFound();
        }

        if (!await _bookmarks.ExistsAsync(
            userId, nconst, cancellationToken))
        {
            return NotFound();
        }

        var person = await _persons.GetByIdAsync(
            nconst, cancellationToken);

        if (person is null)
        {
            return NotFound();
        }

        return Ok(ToResponse(userId, person));
    }

    [HttpPut("{nconst}")]
    public async Task<IActionResult> Add(
        long userId,
        string nconst,
        CancellationToken cancellationToken)
    {
        if (!IsCurrentUser(userId))
        {
            return Forbid();
        }

        if (await _users.GetByIdAsync(
            userId, cancellationToken) is null)
        {
            return NotFound();
        }

        var person = await _persons.GetByIdAsync(
            nconst, cancellationToken);

        if (person is null)
        {
            return NotFound(new
            {
                message = "Person was not found."
            });
        }

        var added = await _bookmarks.AddAsync(
            userId, nconst, cancellationToken);

        if (!added)
        {
            return NoContent();
        }

        return CreatedAtAction(
            nameof(GetById),
            new { userId, nconst },
            ToResponse(userId, person));
    }

    [HttpDelete("{nconst}")]
    public async Task<IActionResult> Delete(
        long userId,
        string nconst,
        CancellationToken cancellationToken)
    {
        if (!IsCurrentUser(userId))
        {
            return Forbid();
        }

        if (await _users.GetByIdAsync(
            userId, cancellationToken) is null)
        {
            return NotFound();
        }

        var deleted = await _bookmarks.DeleteAsync(
            userId, nconst, cancellationToken);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }

    private bool IsCurrentUser(long userId)
    {
        var subject = User.FindFirst("sub")?.Value;

        return long.TryParse(
                subject,
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out var currentUserId)
            && currentUserId == userId;
    }

    private object ToResponse(long userId, Person person)
    {
        return new
        {
            url = Url.Action(
                nameof(GetById),
                new { userId, nconst = person.Nconst }),
            personUrl = Url.Action(
                nameof(PersonsController.GetById),
                "Persons",
                new { nconst = person.Nconst }),
            nconst = person.Nconst,
            primaryName = person.PrimaryName,
            birthYear = person.BirthYear,
            deathYear = person.DeathYear
        };
    }
}