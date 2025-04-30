/// @title UserConfiguration library
/// @author Aave
/// @notice Implements the bitmap logic to handle the user configuration
module aave_config::user_config {
    use aave_config::error_config;
    use aave_config::helper;
    use aave_config::reserve_config;

    const BORROWING_MASK: u256 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    const COLLATERAL_MASK: u256 =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    /// Minimum health factor allowed under any circumstance
    /// A value of 0.95e18 results in 0.95
    /// 0.95 * 10 ** 18
    const MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD: u256 = 950000000000000000;

    /// @dev Minimum health factor to consider a user position healthy
    /// A value of 1e18 results in 1
    /// 1 * 10 ** 18
    const HEALTH_FACTOR_LIQUIDATION_THRESHOLD: u256 = 1000000000000000000;

    /// @dev Role identifier for the role allowed to supply isolated reserves as collateral
    const ISOLATED_COLLATERAL_SUPPLIER_ROLE: vector<u8> = b"ISOLATED_COLLATERAL_SUPPLIER";

    const INTEREST_RATE_MODE_NONE: u8 = 0;
    /// 1 = Stable Rate, 2 = Variable Rate, Since the Stable Rate service has been removed, only the Variable Rate service is retained.
    const INTEREST_RATE_MODE_VARIABLE: u8 = 2;

    struct UserConfigurationMap has key, copy, store, drop {
        /// @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
        /// The first bit indicates if an asset is used as collateral by the user, the second whether an
        /// asset is borrowed by the user.
        data: u256
    }

    /// @notice Initializes the user configuration map
    public fun init(): UserConfigurationMap {
        UserConfigurationMap { data: 0 }
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        let config = init();
        move_to(account, config);
    }

    public fun get_interest_rate_mode_none(): u8 {
        INTEREST_RATE_MODE_NONE
    }

    public fun get_interest_rate_mode_variable(): u8 {
        INTEREST_RATE_MODE_VARIABLE
    }

    public fun get_borrowing_mask(): u256 {
        BORROWING_MASK
    }

    public fun get_collateral_mask(): u256 {
        COLLATERAL_MASK
    }

    public fun get_minimum_health_factor_liquidation_threshold(): u256 {
        MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    public fun get_health_factor_liquidation_threshold(): u256 {
        HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    public fun get_isolated_collateral_supplier_role(): vector<u8> {
        ISOLATED_COLLATERAL_SUPPLIER_ROLE
    }

    /// @notice Sets if the user is borrowing the reserve identified by reserve_index
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @param borrowing True if the user is borrowing the reserve, false otherwise
    public fun set_borrowing(
        self: &mut UserConfigurationMap, reserve_index: u256, borrowing: bool
    ) {
        assert!(
            reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index()
        );
        let bit = 1 << ((reserve_index << 1) as u8);
        if (borrowing) {
            self.data = self.data | bit;
        } else {
            self.data = self.data & helper::bitwise_negation(bit);
        }
    }

    /// @notice Sets if the user is using as collateral the reserve identified by reserve_index
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @param using_as_collateral True if the user is using the reserve as collateral, false otherwise
    public fun set_using_as_collateral(
        self: &mut UserConfigurationMap, reserve_index: u256, using_as_collateral: bool
    ) {
        assert!(
            reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index()
        );
        let bit: u256 = 1 << (((reserve_index << 1) + 1) as u8);
        if (using_as_collateral) {
            self.data = self.data | bit;
        } else {
            self.data = self.data & helper::bitwise_negation(bit);
        }
    }

    /// @notice Returns if a user has been using the reserve for borrowing or as collateral
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
    public fun is_using_as_collateral_or_borrowing(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(
            reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index()
        );
        (self.data >> ((reserve_index << 1) as u8))
        & 3 != 0
    }

    /// @notice Validate a user has been using the reserve for borrowing
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @return True if the user has been using a reserve for borrowing, false otherwise
    public fun is_borrowing(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(
            reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index()
        );
        (self.data >> ((reserve_index << 1) as u8))
        & 1 != 0
    }

    /// @notice Validate a user has been using the reserve as collateral
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @return True if the user has been using a reserve as collateral, false otherwise
    public fun is_using_as_collateral(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(
            reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index()
        );
        (self.data >> ((reserve_index << 1) as u8) + 1)
        & 1 != 0
    }

    /// @notice Checks if a user has been supplying only one reserve as collateral
    /// @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
    /// @param self The configuration object
    /// @return True if the user has been supplying as collateral one reserve, false otherwise
    public fun is_using_as_collateral_one(self: &UserConfigurationMap): bool {
        let self_data = self.data & COLLATERAL_MASK;
        self_data != 0 && (self_data & (self_data - 1) == 0)
    }

    /// @notice Checks if a user has been supplying any reserve as collateral
    /// @param self The configuration object
    /// @return True if the user has been supplying as collateral any reserve, false otherwise
    public fun is_using_as_collateral_any(self: &UserConfigurationMap): bool {
        self.data & COLLATERAL_MASK != 0
    }

    /// @notice Checks if a user has been borrowing only one asset
    /// @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
    /// @param self The configuration object
    /// @return True if the user has been supplying as collateral one reserve, false otherwise
    public fun is_borrowing_one(self: &UserConfigurationMap): bool {
        let borrowing_data = self.data & BORROWING_MASK;
        borrowing_data != 0 && (borrowing_data & (borrowing_data - 1) == 0)
    }

    /// @notice Checks if a user has been borrowing from any reserve
    /// @param self The configuration object
    /// @return True if the user has been borrowing any reserve, false otherwise
    public fun is_borrowing_any(self: &UserConfigurationMap): bool {
        self.data & BORROWING_MASK != 0
    }

    /// @notice Checks if a user has not been using any reserve for borrowing or supply
    /// @param self The configuration object
    /// @return True if the user has not been borrowing or supplying any reserve, false otherwise
    public fun is_empty(self: &UserConfigurationMap): bool {
        self.data == 0
    }

    /// @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
    /// @param self The configuration object
    /// @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
    public fun get_first_asset_id_by_mask(
        self: &UserConfigurationMap, mask: u256
    ): u256 {
        let bit_map_data = self.data & mask;
        let first_asset_position = bit_map_data
            & helper::bitwise_negation(bit_map_data - 1);
        let id: u256 = 0;
        first_asset_position = first_asset_position >> 2;
        while (first_asset_position != 0) {
            id = id + 1;
            first_asset_position = first_asset_position >> 2;
        };
        id
    }

    #[test_only]
    public fun get_user_config_map(): UserConfigurationMap acquires UserConfigurationMap {
        *borrow_global<UserConfigurationMap>(@aave_config)
    }

    #[test_only]
    public fun get_minimum_health_factor_liquidation_threshold_for_testing(): u256 {
        MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    #[test_only]
    public fun get_health_factor_liquidation_threshold_for_testing(): u256 {
        HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    #[test_only]
    public fun get_isolated_collateral_supplier_role_for_testing(): vector<u8> {
        ISOLATED_COLLATERAL_SUPPLIER_ROLE
    }
}
