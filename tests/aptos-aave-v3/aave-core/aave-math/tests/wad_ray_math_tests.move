#[test_only]
module aave_math::wad_ray_math_tests {
    use aave_config::error_config::{EOVERFLOW, EDIVISION_BY_ZERO};
    use aave_math::wad_ray_math::{
        get_half_ray_for_testing,
        get_half_wad_for_testing,
        get_ray_for_testing,
        get_u256_max_for_testing,
        get_wad_for_testing,
        get_wad_ray_ratio_for_testing,
        half_ray,
        half_wad,
        ray,
        ray_div,
        ray_mul,
        ray_to_wad,
        wad,
        wad_div,
        wad_mul,
        wad_to_ray
    };

    const TEST_SUCCESS: u64 = 1;

    #[test]
    fun test_getters() {
        assert!(wad() == get_wad_for_testing(), TEST_SUCCESS);
        assert!(half_wad() == get_half_wad_for_testing(), TEST_SUCCESS);
        assert!(ray() == get_ray_for_testing(), TEST_SUCCESS);
        assert!(half_ray() == get_half_ray_for_testing(), TEST_SUCCESS);
    }

    #[test]
    fun test_wad_mul() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        assert!(wad_mul(a, 0) == 0, TEST_SUCCESS);
        assert!(wad_mul(0, b) == 0, TEST_SUCCESS);
        let x = wad_mul(a, b);
        assert!(x == 1784662923287792467070443765, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_wad_overflow_mult() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - get_half_wad_for_testing()) / b
            + 1;
        wad_mul(tooLargeA, b);
    }

    #[test]
    fun test_wad_div() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        let x = wad_div(a, b);
        assert!(x == 10141715327055228122, TEST_SUCCESS);
        assert!(wad_div(0, b) == 0, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::wad_ray_math)]
    fun test_wad_div_by_zero() {
        let a = 134534543232342353231234;
        wad_div(a, 0);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_wad_div_overflow() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - b / 2) / get_wad_for_testing()
            + 1;
        wad_div(tooLargeA, b);
    }

    #[test]
    fun test_ray_mul() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        assert!(ray_mul(a, 0) == 0, TEST_SUCCESS);
        assert!(ray_mul(0, b) == 0, TEST_SUCCESS);
        let x = ray_mul(a, b);
        assert!(x == 1784662923287792467, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_ray_overflow_mult() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - get_half_ray_for_testing()) / b
            + 1;
        ray_mul(tooLargeA, b);
    }

    #[test]
    fun test_ray_div() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        let x = ray_div(a, b);
        assert!(x == 10141715327055228122033939726, TEST_SUCCESS);
        assert!(ray_div(0, b) == 0, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::wad_ray_math)]
    fun test_ray_div_by_zero() {
        let a = 134534543232342353231234;
        ray_div(a, 0);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_ray_div_overflow() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - b / 2) / get_ray_for_testing()
            + 1;
        ray_div(tooLargeA, b);
    }

    #[test]
    fun test_ray_to_way() {
        let ray = 1 * get_ray_for_testing();
        let x = ray_to_wad(ray);
        assert!(x == 1 * get_wad_for_testing(), TEST_SUCCESS);

        let round_down = get_ray_for_testing() + (get_wad_ray_ratio_for_testing() / 2)
            - 1;
        let x = ray_to_wad(round_down);
        assert!(x == 1000000000000000000, TEST_SUCCESS);

        let round_up = get_ray_for_testing() + (get_wad_ray_ratio_for_testing() / 2) + 1;
        let x = ray_to_wad(round_up);
        assert!(x == 1000000000000000001, TEST_SUCCESS);

        let too_large = get_u256_max_for_testing()
            - (get_wad_ray_ratio_for_testing() / 2) + 1;
        let x = ray_to_wad(too_large);
        assert!(
            x == 115792089237316195423570985008687907853269984665640564039457584007913,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_wad_to_ray() {
        let ray = 1 * get_wad_for_testing();
        let x = wad_to_ray(ray);
        assert!(x == 1 * get_ray_for_testing(), TEST_SUCCESS);
    }

    #[test]
    #[expected_failure]
    fun test_wad_to_ray_overflow() {
        let too_large = get_u256_max_for_testing() / get_wad_ray_ratio_for_testing()
            + 1;
        wad_to_ray(too_large);
    }
}
