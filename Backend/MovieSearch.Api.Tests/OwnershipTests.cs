using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MovieSearch.Api.Controllers;

namespace MovieSearch.Api.Tests;

public class OwnershipTests
{
    [Theory]
    [InlineData("users")]
    [InlineData("title-bookmarks")]
    [InlineData("person-bookmarks")]
    [InlineData("ratings")]
    [InlineData("search-history")]
    public async Task Reading_another_users_data_returns_forbidden(
        string resource)
    {
        var controller = CreateController(resource);

        SetIdentity(controller, "27");

        // Request user 28 while authenticated as user 27.
        var result = await ReadAsync(controller, 28);

        Assert.IsType<ForbidResult>(result);
    }

    [Theory]
    [InlineData("users")]
    [InlineData("title-bookmarks")]
    [InlineData("person-bookmarks")]
    [InlineData("ratings")]
    [InlineData("search-history")]
    public async Task Deleting_another_users_data_returns_forbidden(
        string resource)
    {
        var controller = CreateController(resource);

        SetIdentity(controller, "27");

        var result = await DeleteAsync(controller, 28);

        Assert.IsType<ForbidResult>(result);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("invalid")]
    public async Task Missing_or_invalid_subject_cannot_read_user(
        string? subject)
    {
        var controller = new UsersController(null!, null!);

        SetIdentity(controller, subject);

        var result = await controller.GetById(
            27, CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
    }

    private static ControllerBase CreateController(string resource)
    {
        // These tests must return before any repository is accessed.
        return resource switch
        {
            "users" =>
                new UsersController(null!, null!),

            "title-bookmarks" =>
                new TitleBookmarksController(null!, null!, null!),

            "person-bookmarks" =>
                new PersonBookmarksController(null!, null!, null!),

            "ratings" =>
                new UserRatingsController(null!, null!, null!),

            "search-history" =>
                new SearchHistoryController(null!, null!),

            _ => throw new ArgumentOutOfRangeException(nameof(resource))
        };
    }

    private static Task<IActionResult> ReadAsync(
        ControllerBase controller,
        long userId)
    {
        return controller switch
        {
            UsersController users =>
                users.GetById(userId, CancellationToken.None),

            TitleBookmarksController titles =>
                titles.GetById(
                    userId, "tt0052520", CancellationToken.None),

            PersonBookmarksController persons =>
                persons.GetById(
                    userId, "nm0785245", CancellationToken.None),

            UserRatingsController ratings =>
                ratings.GetByTitle(
                    userId, "tt0052520", CancellationToken.None),

            SearchHistoryController history =>
                history.GetById(
                    userId, 1, CancellationToken.None),

            _ => throw new ArgumentOutOfRangeException(nameof(controller))
        };
    }

    private static Task<IActionResult> DeleteAsync(
        ControllerBase controller,
        long userId)
    {
        return controller switch
        {
            UsersController users =>
                users.Delete(userId, CancellationToken.None),

            TitleBookmarksController titles =>
                titles.Delete(
                    userId, "tt0052520", CancellationToken.None),

            PersonBookmarksController persons =>
                persons.Delete(
                    userId, "nm0785245", CancellationToken.None),

            UserRatingsController ratings =>
                ratings.Delete(
                    userId, "tt0052520", CancellationToken.None),

            SearchHistoryController history =>
                history.Delete(
                    userId, 1, CancellationToken.None),

            _ => throw new ArgumentOutOfRangeException(nameof(controller))
        };
    }

    private static void SetIdentity(
        ControllerBase controller,
        string? subject)
    {
        var claims = new List<Claim>();

        if (subject is not null)
        {
            claims.Add(new Claim("sub", subject));
        }

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(
                    new ClaimsIdentity(claims, "Test"))
            }
        };
    }
}