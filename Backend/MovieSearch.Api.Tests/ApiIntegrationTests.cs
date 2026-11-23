using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace MovieSearch.Api.Tests;

public class ApiIntegrationTests
{
    [Theory]
    [Trait("Category", "Integration")]
    [InlineData("titles", "tt0052520", "tconst")]
    [InlineData("persons", "nm0785245", "nconst")]
    public async Task Bookmarks_support_add_read_list_and_delete(
        string resource,
        string id,
        string idProperty)
    {
        await WithUserAsync(async (client, userId) =>
        {
            var collection =
                $"/api/users/{userId}/bookmarks/{resource}";

            var itemUrl = $"{collection}/{id}";

            using var added = await client.PutAsync(itemUrl, null);
            await ExpectAsync(added, HttpStatusCode.Created);

            Assert.NotNull(added.Headers.Location);

            using var detail = await GetJsonAsync(client, itemUrl);
            Assert.Equal(
                id,
                detail.RootElement.GetProperty(idProperty).GetString());

            Assert.False(string.IsNullOrWhiteSpace(
                detail.RootElement.GetProperty("url").GetString()));

            using var duplicate = await client.PutAsync(itemUrl, null);
            await ExpectAsync(duplicate, HttpStatusCode.NoContent);

            using var list = await GetJsonAsync(
                client, $"{collection}?page=1&pageSize=1");

            Assert.Equal(
                1, list.RootElement.GetProperty("totalCount").GetInt32());

            Assert.Equal(
                1, list.RootElement.GetProperty("items").GetArrayLength());

            using var invalidPage = await client.GetAsync(
                $"{collection}?page=0");

            await ExpectAsync(
                invalidPage, HttpStatusCode.BadRequest);

            using var defaultSize = await GetJsonAsync(
                client, $"{collection}?pageSize=101");

            Assert.Equal(
                10,
                defaultSize.RootElement.GetProperty("pageSize").GetInt32());

            using var removed = await client.DeleteAsync(itemUrl);
            await ExpectAsync(removed, HttpStatusCode.NoContent);

            using var missing = await client.GetAsync(itemUrl);
            await ExpectAsync(missing, HttpStatusCode.NotFound);

            using var emptyList = await GetJsonAsync(client, collection);

            Assert.Equal(
                0,
                emptyList.RootElement.GetProperty("totalCount").GetInt32());
        });
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task Ratings_support_validation_update_and_delete()
    {
        await WithUserAsync(async (client, userId) =>
        {
            var collection = $"/api/users/{userId}/ratings";
            var itemUrl = $"{collection}/tt0052520";

            using var invalid = await client.PutAsJsonAsync(
                itemUrl, new { rating = 11 });

            await ExpectAsync(invalid, HttpStatusCode.BadRequest);

            using var missingRating = await client.PutAsJsonAsync(
                itemUrl, new { });

            await ExpectAsync(
                missingRating, HttpStatusCode.BadRequest);

            using var added = await client.PutAsJsonAsync(
                itemUrl, new { rating = 8 });

            await ExpectAsync(added, HttpStatusCode.OK);

            using var detail = await GetJsonAsync(client, itemUrl);

            Assert.Equal(
                8, detail.RootElement.GetProperty("rating").GetInt32());

            using var updated = await client.PutAsJsonAsync(
                itemUrl, new { rating = 9 });

            await ExpectAsync(updated, HttpStatusCode.OK);

            using var updatedDetail = await GetJsonAsync(client, itemUrl);

            Assert.Equal(
                9,
                updatedDetail.RootElement.GetProperty("rating").GetInt32());

            using var list = await GetJsonAsync(client, collection);

            // Updating a rating must not create a second current rating.
            Assert.Equal(
                1, list.RootElement.GetProperty("totalCount").GetInt32());

            using var removed = await client.DeleteAsync(itemUrl);
            await ExpectAsync(removed, HttpStatusCode.NoContent);

            using var missing = await client.GetAsync(itemUrl);
            await ExpectAsync(missing, HttpStatusCode.NotFound);
        });
    }

    [Theory]
    [Trait("Category", "Integration")]
    [InlineData("titles?query=twilight", "tconst")]
    [InlineData("persons?query=serling", "nconst")]
    [InlineData(
        "structured?title=twilight&personName=serling", "tconst")]
    public async Task Search_returns_pages_and_records_one_history_per_call(
        string search,
        string idProperty)
    {
        await WithUserAsync(async (client, userId) =>
        {
            var historyUrl = $"/api/users/{userId}/search-history";

            using var first = await GetJsonAsync(
                client, $"/api/search/{search}&page=1&pageSize=1");

            var total = first.RootElement
                .GetProperty("totalCount").GetInt64();

            Assert.True(total > 0);

            var items = first.RootElement.GetProperty("items");
            Assert.Equal(1, items.GetArrayLength());
            Assert.False(string.IsNullOrWhiteSpace(
                items[0].GetProperty(idProperty).GetString()));

            using var history = await GetJsonAsync(client, historyUrl);

            Assert.Equal(
                1,
                history.RootElement.GetProperty("totalCount").GetInt32());

            // A page beyond the results must preserve the total count.
            using var beyond = await GetJsonAsync(
                client,
                $"/api/search/{search}&page=2147483647&pageSize=1");

            Assert.Equal(
                total,
                beyond.RootElement.GetProperty("totalCount").GetInt64());

            Assert.Equal(
                0,
                beyond.RootElement.GetProperty("items").GetArrayLength());

            using var secondHistory = await GetJsonAsync(
                client, historyUrl);

            Assert.Equal(
                2,
                secondHistory.RootElement
                    .GetProperty("totalCount").GetInt32());

            var entryUrl = secondHistory.RootElement
                .GetProperty("items")[0]
                .GetProperty("url").GetString();

            Assert.False(string.IsNullOrWhiteSpace(entryUrl));

            using var entry = await GetJsonAsync(client, entryUrl!);

            Assert.False(string.IsNullOrWhiteSpace(
                entry.RootElement.GetProperty("queryText").GetString()));

            using var deleted = await client.DeleteAsync(entryUrl);
            await ExpectAsync(deleted, HttpStatusCode.NoContent);

            using var missing = await client.GetAsync(entryUrl);
            await ExpectAsync(missing, HttpStatusCode.NotFound);

            using var cleared = await client.DeleteAsync(historyUrl);
            await ExpectAsync(cleared, HttpStatusCode.NoContent);

            using var empty = await GetJsonAsync(client, historyUrl);

            Assert.Equal(
                0, empty.RootElement.GetProperty("totalCount").GetInt32());
        });
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task Jwt_protects_private_routes_and_allows_own_account()
    {
        await WithUserAsync(async (client, userId) =>
        {
            using var anonymous = CreateClient();

            var privatePaths = new[]
            {
                $"/api/users/{userId}",
                $"/api/users/{userId}/bookmarks/titles",
                $"/api/users/{userId}/bookmarks/persons",
                $"/api/users/{userId}/ratings",
                $"/api/users/{userId}/search-history",
                "/api/search/titles?query=twilight"
            };

            foreach (var path in privatePaths)
            {
                using var response = await anonymous.GetAsync(path);
                await ExpectAsync(response, HttpStatusCode.Unauthorized);
            }

            using var own = await client.GetAsync(
                $"/api/users/{userId}");

            await ExpectAsync(own, HttpStatusCode.OK);

            // This request only reads another ID; it does not modify it.
            var otherId = userId == 1 ? 2 : 1;

            using var other = await client.GetAsync(
                $"/api/users/{otherId}");

            await ExpectAsync(other, HttpStatusCode.Forbidden);
        });
    }

    private static HttpClient CreateClient()
    {
        return new HttpClient
        {
            BaseAddress = new Uri(
                Environment.GetEnvironmentVariable("MOVIE_API_TEST_URL")
                ?? "http://localhost:5053"),
            Timeout = TimeSpan.FromMinutes(3)
        };
    }

    private static async Task WithUserAsync(
        Func<HttpClient, long, Task> test)
    {
        using var client = CreateClient();

        var username = $"integration_{Guid.NewGuid():N}";
        const string password = "IntegrationTest!2026";

        using var created = await client.PostAsJsonAsync(
            "/api/users",
            new
            {
                username,
                email = $"{username}@example.com",
                password
            });

        await ExpectAsync(created, HttpStatusCode.Created);

        using var user = JsonDocument.Parse(
            await created.Content.ReadAsStringAsync());

        var userId = user.RootElement.GetProperty("userId").GetInt64();

        using var loginResponse = await client.PostAsJsonAsync(
            "/api/auth/login",
            new { username, password });

        await ExpectAsync(loginResponse, HttpStatusCode.OK);

        using var login = JsonDocument.Parse(
            await loginResponse.Content.ReadAsStringAsync());

        var token = login.RootElement
            .GetProperty("accessToken").GetString();

        Assert.False(string.IsNullOrWhiteSpace(token));

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        try
        {
            await test(client, userId);
        }
        finally
        {
            using var cleanup = await client.DeleteAsync(
                $"/api/users/{userId}");

            await ExpectAsync(cleanup, HttpStatusCode.NoContent);
        }
    }

    private static async Task<JsonDocument> GetJsonAsync(
        HttpClient client,
        string path)
    {
        using var response = await client.GetAsync(path);

        await ExpectAsync(response, HttpStatusCode.OK);

        return JsonDocument.Parse(
            await response.Content.ReadAsStringAsync());
    }

    private static async Task ExpectAsync(
        HttpResponseMessage response,
        HttpStatusCode expected)
    {
        // Avoid including login tokens in test failure output.
        if (response.StatusCode != expected)
        {
            var body = await response.Content.ReadAsStringAsync();

            Assert.Fail(
                $"{response.RequestMessage?.Method} " +
                $"{response.RequestMessage?.RequestUri?.AbsolutePath}: " +
                $"expected {(int)expected}, " +
                $"received {(int)response.StatusCode}. " +
                $"Response: {body}");
        }
    }
}