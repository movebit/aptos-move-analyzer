/// @title WadRayMath library
/// @author Aave
/// @notice Provides functions to perform calculations with Wad and Ray units
/// @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
/// with 27 digits of precision)
/// @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
module aave_math::wad_ray_math {
    use aave_config::error_config;

    /// u256 max
    const U256_MAX: u256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    /// 10^18
    const WAD: u256 = 1_000_000_000_000_000_000;
    /// 5 * 10^17
    const HALF_WAD: u256 = 500_000_000_000_000_000;
    /// 10^27
    const RAY: u256 = 1_000_000_000_000_000_000_000_000_000;
    /// 5 * 10^26
    const HALF_RAY: u256 = 500_000_000_000_000_000_000_000_000;
    /// 10^9
    const WAD_RAY_RATIO: u256 = 1_000_000_000;

    public fun wad(): u256 {
        WAD
    }

    #[test_only]
    public fun get_wad_for_testing(): u256 {
        wad()
    }

    public fun half_wad(): u256 {
        HALF_WAD
    }

    #[test_only]
    public fun get_half_wad_for_testing(): u256 {
        half_wad()
    }

    public fun ray(): u256 {
        RAY
    }

    #[test_only]
    public fun get_ray_for_testing(): u256 {
        ray()
    }

    public fun half_ray(): u256 {
        HALF_RAY
    }

    #[test_only]
    public fun get_half_ray_for_testing(): u256 {
        half_ray()
    }

    #[test_only]
    public fun get_wad_ray_ratio_for_testing(): u256 {
        WAD_RAY_RATIO
    }

    #[test_only]
    public fun get_u256_max_for_testing(): u256 {
        U256_MAX
    }

    /// @dev Multiplies two wad, rounding half up to the nearest wad
    /// @param a Wad
    /// @param b Wad
    /// @return c = a*b, in wad
    public fun wad_mul(a: u256, b: u256): u256 {
        if (a == 0 || b == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - HALF_WAD) / b,
            error_config::get_eoverflow()
        );
        (a * b + HALF_WAD) / WAD
    }

    /// @dev Divides two wad, rounding half up to the nearest wad
    /// @param a Wad
    /// @param b Wad
    /// @return c = a/b, in wad
    public fun wad_div(a: u256, b: u256): u256 {
        assert!(b > 0, error_config::get_edivision_by_zero());
        if (a == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - b / 2) / WAD,
            error_config::get_eoverflow()
        );
        (a * WAD + b / 2) / b
    }

    /// @notice Multiplies two ray, rounding half up to the nearest ray
    /// @param a Ray
    /// @param b Ray
    /// @return c = a raymul b
    public fun ray_mul(a: u256, b: u256): u256 {
        if (a == 0 || b == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - HALF_RAY) / b,
            error_config::get_eoverflow()
        );
        (a * b + HALF_RAY) / RAY
    }

    /// @notice Divides two ray, rounding half up to the nearest ray
    /// @param a Ray
    /// @param b Ray
    /// @return c = a raydiv b
    public fun ray_div(a: u256, b: u256): u256 {
        assert!(b > 0, error_config::get_edivision_by_zero());
        if (a == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - b / 2) / RAY,
            error_config::get_eoverflow()
        );
        (a * RAY + b / 2) / b
    }

    /// @dev Casts ray down to wad
    /// @param a Ray
    /// @return b = a converted to wad, rounded half up to the nearest wad
    public fun ray_to_wad(a: u256): u256 {
        let b = a / WAD_RAY_RATIO;
        let remainder = a % WAD_RAY_RATIO;
        if (remainder >= WAD_RAY_RATIO / 2) {
            b = b + 1;
        };
        b
    }

    /// @dev Converts wad up to ray
    /// @param a Wad
    /// @return b = a converted in ray
    public fun wad_to_ray(a: u256): u256 {
        let b = a * WAD_RAY_RATIO;
        assert!(
            b / WAD_RAY_RATIO == a,
            error_config::get_eoverflow()
        );
        b
    }
}
