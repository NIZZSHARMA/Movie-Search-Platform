using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Dtos;
using MovieSearch.Api.Models;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/users/{userId:long}/ratings")]
public class UserRatingsController : ControllerBase
{
    private readonly IUserRatingRepository _ratings;
    private readonly IUserRepository _users;
    private readonly ITitleRepository _titles;

    public UserRatingsController(
        IUserRatingRepository ratings,
        IUserRepository users,
        ITitleRepository titles)
    {
        _ratings = ratings;
        _users = users;
        _titles = titles;
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

        var totalCount = await _ratings.CountAsync(
            userId, cancellationToken);

        var totalPages = (int)Math.Ceiling(
            totalCount / (double)pageSize);

        var ratings = await _ratings.GetPageAsync(
            userId, (int)offset, pageSize, cancellationToken);

        var items = ratings.Select(ToResponse).ToList();

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
    public async Task<IActionResult> GetByTitle(
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

        var rating = await _ratings.GetByTitleAsync(
            userId, tconst, cancellationToken);

        if (rating is null)
        {
            return NotFound();
        }

        return Ok(ToResponse(rating));
    }

    [HttpPut("{tconst}")]
    public async Task<IActionResult> Set(
        long userId,
        string tconst,
        [FromBody] SetRatingDto request,
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

        if (await _titles.GetByIdAsync(
            tconst, cancellationToken) is null)
        {
            return NotFound(new
            {
                message = "Title was not found."
            });
        }

        var rating = await _ratings.SetAsync(
            userId,
            tconst,
            request.Rating!.Value,
            cancellationToken);

        return Ok(ToResponse(rating));
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

        var deleted = await _ratings.DeleteAsync(
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

    private object ToResponse(UserTitleRating rating)
    {
        return new
        {
            url = Url.Action(
                nameof(GetByTitle),
                new
                {
                    userId = rating.UserId,
                    tconst = rating.Tconst
                }),
            titleUrl = Url.Action(
                nameof(TitlesController.GetById),
                "Titles",
                new { tconst = rating.Tconst }),
            ratingId = rating.RatingId,
            tconst = rating.Tconst,
            rating = rating.Rating,
            ratedAt = rating.RatedAt
        };
    }
}