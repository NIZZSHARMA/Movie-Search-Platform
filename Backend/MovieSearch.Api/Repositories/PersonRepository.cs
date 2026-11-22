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
}