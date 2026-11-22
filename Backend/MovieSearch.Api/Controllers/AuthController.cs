using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Dtos;
using MovieSearch.Api.Models;
using MovieSearch.Api.Repositories;

namespace MovieSearch.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IUserRepository _repository;
    private readonly IPasswordHasher<AppUser> _passwordHasher;

    public AuthController(
        IUserRepository repository,
        IPasswordHasher<AppUser> passwordHasher)
    {
        _repository = repository;
        _passwordHasher = passwordHasher;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginDto request,
        CancellationToken cancellationToken)
    {
        var username = request.Username.Trim();

        var user = await _repository.GetByUsernameAsync(
            username, cancellationToken);

        if (user is null)
        {
            return Unauthorized(new
            {
                message = "Invalid username or password."
            });
        }

        var result = _passwordHasher.VerifyHashedPassword(
            user,
            user.PasswordHash,
            request.Password);

        if (result == PasswordVerificationResult.Failed)
        {
            return Unauthorized(new
            {
                message = "Invalid username or password."
            });
        }

        return Ok(new UserDto
        {
            Url = Url.Action(
                nameof(UsersController.GetById),
                "Users",
                new { userId = user.UserId }),
            UserId = user.UserId,
            Username = user.Username,
            Email = user.Email
        });
    }
}