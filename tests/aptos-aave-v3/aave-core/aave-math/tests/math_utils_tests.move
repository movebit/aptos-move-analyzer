#[test_only]
module aave_math::math_utils_tests {
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::{
        fast_forward_seconds,
        set_time_has_started_for_testing
    };
    use aave_config::error_config::{EOVERFLOW, EDIVISION_BY_ZERO};
    use aave_math::math_utils::{
        calculate_compounded_interest_now,
        calculate_linear_interest,
        get_half_percentage_factor_for_testing,
        get_percentage_factor,
        get_percentage_factor_for_testing,
        get_seconds_per_year_for_testing,
        get_u256_max_for_testing,
        percent_div,
        percent_mul,
        pow,
        u256_max
    };
    use aave_math::wad_ray_math::ray;

    const TEST_SUCCESS: u64 = 1;

    #[test]
    fun test_power() {
        assert!(pow(0, 0) == 1, TEST_SUCCESS);
        assert!(pow(1, 0) == 1, TEST_SUCCESS);
        assert!(pow(1, 1) == 1, TEST_SUCCESS);
        assert!(pow(10, 0) == 1, TEST_SUCCESS);
        assert!(pow(10, 1) == 10, TEST_SUCCESS);
        assert!(pow(10, 2) == 100, TEST_SUCCESS);
        assert!(pow(10, 3) == 1000, TEST_SUCCESS);
        assert!(pow(10, 4) == 10000, TEST_SUCCESS);
    }

    #[test]
    fun test_getters() {
        assert!(
            get_percentage_factor() == get_percentage_factor_for_testing(),
            TEST_SUCCESS
        );
        assert!(u256_max() == get_u256_max_for_testing(), TEST_SUCCESS);
    }

    #[test(creator = @0x1)]
    fun test_linear_interest(creator: &signer) {
        let one_hour_in_secs = 1 * 60 * 60;
        // start the timer
        set_time_has_started_for_testing(creator);
        // fast forward 1 hour
        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;
        // compute the interest rate
        let interest_rate_per_year = ray(); // ray per year
        let lin_interest_rate_increase =
            calculate_linear_interest(interest_rate_per_year, ts_one_hour_ago);
        // verification
        let percentage_increase =
            (interest_rate_per_year * (one_hour_in_secs as u256))
                / get_seconds_per_year_for_testing();
        let increased_interest_rate = interest_rate_per_year + percentage_increase;
        assert!(increased_interest_rate == lin_interest_rate_increase, TEST_SUCCESS);
    }

    #[test(creator = @0x1)]
    fun test_compounded_interest(creator: &signer) {
        let one_hour_in_secs = 1 * 60 * 60;
        // start the timer
        set_time_has_started_for_testing(creator);
        // fast forward 1 hour
        fast_forward_seconds(one_hour_in_secs);
        // get the ts for one hour ago
        let ts_one_hour_ago = timestamp::now_seconds() - one_hour_in_secs;
        // compute the interest rate
        let interest_rate_per_year = ray(); // ray per year
        let compunded_interest_rate_increase =
            calculate_compounded_interest_now(interest_rate_per_year, ts_one_hour_ago);
        let lin_interest_rate_increase =
            calculate_linear_interest(interest_rate_per_year, ts_one_hour_ago);
        // test that the compounded int. rate is indeed higher than the linear
        assert!(
            compunded_interest_rate_increase > lin_interest_rate_increase, TEST_SUCCESS
        );
    }

    #[test]
    fun test_percent_mul() {
        let value = 50;
        let percentage = get_percentage_factor_for_testing() / 5;
        let percentage_of_value = percent_mul(value, percentage);
        assert!(percentage_of_value == 50 / 5, TEST_SUCCESS);

        // test mult with 0 value
        assert!(percent_mul(0, percentage) == 0, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::math_utils)]
    fun test_percent_mul_overflow() {
        let percentage = get_percentage_factor_for_testing() / 5;
        let value =
            (get_u256_max_for_testing() - get_half_percentage_factor_for_testing())
                / percentage + 1;
        percent_mul(value, percentage);
    }

    #[test]
    fun test_percent_div() {
        let value = 50;
        let percentage = get_percentage_factor_for_testing() / 5;
        let percentage_of_value = percent_div(value, percentage);
        assert!(
            percentage_of_value
                == value * get_percentage_factor_for_testing() / percentage,
            TEST_SUCCESS
        );
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::math_utils)]
    fun test_percent_div_overflow() {
        let percentage = get_percentage_factor_for_testing() / 5;
        let value =
            (get_u256_max_for_testing() - get_half_percentage_factor_for_testing())
                / get_percentage_factor_for_testing() + 1;
        percent_div(value, percentage);
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::math_utils)]
    fun test_percent_div_by_zero() {
        percent_div(50, 0);
    }
}
