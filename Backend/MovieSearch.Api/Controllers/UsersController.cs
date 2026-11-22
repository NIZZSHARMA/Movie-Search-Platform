using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MovieSearch.Api.Dtos;
using MovieSearch.Api.Models;
using MovieSearch.Api.Repositories;
using Npgsql;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly IUserRepository _repository;
    private readonly IPasswordHasher<AppUser> _passwordHasher;

    public UsersController(
        IUserRepository repository,
        IPasswordHasher<AppUser> passwordHasher)
    {
        _repository = repository;
        _passwordHasher = passwordHasher;
    }

    [HttpGet("{userId:long}")]
    public async Task<IActionResult> GetById(
        long userId,
        CancellationToken cancellationToken)
    {
        var user = await _repository.GetByIdAsync(
            userId, cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        return Ok(ToDto(user));
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateUserDto request,
        CancellationToken cancellationToken)
    {
        var username = request.Username.Trim();
        var email = request.Email.Trim();

        if (username.Length < 3)
        {
            return BadRequest(new
            {
                message = "Username must contain at least 3 characters."
            });
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new
            {
                message = "Password must not be blank."
            });
        }

        if (await _repository.UsernameExistsAsync(
            username, cancellationToken: cancellationToken))
        {
            return Conflict(new
            {
                message = "Username is already in use."
            });
        }

        if (await _repository.EmailExistsAsync(
            email, cancellationToken: cancellationToken))
        {
            return Conflict(new
            {
                message = "Email is already in use."
            });
        }

        var user = new AppUser
        {
            Username = username,
            Email = email
        };

        user.PasswordHash = _passwordHasher.HashPassword(
            user, request.Password);

        try
        {
            await _repository.CreateAsync(
                user, cancellationToken);
        }
        catch (DbUpdateException exception)
            when (exception.InnerException is PostgresException
            {
                SqlState: PostgresErrorCodes.UniqueViolation
            })
        {
            return Conflict(new
            {
                message = "Username or email is already in use."
            });
        }

        return CreatedAtAction(
            nameof(GetById),
            new { userId = user.UserId },
            ToDto(user));
    }

    [HttpPut("{userId:long}")]
    public async Task<IActionResult> Update(
        long userId,
        [FromBody] UpdateUserDto request,
        CancellationToken cancellationToken)
    {
        var user = await _repository.GetByIdAsync(
            userId, cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        var username = request.Username.Trim();
        var email = request.Email.Trim();

        if (username.Length < 3)
        {
            return BadRequest(new
            {
                message = "Username must contain at least 3 characters."
            });
        }

        if (request.Password is not null
            && string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new
            {
                message = "Password must not be blank."
            });
        }

        if (await _repository.UsernameExistsAsync(
            username,
            excludedUserId: userId,
            cancellationToken: cancellationToken))
        {
            return Conflict(new
            {
                message = "Username is already in use."
            });
        }

        if (await _repository.EmailExistsAsync(
            email,
            excludedUserId: userId,
            cancellationToken: cancellationToken))
        {
            return Conflict(new
            {
                message = "Email is already in use."
            });
        }

        user.Username = username;
        user.Email = email;

        if (request.Password is not null)
        {
            user.PasswordHash = _passwordHasher.HashPassword(
                user, request.Password);
        }

        try
        {
            var updated = await _repository.UpdateAsync(
                user, cancellationToken);

            if (!updated)
            {
                return NotFound();
            }
        }
        catch (DbUpdateException exception)
            when (exception.InnerException is PostgresException
            {
                SqlState: PostgresErrorCodes.UniqueViolation
            })
        {
            return Conflict(new
            {
                message = "Username or email is already in use."
            });
        }

        return Ok(ToDto(user));
    }

    private UserDto ToDto(AppUser user)
    {
        return new UserDto
        {
            Url = Url.Action(
                nameof(GetById),
                new { userId = user.UserId }),
            UserId = user.UserId,
            Username = user.Username,
            Email = user.Email
        };
    }
}