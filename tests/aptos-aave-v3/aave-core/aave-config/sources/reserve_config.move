/// @title ReserveConfiguration module
/// @author Aave
/// @notice Implements the bitmap logic to handle the reserve configuration
module aave_config::reserve_config {
    use aave_config::error_config;
    use aave_config::helper;

    const LTV_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
    const LIQUIDATION_THRESHOLD_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF;
    const LIQUIDATION_BONUS_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF;
    const DECIMALS_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF;
    const ACTIVE_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
    const FROZEN_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF;
    const BORROWING_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF;
    const PAUSED_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF;
    const BORROWABLE_IN_ISOLATION_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF;
    const SILOED_BORROWING_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF;
    const FLASHLOAN_ENABLED_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF;
    const RESERVE_FACTOR_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;
    const BORROW_CAP_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF;
    const SUPPLY_CAP_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    const LIQUIDATION_PROTOCOL_FEE_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    const EMODE_CATEGORY_MASK: u256 =
        0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    const UNBACKED_MINT_CAP_MASK: u256 =
        0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    const DEBT_CEILING_MASK: u256 =
        0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    const LIQUIDATION_THRESHOLD_START_BIT_POSITION: u256 = 16;
    const LIQUIDATION_BONUS_START_BIT_POSITION: u256 = 32;
    const RESERVE_DECIMALS_START_BIT_POSITION: u256 = 48;
    const IS_ACTIVE_START_BIT_POSITION: u256 = 56;
    const IS_FROZEN_START_BIT_POSITION: u256 = 57;
    const BORROWING_ENABLED_START_BIT_POSITION: u256 = 58;
    const IS_PAUSED_START_BIT_POSITION: u256 = 60;
    const BORROWABLE_IN_ISOLATION_START_BIT_POSITION: u256 = 61;
    const SILOED_BORROWING_START_BIT_POSITION: u256 = 62;
    const FLASHLOAN_ENABLED_START_BIT_POSITION: u256 = 63;
    const RESERVE_FACTOR_START_BIT_POSITION: u256 = 64;
    const BORROW_CAP_START_BIT_POSITION: u256 = 80;
    const SUPPLY_CAP_START_BIT_POSITION: u256 = 116;
    const LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION: u256 = 152;
    const EMODE_CATEGORY_START_BIT_POSITION: u256 = 168;
    const UNBACKED_MINT_CAP_START_BIT_POSITION: u256 = 176;
    const DEBT_CEILING_START_BIT_POSITION: u256 = 212;

    // control values
    const MAX_VALID_LTV: u256 = 65535;
    const MAX_VALID_LIQUIDATION_THRESHOLD: u256 = 65535;
    const MAX_VALID_LIQUIDATION_BONUS: u256 = 65535;
    const MAX_VALID_DECIMALS: u256 = 255;
    const MAX_VALID_RESERVE_FACTOR: u256 = 65535;
    const MAX_VALID_BORROW_CAP: u256 = 68719476735;
    const MAX_VALID_SUPPLY_CAP: u256 = 68719476735;
    const MAX_VALID_LIQUIDATION_PROTOCOL_FEE: u256 = 65535;
    const MAX_VALID_EMODE_CATEGORY: u256 = 255;
    const MAX_VALID_UNBACKED_MINT_CAP: u256 = 68719476735;
    const MAX_VALID_DEBT_CEILING: u256 = 1099511627775;

    const DEBT_CEILING_DECIMALS: u256 = 2;
    const MAX_RESERVES_COUNT: u16 = 128;

    struct ReserveConfigurationMap has key, store, copy, drop {
        /// bit 0-15: LTV
        /// bit 16-31: Liq. threshold
        /// bit 32-47: Liq. bonus
        /// bit 48-55: Decimals
        /// bit 56: reserve is active
        /// bit 57: reserve is frozen
        /// bit 58: borrowing is enabled
        /// bit 59: stable rate borrowing enabled (already remove)
        /// bit 60: asset is paused
        /// bit 61: borrowing in isolation mode is enabled
        /// bit 62: siloed borrowing enabled
        /// bit 63: flashloaning enabled
        /// bit 64-79: reserve factor
        /// bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        /// bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        /// bit 152-167 liquidation protocol fee
        /// bit 168-175 eMode category
        /// bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        /// bit 212-251 debt ceiling for isolation mode with (ReserveConfigurationMap::DEBT_CEILING_DECIMALS) decimals
        /// bit 252-255 unused
        data: u256
    }

    /// @notice init the reserve configuration
    public fun init(): ReserveConfigurationMap {
        ReserveConfigurationMap { data: 0 }
    }

    /// @notice Sets the Loan to Value of the reserve
    /// @param self The reserve configuration
    /// @param ltv The new ltv
    public fun set_ltv(self: &mut ReserveConfigurationMap, ltv: u256) {
        assert!(ltv <= MAX_VALID_LTV, error_config::get_einvalid_ltv());
        self.data = (self.data & LTV_MASK) | ltv;
    }

    /// @notice Gets the Loan to Value of the reserve
    /// @param self The reserve configuration
    /// @return The loan to value
    public fun get_ltv(self: &ReserveConfigurationMap): u256 {
        self.data & helper::bitwise_negation(LTV_MASK)
    }

    /// @notice Sets the liquidation threshold of the reserve
    /// @param self The reserve configuration
    /// @param liquidation_threshold The new liquidation threshold
    public fun set_liquidation_threshold(
        self: &mut ReserveConfigurationMap, liquidation_threshold: u256
    ) {
        assert!(
            liquidation_threshold <= MAX_VALID_LIQUIDATION_THRESHOLD,
            error_config::get_einvalid_liq_threshold()
        );
        self.data = (self.data & LIQUIDATION_THRESHOLD_MASK)
            | (liquidation_threshold
                << (LIQUIDATION_THRESHOLD_START_BIT_POSITION as u8))
    }

    /// @notice Gets the liquidation threshold of the reserve
    /// @param self The reserve configuration
    /// @return The liquidation threshold
    public fun get_liquidation_threshold(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(LIQUIDATION_THRESHOLD_MASK))
            >> (LIQUIDATION_THRESHOLD_START_BIT_POSITION as u8)
    }

    /// @notice Sets the liquidation bonus of the reserve
    /// @param self The reserve configuration
    /// @param liquidation_bonus The new liquidation bonus
    public fun set_liquidation_bonus(
        self: &mut ReserveConfigurationMap, liquidation_bonus: u256
    ) {
        assert!(
            liquidation_bonus <= MAX_VALID_LIQUIDATION_BONUS,
            error_config::get_einvalid_liq_bonus()
        );
        self.data = (self.data & LIQUIDATION_BONUS_MASK)
            | (liquidation_bonus << (LIQUIDATION_BONUS_START_BIT_POSITION as u8))
    }

    /// @notice Gets the liquidation bonus of the reserve
    /// @param self The reserve configuration
    /// @return The liquidation bonus
    public fun get_liquidation_bonus(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(LIQUIDATION_BONUS_MASK))
            >> (LIQUIDATION_BONUS_START_BIT_POSITION as u8)
    }

    /// @notice Sets the decimals of the underlying asset of the reserve
    /// @param self The reserve configuration
    /// @param decimals The decimals
    public fun set_decimals(
        self: &mut ReserveConfigurationMap, decimals: u256
    ) {
        assert!(decimals <= MAX_VALID_DECIMALS, error_config::get_einvalid_decimals());
        self.data = (self.data & DECIMALS_MASK)
            | (decimals << (RESERVE_DECIMALS_START_BIT_POSITION as u8))
    }

    /// @notice Gets the decimals of the underlying asset of the reserve
    /// @param self The reserve configuration
    /// @return The decimals
    public fun get_decimals(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(DECIMALS_MASK))
            >> (RESERVE_DECIMALS_START_BIT_POSITION as u8)
    }

    /// @notice Sets the active state of the reserve
    /// @param self The reserve configuration
    /// @param active The new active state
    public fun set_active(
        self: &mut ReserveConfigurationMap, active: bool
    ) {
        let active_state: u256 = 0;
        if (active) {
            active_state = 1;
        };
        self.data = (self.data & ACTIVE_MASK)
            | active_state << (IS_ACTIVE_START_BIT_POSITION as u8)
    }

    /// @notice Gets the active state of the reserve
    /// @param self The reserve configuration
    /// @return The active state
    public fun get_active(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(ACTIVE_MASK)) != 0
    }

    /// @notice Sets the frozen state of the reserve
    /// @param self The reserve configuration
    /// @param frozen The new frozen state
    public fun set_frozen(
        self: &mut ReserveConfigurationMap, frozen: bool
    ) {
        let frozen_state: u256 = 0;
        if (frozen) {
            frozen_state = 1;
        };
        self.data = (self.data & FROZEN_MASK)
            | (frozen_state << (IS_FROZEN_START_BIT_POSITION as u8))
    }

    /// @notice Gets the frozen state of the reserve
    /// @param self The reserve configuration
    /// @return The frozen state
    public fun get_frozen(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(FROZEN_MASK)) != 0
    }

    /// @notice Sets the paused state of the reserve
    /// @param self The reserve configuration
    /// @param paused The new paused state
    public fun set_paused(
        self: &mut ReserveConfigurationMap, paused: bool
    ) {
        let paused_state: u256 = 0;
        if (paused) {
            paused_state = 1;
        };
        self.data = (self.data & PAUSED_MASK)
            | (paused_state << (IS_PAUSED_START_BIT_POSITION as u8))
    }

    /// @notice Gets the paused state of the reserve
    /// @param self The reserve configuration
    /// @return The paused state
    public fun get_paused(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(PAUSED_MASK)) != 0
    }

    /// @notice Sets the borrowing in isolation state of the reserve
    /// @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
    /// amount will be accumulated in the isolated collateral's total debt exposure.
    /// @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
    /// consistency in the debt ceiling calculations.
    /// @param self The reserve configuration
    /// @param borrowable The new borrowing in isolation state
    public fun set_borrowable_in_isolation(
        self: &mut ReserveConfigurationMap, borrowable: bool
    ) {
        let borrowable_state: u256 = 0;
        if (borrowable) {
            borrowable_state = 1;
        };
        self.data = (self.data & BORROWABLE_IN_ISOLATION_MASK)
            | (borrowable_state << (BORROWABLE_IN_ISOLATION_START_BIT_POSITION as u8))
    }

    /// @notice Gets the borrowable in isolation flag for the reserve.
    /// @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
    /// isolated collateral is accounted for in the isolated collateral's total debt exposure.
    /// @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
    /// consistency in the debt ceiling calculations.
    /// @param self The reserve configuration
    /// @return The borrowable in isolation flag
    public fun get_borrowable_in_isolation(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(BORROWABLE_IN_ISOLATION_MASK)) != 0
    }

    /// @notice Sets the siloed borrowing flag for the reserve.
    /// @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
    /// @param self The reserve configuration
    /// @param siloed_borrowing True if the asset is siloed
    public fun set_siloed_borrowing(
        self: &mut ReserveConfigurationMap, siloed_borrowing: bool
    ) {
        let siloed_borrowing_state: u256 = 0;
        if (siloed_borrowing) {
            siloed_borrowing_state = 1;
        };
        self.data = (self.data & SILOED_BORROWING_MASK)
            | siloed_borrowing_state << (SILOED_BORROWING_START_BIT_POSITION as u8)
    }

    /// @notice Gets the siloed borrowing flag for the reserve.
    /// @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
    /// @param self The reserve configuration
    /// @return The siloed borrowing flag
    public fun get_siloed_borrowing(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(SILOED_BORROWING_MASK)) != 0
    }

    /// @notice Enables or disables borrowing on the reserve
    /// @param self The reserve configuration
    /// @param borrowing_enabled True if the borrowing needs to be enabled, false otherwise
    public fun set_borrowing_enabled(
        self: &mut ReserveConfigurationMap, borrowing_enabled: bool
    ) {
        let borrowing_enabled_state: u256 = 0;
        if (borrowing_enabled) {
            borrowing_enabled_state = 1;
        };
        self.data = (self.data & BORROWING_MASK)
            | borrowing_enabled_state << (BORROWING_ENABLED_START_BIT_POSITION as u8)
    }

    /// @notice Gets the borrowing state of the reserve
    /// @param self The reserve configuration
    /// @return The borrowing state
    public fun get_borrowing_enabled(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(BORROWING_MASK)) != 0
    }

    /// @notice Sets the reserve factor of the reserve
    /// @param self The reserve configuration
    /// @param reserve_factor The reserve factor
    public fun set_reserve_factor(
        self: &mut ReserveConfigurationMap, reserve_factor: u256
    ) {
        assert!(
            reserve_factor <= MAX_VALID_RESERVE_FACTOR,
            error_config::get_einvalid_reserve_factor()
        );

        self.data = (self.data & RESERVE_FACTOR_MASK)
            | (reserve_factor << (RESERVE_FACTOR_START_BIT_POSITION as u8))
    }

    /// @notice Gets the reserve factor of the reserve
    /// @param self The reserve configuration
    /// @return The reserve factor
    public fun get_reserve_factor(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(RESERVE_FACTOR_MASK))
            >> (RESERVE_FACTOR_START_BIT_POSITION as u8)
    }

    /// @notice Sets the borrow cap of the reserve
    /// @param self The reserve configuration
    /// @param borrow_cap The borrow cap
    public fun set_borrow_cap(
        self: &mut ReserveConfigurationMap, borrow_cap: u256
    ) {
        assert!(
            borrow_cap <= MAX_VALID_BORROW_CAP, error_config::get_einvalid_borrow_cap()
        );
        self.data = (self.data & BORROW_CAP_MASK)
            | (borrow_cap << (BORROW_CAP_START_BIT_POSITION as u8));
    }

    /// @notice Gets the borrow cap of the reserve
    /// @param self The reserve configuration
    /// @return The borrow cap
    public fun get_borrow_cap(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(BORROW_CAP_MASK))
            >> (BORROW_CAP_START_BIT_POSITION as u8)
    }

    /// @notice Sets the supply cap of the reserve
    /// @param self The reserve configuration
    /// @param supply_cap The supply cap
    public fun set_supply_cap(
        self: &mut ReserveConfigurationMap, supply_cap: u256
    ) {
        assert!(
            supply_cap <= MAX_VALID_SUPPLY_CAP, error_config::get_einvalid_supply_cap()
        );
        self.data = (self.data & SUPPLY_CAP_MASK)
            | (supply_cap << (SUPPLY_CAP_START_BIT_POSITION as u8))
    }

    /// @notice Gets the supply cap of the reserve
    /// @param self The reserve configuration
    /// @return The supply cap
    public fun get_supply_cap(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(SUPPLY_CAP_MASK))
            >> (SUPPLY_CAP_START_BIT_POSITION as u8)
    }

    /// @notice Sets the debt ceiling in isolation mode for the asset
    /// @param self The reserve configuration
    /// @param debt_ceiling The maximum debt ceiling for the asset
    public fun set_debt_ceiling(
        self: &mut ReserveConfigurationMap, debt_ceiling: u256
    ) {
        assert!(
            debt_ceiling <= MAX_VALID_DEBT_CEILING,
            error_config::get_einvalid_debt_ceiling()
        );

        self.data = (self.data & DEBT_CEILING_MASK)
            | (debt_ceiling << (DEBT_CEILING_START_BIT_POSITION as u8));
    }

    /// @notice Gets the debt ceiling for the asset if the asset is in isolation mode
    /// @param self The reserve configuration
    /// @return The debt ceiling (0 = isolation mode disabled)
    public fun get_debt_ceiling(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(DEBT_CEILING_MASK))
            >> (DEBT_CEILING_START_BIT_POSITION as u8)
    }

    /// @notice Sets the liquidation protocol fee of the reserve
    /// @param self The reserve configuration
    /// @param liquidation_protocol_fee The liquidation protocol fee
    public fun set_liquidation_protocol_fee(
        self: &mut ReserveConfigurationMap, liquidation_protocol_fee: u256
    ) {
        assert!(
            liquidation_protocol_fee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
            error_config::get_einvalid_liquidation_protocol_fee()
        );
        self.data = (self.data & LIQUIDATION_PROTOCOL_FEE_MASK)
            | (
                liquidation_protocol_fee
                    << (LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION as u8)
            )
    }

    /// @dev Gets the liquidation protocol fee
    /// @param self The reserve configuration
    /// @return The liquidation protocol fee
    public fun get_liquidation_protocol_fee(
        self: &ReserveConfigurationMap
    ): u256 {
        (self.data & helper::bitwise_negation(LIQUIDATION_PROTOCOL_FEE_MASK))
            >> (LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION as u8)
    }

    /// @notice Sets the unbacked mint cap of the reserve
    /// @param self The reserve configuration
    /// @param unbacked_mint_cap The unbacked mint cap
    public fun set_unbacked_mint_cap(
        self: &mut ReserveConfigurationMap, unbacked_mint_cap: u256
    ) {
        assert!(
            unbacked_mint_cap <= MAX_VALID_UNBACKED_MINT_CAP,
            error_config::get_einvalid_unbacked_mint_cap()
        );

        self.data = (self.data & UNBACKED_MINT_CAP_MASK)
            | (unbacked_mint_cap << (UNBACKED_MINT_CAP_START_BIT_POSITION as u8))
    }

    /// @dev Gets the unbacked mint cap of the reserve
    /// @param self The reserve configuration
    /// @return The unbacked mint cap
    public fun get_unbacked_mint_cap(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(UNBACKED_MINT_CAP_MASK))
            >> (UNBACKED_MINT_CAP_START_BIT_POSITION as u8)
    }

    /// @notice Sets the eMode asset category
    /// @param self The reserve configuration
    /// @param emode_category The asset category when the user selects the eMode
    public fun set_emode_category(
        self: &mut ReserveConfigurationMap, emode_category: u256
    ) {
        assert!(
            emode_category <= MAX_VALID_EMODE_CATEGORY,
            error_config::get_einvalid_emode_category()
        );
        self.data = (self.data & EMODE_CATEGORY_MASK)
            | (emode_category << (EMODE_CATEGORY_START_BIT_POSITION as u8))
    }

    /// @dev Gets the eMode asset category
    /// @param self The reserve configuration
    /// @return The eMode category for the asset
    public fun get_emode_category(self: &ReserveConfigurationMap): u256 {
        (self.data & helper::bitwise_negation(EMODE_CATEGORY_MASK))
            >> (EMODE_CATEGORY_START_BIT_POSITION as u8)
    }

    /// @notice Sets the flashloanable flag for the reserve
    /// @param self The reserve configuration
    /// @param flash_loan_enabled True if the asset is flashloanable, false otherwise
    public fun set_flash_loan_enabled(
        self: &mut ReserveConfigurationMap, flash_loan_enabled: bool
    ) {
        let flash_loan_enabled_state: u256 = 0;
        if (flash_loan_enabled) {
            flash_loan_enabled_state = 1;
        };
        self.data = (self.data & FLASHLOAN_ENABLED_MASK)
            | (flash_loan_enabled_state << (FLASHLOAN_ENABLED_START_BIT_POSITION as u8))
    }

    /// @notice Gets the flashloanable flag for the reserve
    /// @param self The reserve configuration
    /// @return The flashloanable flag
    public fun get_flash_loan_enabled(self: &ReserveConfigurationMap): bool {
        (self.data & helper::bitwise_negation(FLASHLOAN_ENABLED_MASK)) != 0
    }

    /// @notice Gets the configuration flags of the reserve
    /// @param self The reserve configuration
    /// @return The state flag representing active
    /// @return The state flag representing frozen
    /// @return The state flag representing borrowing enabled
    /// @return The state flag representing paused
    public fun get_flags(self: &ReserveConfigurationMap): (bool, bool, bool, bool) {
        (
            get_active(self),
            get_frozen(self),
            get_borrowing_enabled(self),
            get_paused(self)
        )
    }

    /// @notice Gets the configuration parameters of the reserve from storage
    /// @param self The reserve configuration
    /// @return The state param representing ltv
    /// @return The state param representing liquidation threshold
    /// @return The state param representing liquidation bonus
    /// @return The state param representing reserve decimals
    /// @return The state param representing reserve factor
    /// @return The state param representing eMode category
    public fun get_params(self: &ReserveConfigurationMap):
        (u256, u256, u256, u256, u256, u256) {
        (
            get_ltv(self),
            get_liquidation_threshold(self),
            get_liquidation_bonus(self),
            get_decimals(self),
            get_reserve_factor(self),
            get_emode_category(self)
        )
    }

    /// @notice Gets the caps parameters of the reserve from storage
    /// @param self The reserve configuration
    /// @return The state param representing borrow cap
    /// @return The state param representing supply cap.
    public fun get_caps(self: &ReserveConfigurationMap): (u256, u256) {
        (get_borrow_cap(self), get_supply_cap(self))
    }

    /// @notice Gets the debt ceiling decimals
    public fun get_debt_ceiling_decimals(): u256 {
        DEBT_CEILING_DECIMALS
    }

    /// @notice Gets the maximum number of reserves
    public fun get_max_reserves_count(): u16 {
        MAX_RESERVES_COUNT
    }

    #[test_only]
    public fun get_max_valid_ltv(): u256 {
        MAX_VALID_LTV
    }

    #[test_only]
    public fun get_max_valid_liquidation_threshold(): u256 {
        MAX_VALID_LIQUIDATION_THRESHOLD
    }

    #[test_only]
    public fun get_max_valid_liquidation_bonus(): u256 {
        MAX_VALID_LIQUIDATION_BONUS
    }

    #[test_only]
    public fun get_max_valid_decimals(): u256 {
        MAX_VALID_DECIMALS
    }

    #[test_only]
    public fun get_max_valid_reserve_factor(): u256 {
        MAX_VALID_RESERVE_FACTOR
    }

    #[test_only]
    public fun get_max_valid_borrow_cap(): u256 {
        MAX_VALID_BORROW_CAP
    }

    #[test_only]
    public fun get_max_valid_supply_cap(): u256 {
        MAX_VALID_SUPPLY_CAP
    }

    #[test_only]
    public fun get_max_valid_liquidation_protocol_fee(): u256 {
        MAX_VALID_LIQUIDATION_PROTOCOL_FEE
    }

    #[test_only]
    public fun get_max_valid_emode_category(): u256 {
        MAX_VALID_EMODE_CATEGORY
    }

    #[test_only]
    public fun get_max_valid_unbacked_mint_cap(): u256 {
        MAX_VALID_UNBACKED_MINT_CAP
    }

    #[test_only]
    public fun get_max_valid_debt_ceiling(): u256 {
        MAX_VALID_DEBT_CEILING
    }
}
