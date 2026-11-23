using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Models;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/users/{userId:long}/bookmarks/titles")]
public class TitleBookmarksController : ControllerBase
{
    private readonly ITitleBookmarkRepository _bookmarks;
    private readonly ITitleRepository _titles;
    private readonly IUserRepository _users;

    public TitleBookmarksController(
        ITitleBookmarkRepository bookmarks,
        ITitleRepository titles,
        IUserRepository users)
    {
        _bookmarks = bookmarks;
        _titles = titles;
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

        var titles = await _bookmarks.GetPageAsync(
            userId, (int)offset, pageSize, cancellationToken);

        var items = titles
            .Select(title => ToResponse(userId, title))
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

    [HttpGet("{tconst}")]
    public async Task<IActionResult> GetById(
        long userId,
        string tconst,
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
            userId, tconst, cancellationToken))
        {
            return NotFound();
        }

        var title = await _titles.GetByIdAsync(
            tconst, cancellationToken);

        if (title is null)
        {
            return NotFound();
        }

        return Ok(ToResponse(userId, title));
    }

    [HttpPut("{tconst}")]
    public async Task<IActionResult> Add(
        long userId,
        string tconst,
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

        var title = await _titles.GetByIdAsync(
            tconst, cancellationToken);

        if (title is null)
        {
            return NotFound(new
            {
                message = "Title was not found."
            });
        }

        var added = await _bookmarks.AddAsync(
            userId, tconst, cancellationToken);

        if (!added)
        {
            return NoContent();
        }

        return CreatedAtAction(
            nameof(GetById),
            new { userId, tconst },
            ToResponse(userId, title));
    }

    [HttpDelete("{tconst}")]
    public async Task<IActionResult> Delete(
        long userId,
        string tconst,
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
            userId, tconst, cancellationToken);

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

    private object ToResponse(long userId, Title title)
    {
        return new
        {
            url = Url.Action(
                nameof(GetById),
                new { userId, tconst = title.Tconst }),
            titleUrl = Url.Action(
                nameof(TitlesController.GetById),
                "Titles",
                new { tconst = title.Tconst }),
            tconst = title.Tconst,
            primaryTitle = title.PrimaryTitle,
            titleType = title.TitleType,
            startYear = title.StartYear
        };
    }
}