using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Models;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/users/{userId:long}/search-history")]
public class SearchHistoryController : ControllerBase
{
    private readonly ISearchHistoryRepository _history;
    private readonly IUserRepository _users;

    public SearchHistoryController(
        ISearchHistoryRepository history,
        IUserRepository users)
    {
        _history = history;
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

        var totalCount = await _history.CountAsync(
            userId, cancellationToken);

        var totalPages = (int)Math.Ceiling(
            totalCount / (double)pageSize);

        var history = await _history.GetPageAsync(
            userId, (int)offset, pageSize, cancellationToken);

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
            items = history.Select(ToResponse).ToList()
        });
    }

    [HttpGet("{searchId:long}")]
    public async Task<IActionResult> GetById(
        long userId,
        long searchId,
        CancellationToken cancellationToken)
    {
        if (!IsCurrentUser(userId))
        {
            return Forbid();
        }

        var item = await _history.GetByIdAsync(
            userId, searchId, cancellationToken);

        if (item is null)
        {
            return NotFound();
        }

        return Ok(ToResponse(item));
    }

    [HttpDelete("{searchId:long}")]
    public async Task<IActionResult> Delete(
        long userId,
        long searchId,
        CancellationToken cancellationToken)
    {
        if (!IsCurrentUser(userId))
        {
            return Forbid();
        }

        var deleted = await _history.DeleteAsync(
            userId, searchId, cancellationToken);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete]
    public async Task<IActionResult> Clear(
        long userId,
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

        await _history.ClearAsync(userId, cancellationToken);

        return NoContent();
    }

    private bool IsCurrentUser(long userId)
    {
        return long.TryParse(
                User.FindFirst("sub")?.Value,
                NumberStyles.None,
                CultureInfo.InvariantCulture,
                out var currentUserId)
            && currentUserId == userId;
    }

    private object ToResponse(UserSearchHistory item)
    {
        return new
        {
            url = Url.Action(
                nameof(GetById),
                new
                {
                    userId = item.UserId,
                    searchId = item.SearchId
                }),
            searchId = item.SearchId,
            queryText = item.QueryText,
            performedAt = item.PerformedAt
        };
    }
}