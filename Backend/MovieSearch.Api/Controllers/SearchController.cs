using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Dtos;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/search")]
public class SearchController : ControllerBase
{
    private readonly ISearchRepository _search;
    private readonly IUserRepository _users;

    public SearchController(
        ISearchRepository search,
        IUserRepository users)
    {
        _search = search;
        _users = users;
    }

    [HttpGet("titles")]
    public Task<IActionResult> SearchTitles(
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        return ExecuteSearchAsync(
            "titles", query, null, null, null, null,
            page, pageSize, cancellationToken);
    }

    [HttpGet("persons")]
    public Task<IActionResult> SearchPersons(
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        return ExecuteSearchAsync(
            "persons", query, null, null, null, null,
            page, pageSize, cancellationToken);
    }

    [HttpGet("structured")]
    public Task<IActionResult> SearchStructured(
        [FromQuery] string? title,
        [FromQuery] string? plot,
        [FromQuery] string? character,
        [FromQuery] string? personName,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        return ExecuteSearchAsync(
            "structured", null, title, plot, character, personName,
            page, pageSize, cancellationToken);
    }

    private async Task<IActionResult> ExecuteSearchAsync(
        string kind,
        string? query,
        string? title,
        string? plot,
        string? character,
        string? personName,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        if (!long.TryParse(
            User.FindFirst("sub")?.Value,
            NumberStyles.None,
            CultureInfo.InvariantCulture,
            out var userId))
        {
            return Unauthorized();
        }

        query = query?.Trim() ?? "";
        title = title?.Trim() ?? "";
        plot = plot?.Trim() ?? "";
        character = character?.Trim() ?? "";
        personName = personName?.Trim() ?? "";

        if (kind != "structured" && query.Length == 0)
        {
            return BadRequest(new
            {
                message = "Search text is required."
            });
        }

        if (kind == "structured"
            && title.Length == 0
            && plot.Length == 0
            && character.Length == 0
            && personName.Length == 0)
        {
            return BadRequest(new
            {
                message = "At least one search field is required."
            });
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
            return Unauthorized();
        }

        List<SearchResultRow> rows;

        if (kind == "persons")
        {
            rows = await _search.SearchPersonsAsync(
                userId, query, (int)offset,
                pageSize, cancellationToken);
        }
        else if (kind == "structured")
        {
            rows = await _search.SearchStructuredAsync(
                userId, title, plot, character, personName,
                (int)offset, pageSize, cancellationToken);
        }
        else
        {
            rows = await _search.SearchTitlesAsync(
                userId, query, (int)offset,
                pageSize, cancellationToken);
        }

        var totalCount = rows.FirstOrDefault()?.TotalCount ?? 0;
        var totalPages = (long)Math.Ceiling(
            totalCount / (double)pageSize);

        // An empty page still contains a count-only database row.
        var items = rows
            .Where(row => row.Id is not null)
            .Select(row => ToResponse(kind, row))
            .ToList();

        string? PageUrl(int targetPage)
        {
            if (kind == "structured")
            {
                return Url.Action(
                    nameof(SearchStructured),
                    new
                    {
                        title,
                        plot,
                        character,
                        personName,
                        page = targetPage,
                        pageSize
                    });
            }

            return Url.Action(
                kind == "persons"
                    ? nameof(SearchPersons)
                    : nameof(SearchTitles),
                new { query, page = targetPage, pageSize });
        }

        return Ok(new
        {
            url = PageUrl(page),
            page,
            pageSize,
            totalCount,
            totalPages,
            previous = page > 1 && page - 1 <= totalPages
                ? PageUrl(page - 1)
                : null,
            next = page < totalPages
                ? PageUrl(page + 1)
                : null,
            items
        });
    }

    private object ToResponse(string kind, SearchResultRow row)
    {
        if (kind == "persons")
        {
            return new
            {
                url = Url.Action(
                    nameof(PersonsController.GetById),
                    "Persons",
                    new { nconst = row.Id }),
                nconst = row.Id,
                primaryName = row.Name
            };
        }

        return new
        {
            url = Url.Action(
                nameof(TitlesController.GetById),
                "Titles",
                new { tconst = row.Id }),
            tconst = row.Id,
            primaryTitle = row.Name,
            plot = row.Plot
        };
    }
}