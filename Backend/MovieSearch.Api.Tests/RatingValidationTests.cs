using System.ComponentModel.DataAnnotations;
using MovieSearch.Api.Dtos;

namespace MovieSearch.Api.Tests;

public class RatingValidationTests
{
    [Theory]
    [InlineData(null, false)]
    [InlineData(-1, false)]
    [InlineData(0, false)]
    [InlineData(1, true)]
    [InlineData(5, true)]
    [InlineData(10, true)]
    [InlineData(11, false)]
    public void Rating_must_be_present_and_between_one_and_ten(
        int? rating,
        bool expectedValid)
    {
        var request = new SetRatingDto
        {
            Rating = rating
        };

        var errors = new List<ValidationResult>();

        var valid = Validator.TryValidateObject(
            request,
            new ValidationContext(request),
            errors,
            validateAllProperties: true);

        Assert.Equal(expectedValid, valid);

        if (!expectedValid)
        {
            Assert.Contains(
                errors,
                error => error.MemberNames.Contains(
                    nameof(SetRatingDto.Rating)));
        }
    }
}