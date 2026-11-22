using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public class PersonRepository : IPersonRepository
{
    private readonly MovieDbContext _context;

    public PersonRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<Person?> GetByIdAsync(
        string nconst,
        CancellationToken cancellationToken = default)
    {
        return _context.Persons
            .AsNoTracking()
            .SingleOrDefaultAsync(
                person => person.Nconst == nconst,
                cancellationToken);
    }

    public Task<int> CountAsync(
        CancellationToken cancellationToken = default)
    {
        return _context.Persons.CountAsync(cancellationToken);
    }

    public Task<List<Person>> GetPageAsync(
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return _context.Persons
            .AsNoTracking()
            .OrderBy(person => person.Nconst)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public Task<int> CountTitlesAsync(
        string nconst,
        CancellationToken cancellationToken = default)
    {
        return _context.Titles
            .Where(title => _context.Credits.Any(
                credit => credit.Tconst == title.Tconst
                    && credit.Nconst == nconst))
            .CountAsync(cancellationToken);
    }

    public Task<List<Title>> GetTitlesPageAsync(
        string nconst,
        int offset,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        return _context.Titles
            .AsNoTracking()
            .Where(title => _context.Credits.Any(
                credit => credit.Tconst == title.Tconst
                    && credit.Nconst == nconst))
            .OrderBy(title => title.Tconst)
            .Skip(offset)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }
}