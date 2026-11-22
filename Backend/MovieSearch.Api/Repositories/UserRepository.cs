using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Data;
using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public class UserRepository : IUserRepository
{
    private readonly MovieDbContext _context;

    public UserRepository(MovieDbContext context)
    {
        _context = context;
    }

    public Task<AppUser?> GetByIdAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        return _context.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.UserId == userId,
                cancellationToken);
    }

    public Task<AppUser?> GetByUsernameAsync(
        string username,
        CancellationToken cancellationToken = default)
    {
        return _context.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.Username == username,
                cancellationToken);
    }

    public Task<bool> UsernameExistsAsync(
        string username,
        long? excludedUserId = null,
        CancellationToken cancellationToken = default)
    {
        return _context.Users.AnyAsync(
            user => user.Username == username
                && (!excludedUserId.HasValue
                    || user.UserId != excludedUserId.Value),
            cancellationToken);
    }

    public Task<bool> EmailExistsAsync(
        string email,
        long? excludedUserId = null,
        CancellationToken cancellationToken = default)
    {
        return _context.Users.AnyAsync(
            user => user.Email == email
                && (!excludedUserId.HasValue
                    || user.UserId != excludedUserId.Value),
            cancellationToken);
    }

    public async Task<AppUser> CreateAsync(
        AppUser user,
        CancellationToken cancellationToken = default)
    {
        _context.Users.Add(user);

        await _context.SaveChangesAsync(cancellationToken);

        return user;
    }

    public async Task<bool> UpdateAsync(
        AppUser user,
        CancellationToken cancellationToken = default)
    {
        var existingUser = await _context.Users
            .SingleOrDefaultAsync(
                item => item.UserId == user.UserId,
                cancellationToken);

        if (existingUser is null)
        {
            return false;
        }

        existingUser.Username = user.Username;
        existingUser.Email = user.Email;
        existingUser.PasswordHash = user.PasswordHash;

        await _context.SaveChangesAsync(cancellationToken);

        return true;
    }

    public async Task<bool> DeleteAsync(
        long userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .SingleOrDefaultAsync(
                item => item.UserId == userId,
                cancellationToken);

        if (user is null)
        {
            return false;
        }

        _context.Users.Remove(user);

        await _context.SaveChangesAsync(cancellationToken);

        return true;
    }
}