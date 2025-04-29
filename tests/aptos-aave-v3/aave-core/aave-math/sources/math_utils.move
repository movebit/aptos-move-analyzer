module aave_math::math_utils {
    use aptos_framework::timestamp;

    use aave_config::error_config;

    use aave_math::wad_ray_math;

    const U256_MAX: u256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev Ignoring leap years
    const SECONDS_PER_YEAR: u256 = 365 * 24 * 3600;

    /// Maximum percentage factor (100.00%)
    const PERCENTAGE_FACTOR: u256 = 10000;

    /// Half percentage factor (50.00%)
    const HALF_PERCENTAGE_FACTOR: u256 = 5 * 1000;

    public fun u256_max(): u256 {
        U256_MAX
    }

    #[test_only]
    public fun get_seconds_per_year_for_testing(): u256 {
        SECONDS_PER_YEAR
    }

    #[test_only]
    public fun get_half_percentage_factor_for_testing(): u256 {
        HALF_PERCENTAGE_FACTOR
    }

    #[test_only]
    public fun get_u256_max_for_testing(): u256 {
        u256_max()
    }

    /// @dev Function to calculate the interest accumulated using a linear interest rate formula
    /// @param rate The interest rate, in ray
    /// @param last_update_timestamp The timestamp of the last update of the interest
    /// @return The interest rate linearly accumulated during the timeDelta, in ray
    public fun calculate_linear_interest(
        rate: u256, last_update_timestamp: u64
    ): u256 {
        let time_passed = timestamp::now_seconds() - last_update_timestamp;
        let result = rate * (time_passed as u256);
        wad_ray_math::ray() + (result / SECONDS_PER_YEAR)
    }

    /// @dev Function to calculate the interest using a compounded interest rate formula
    /// To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
    ///
    /// (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
    ///
    /// The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
    /// gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
    /// error per different time periods
    ///
    /// @param rate The interest rate, in ray
    /// @param last_update_timestamp The timestamp of the last update of the interest
    /// @return The interest rate compounded during the timeDelta, in ray
    public fun calculate_compounded_interest(
        rate: u256, last_update_timestamp: u64, current_timestamp: u64
    ): u256 {
        let exp = ((current_timestamp - last_update_timestamp) as u256);
        if (exp == 0) {
            return wad_ray_math::ray()
        };

        let exp_minus_one = exp - 1;
        let exp_minus_two = if (exp > 2) exp - 2 else 0;
        let base_power_two =
            wad_ray_math::ray_mul(rate, rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
        let base_power_three =
            wad_ray_math::ray_mul(base_power_two, rate) / SECONDS_PER_YEAR;
        let second_term = (exp * exp_minus_one * base_power_two) / 2;
        let third_term = (exp * exp_minus_one * exp_minus_two * base_power_three) / 6;

        wad_ray_math::ray() + (rate * exp) / SECONDS_PER_YEAR + second_term
            + third_term
    }

    /// @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
    /// @param rate The interest rate (in ray)
    /// @param last_update_timestamp The timestamp from which the interest accumulation needs to be calculated
    /// @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
    public fun calculate_compounded_interest_now(
        rate: u256, last_update_timestamp: u64
    ): u256 {
        calculate_compounded_interest(
            rate, last_update_timestamp, timestamp::now_seconds()
        )
    }

    public fun get_percentage_factor(): u256 {
        PERCENTAGE_FACTOR
    }

    #[test_only]
    public fun get_percentage_factor_for_testing(): u256 {
        PERCENTAGE_FACTOR
    }

    /// @notice Executes a percentage multiplication
    /// @param value The value of which the percentage needs to be calculated
    /// @param percentage The percentage of the value to be calculated
    /// @return result value percentmul percentage
    public fun percent_mul(value: u256, percentage: u256): u256 {
        if (value == 0 || percentage == 0) {
            return 0
        };
        assert!(
            value <= (U256_MAX - HALF_PERCENTAGE_FACTOR) / percentage,
            error_config::get_eoverflow()
        );
        (value * percentage + HALF_PERCENTAGE_FACTOR) / PERCENTAGE_FACTOR
    }

    /// @notice Executes a percentage division
    /// @param value The value of which the percentage needs to be calculated
    /// @param percentage The percentage of the value to be calculated
    /// @return result value percentdiv percentage
    public fun percent_div(value: u256, percentage: u256): u256 {
        assert!(percentage > 0, error_config::get_edivision_by_zero());
        assert!(
            value <= (U256_MAX - HALF_PERCENTAGE_FACTOR) / PERCENTAGE_FACTOR,
            error_config::get_eoverflow()
        );
        (value * PERCENTAGE_FACTOR + percentage / 2) / percentage
    }

    // Get the power
    public fun pow(base: u256, exponent: u256): u256 {
        let result = 1;
        for (_i in 0..exponent) {
            result = result * base;
        };
        result
    }
}
