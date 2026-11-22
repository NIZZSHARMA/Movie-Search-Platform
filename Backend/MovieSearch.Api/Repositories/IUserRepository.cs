using MovieSearch.Api.Models;

namespace MovieSearch.Api.Repositories;

public interface IUserRepository
{
    Task<AppUser?> GetByIdAsync(
        long userId,
        CancellationToken cancellationToken = default);

    Task<AppUser?> GetByUsernameAsync(
        string username,
        CancellationToken cancellationToken = default);

    Task<bool> UsernameExistsAsync(
        string username,
        long? excludedUserId = null,
        CancellationToken cancellationToken = default);

    Task<bool> EmailExistsAsync(
        string email,
        long? excludedUserId = null,
        CancellationToken cancellationToken = default);

    Task<AppUser> CreateAsync(
        AppUser user,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateAsync(
        AppUser user,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(
        long userId,
        CancellationToken cancellationToken = default);
}