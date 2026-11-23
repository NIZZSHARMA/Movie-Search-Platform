using System.Runtime.CompilerServices;
using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Dtos;

namespace MovieSearch.Api.Repositories;

public class SearchRepository : ISearchRepository
{
    private readonly MovieDbContext _context;

    public SearchRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<List<SearchResultRow>> SearchTitlesAsync(
        long userId,
        string query,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        FormattableString source = $"""
            SELECT
                tconst AS "Id",
                primary_title AS "Name",
                plot AS "Plot"
            FROM movie.string_search({userId}, {query})
            """;

        return ReadPageAsync(
            source, offset, pageSize, cancellationToken);
    }

    public Task<List<SearchResultRow>> SearchPersonsAsync(
        long userId,
        string query,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        FormattableString source = $"""
            SELECT
                nconst AS "Id",
                primary_name AS "Name",
                NULL::text AS "Plot"
            FROM movie.name_search({userId}, {query})
            """;

        return ReadPageAsync(
            source, offset, pageSize, cancellationToken);
    }

    public Task<List<SearchResultRow>> SearchStructuredAsync(
        long userId,
        string title,
        string plot,
        string character,
        string personName,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        FormattableString source = $"""
            SELECT
                tconst AS "Id",
                primary_title AS "Name",
                NULL::text AS "Plot"
            FROM movie.structured_string_search(
                {userId}, {title}, {plot}, {character}, {personName})
            """;

        return ReadPageAsync(
            source, offset, pageSize, cancellationToken);
    }

    private Task<List<SearchResultRow>> ReadPageAsync(
        FormattableString source,
        int offset,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var arguments = source.GetArguments().ToList();
        var offsetIndex = arguments.Count;
        arguments.Add(offset);

        var sizeIndex = arguments.Count;
        arguments.Add(pageSize);

        var sql = """
            WITH results AS MATERIALIZED (
            """ + source.Format + """
            
            ),
            page AS (
                SELECT *
                FROM results
                ORDER BY "Id"
                OFFSET {
            """ + offsetIndex + "} LIMIT {" + sizeIndex + """
            }
            )
            SELECT
                page."Id",
                page."Name",
                page."Plot",
                totals."TotalCount"
            FROM (
                SELECT COUNT(*) AS "TotalCount"
                FROM results
            ) AS totals
            LEFT JOIN page ON TRUE
            ORDER BY page."Id"
            """;

        var command = FormattableStringFactory.Create(
            sql, arguments.ToArray());

        return _context.Database
            .SqlQuery<SearchResultRow>(command)
            .ToListAsync(cancellationToken);
    }
}