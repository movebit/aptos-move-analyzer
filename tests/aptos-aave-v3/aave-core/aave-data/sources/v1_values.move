module aave_data::v1_values {
    // std
    use std::option;
    use std::option::Option;
    use std::string;
    use std::string::{String, utf8};
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::aptos_coin;
    // locals
    use aave_pool::coin_migrator;

    // assets
    const USDT_ASSET: vector<u8> = b"USDT";
    const USDC_ASSET: vector<u8> = b"USDC";
    const AMAPT_ASSET: vector<u8> = b"amAPT";
    const THAPT_ASSET: vector<u8> = b"thAPT";
    const APT_ASSET: vector<u8> = b"APT";

    struct ReserveConfig has store, copy, drop {
        base_ltv_as_collateral: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256,
        liquidation_protocol_fee: u256,
        borrowing_enabled: bool,
        flashLoan_enabled: bool,
        reserve_factor: u256,
        supply_cap: u256,
        borrow_cap: u256,
        debt_ceiling: u256,
        borrowable_isolation: bool,
        siloed_borrowing: bool,
        emode_category: Option<u256>
    }

    struct InterestRateStrategy has store, copy, drop {
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    }

    struct EmodeConfig has store, copy, drop {
        category_id: u256,
        ltv: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256,
        label: String
    }

    public fun get_emode_category_id(emode_config: &EmodeConfig): u256 {
        emode_config.category_id
    }

    public fun get_emode_ltv(emode_config: &EmodeConfig): u256 {
        emode_config.ltv
    }

    public fun get_emode_liquidation_threshold(emode_config: &EmodeConfig): u256 {
        emode_config.liquidation_threshold
    }

    public fun get_emode_liquidation_bonus(emode_config: &EmodeConfig): u256 {
        emode_config.liquidation_bonus
    }

    public fun get_emode_liquidation_label(emode_config: &EmodeConfig): String {
        emode_config.label
    }

    public fun get_optimal_usage_ratio(ir_strategy: &InterestRateStrategy): u256 {
        ir_strategy.optimal_usage_ratio
    }

    public fun get_base_variable_borrow_rate(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.base_variable_borrow_rate
    }

    public fun get_variable_rate_slope1(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.variable_rate_slope1
    }

    public fun get_variable_rate_slope2(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.variable_rate_slope2
    }

    public fun get_base_ltv_as_collateral(reserve_config: &ReserveConfig): u256 {
        reserve_config.base_ltv_as_collateral
    }

    public fun get_liquidation_threshold(reserve_config: &ReserveConfig): u256 {
        reserve_config.liquidation_threshold
    }

    public fun get_liquidation_bonus(reserve_config: &ReserveConfig): u256 {
        reserve_config.liquidation_bonus
    }

    public fun get_liquidation_protocol_fee(
        reserve_config: &ReserveConfig
    ): u256 {
        reserve_config.liquidation_protocol_fee
    }

    public fun get_borrowing_enabled(reserve_config: &ReserveConfig): bool {
        reserve_config.borrowing_enabled
    }

    public fun get_flashLoan_enabled(reserve_config: &ReserveConfig): bool {
        reserve_config.flashLoan_enabled
    }

    public fun get_reserve_factor(reserve_config: &ReserveConfig): u256 {
        reserve_config.reserve_factor
    }

    public fun get_supply_cap(reserve_config: &ReserveConfig): u256 {
        reserve_config.supply_cap
    }

    public fun get_borrow_cap(reserve_config: &ReserveConfig): u256 {
        reserve_config.borrow_cap
    }

    public fun get_debt_ceiling(reserve_config: &ReserveConfig): u256 {
        reserve_config.debt_ceiling
    }

    public fun get_borrowable_isolation(reserve_config: &ReserveConfig): bool {
        reserve_config.borrowable_isolation
    }

    public fun get_siloed_borrowing(reserve_config: &ReserveConfig): bool {
        reserve_config.siloed_borrowing
    }

    public fun get_emode_category(reserve_config: &ReserveConfig): Option<u256> {
        reserve_config.emode_category
    }

    // TODO: add settings here per network
    public fun build_emodes_testnet(): SmartTable<u256, EmodeConfig> {
        let emodes = smart_table::new<u256, EmodeConfig>();
        smart_table::add(
            &mut emodes,
            1,
            EmodeConfig {
                category_id: 1,
                ltv: 9000,
                liquidation_threshold: 9300,
                liquidation_bonus: 10200,
                label: string::utf8(b"ETH Correlated")
            }
        );
        smart_table::add(
            &mut emodes,
            2,
            EmodeConfig {
                category_id: 2,
                ltv: 9500,
                liquidation_threshold: 9700,
                liquidation_bonus: 10100,
                label: string::utf8(b"Stablecoins")
            }
        );
        emodes
    }

    // TODO: add settings here per network
    public fun build_emodes_mainnet(): SmartTable<u256, EmodeConfig> {
        let emodes = smart_table::new<u256, EmodeConfig>();
        smart_table::add(
            &mut emodes,
            1,
            EmodeConfig {
                category_id: 1,
                ltv: 9000,
                liquidation_threshold: 9300,
                liquidation_bonus: 10200,
                label: string::utf8(b"ETH Correlated")
            }
        );
        smart_table::add(
            &mut emodes,
            2,
            EmodeConfig {
                category_id: 2,
                ltv: 9500,
                liquidation_threshold: 9700,
                liquidation_bonus: 10100,
                label: string::utf8(b"Stablecoins")
            }
        );
        emodes
    }

    // TODO: add feed id here per network
    public fun build_price_feeds_testnet(): SmartTable<String, vector<u8>> {
        let price_feeds_testnet = smart_table::new<string::String, vector<u8>>();
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(APT_ASSET),
            x"011e22d6bf000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(USDC_ASSET),
            x"01a80ff216000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(USDT_ASSET),
            x"016d06ebb6000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(AMAPT_ASSET),
            x"01a0b4d920000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(THAPT_ASSET),
            x"01d585327c000332000000000000000000000000000000000000000000000000"
        );
        price_feeds_testnet
    }

    // TODO: add feed id here per network
    public fun build_price_feeds_mainnet(): SmartTable<String, vector<u8>> {
        let price_feeds_mainnet = smart_table::new<string::String, vector<u8>>();
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(APT_ASSET),
            x"011e22d6bf000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(USDC_ASSET),
            x"01a80ff216000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(USDT_ASSET),
            x"016d06ebb6000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(AMAPT_ASSET),
            x"01a0b4d920000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(THAPT_ASSET),
            x"01d585327c000332000000000000000000000000000000000000000000000000"
        );
        price_feeds_mainnet
    }

    // TODO: add address here per network
    public fun build_underlying_assets_testnet(): SmartTable<String, address> {
        let apt_mapped_fa_asset = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();
        let underlying_assets_testnet = smart_table::new<String, address>();
        smart_table::upsert(&mut underlying_assets_testnet, utf8(USDT_ASSET), @0x0);
        smart_table::upsert(&mut underlying_assets_testnet, utf8(USDC_ASSET), @0x0);
        smart_table::upsert(&mut underlying_assets_testnet, utf8(AMAPT_ASSET), @0x0);
        smart_table::upsert(&mut underlying_assets_testnet, utf8(THAPT_ASSET), @0x0);
        smart_table::upsert(
            &mut underlying_assets_testnet, utf8(APT_ASSET), apt_mapped_fa_asset
        );
        underlying_assets_testnet
    }

    // TODO: add address here per network
    public fun build_underlying_assets_mainnet(): SmartTable<String, address> {
        let apt_mapped_fa_asset = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();
        let underlying_assets_mainnet = smart_table::new<String, address>();
        smart_table::upsert(&mut underlying_assets_mainnet, utf8(USDT_ASSET), @0x0);
        smart_table::upsert(&mut underlying_assets_mainnet, utf8(USDC_ASSET), @0x0);
        smart_table::upsert(&mut underlying_assets_mainnet, utf8(AMAPT_ASSET), @0x0);
        smart_table::upsert(&mut underlying_assets_mainnet, utf8(THAPT_ASSET), @0x0);
        smart_table::upsert(
            &mut underlying_assets_mainnet, utf8(APT_ASSET), apt_mapped_fa_asset
        );
        underlying_assets_mainnet
    }

    // TODO: add data for each value
    public fun build_reserve_config_testnet(): SmartTable<string::String, ReserveConfig> {
        let reserve_config = smart_table::new<String, ReserveConfig>();
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDC_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(AMAPT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(THAPT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(APT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        reserve_config
    }

    // TODO: add data for each value
    public fun build_reserve_config_mainnet(): SmartTable<string::String, ReserveConfig> {
        let reserve_config = smart_table::new<String, ReserveConfig>();
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDC_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(AMAPT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(THAPT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(APT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: 8000,
                liquidation_threshold: 8500,
                liquidation_bonus: 10500,
                liquidation_protocol_fee: 1000,
                borrowing_enabled: true,
                flashLoan_enabled: true,
                reserve_factor: 1000,
                supply_cap: 0,
                borrow_cap: 0,
                debt_ceiling: 0,
                borrowable_isolation: true,
                siloed_borrowing: true,
                emode_category: option::none()
            }
        );
        reserve_config
    }

    // TODO: add data for each value
    public fun build_interest_rate_strategy_mainnet():
        SmartTable<string::String, InterestRateStrategy> {
        let interest_rate_config = smart_table::new<String, InterestRateStrategy>();
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDC_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(AMAPT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(THAPT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(APT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        interest_rate_config
    }

    // TODO: add data for each value
    public fun build_interest_rate_strategy_testnet():
        SmartTable<string::String, InterestRateStrategy> {
        let interest_rate_config = smart_table::new<String, InterestRateStrategy>();
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDC_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(AMAPT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(THAPT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(APT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: 800000000000000000000000000,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 40000000000000000000000000,
                variable_rate_slope2: 750000000000000000000000000
            }
        );
        interest_rate_config
    }
}
