module aave_data::v1 {
    // std
    use std::signer;
    use std::string;
    use std::string::String;
    use aptos_std::string_utils;
    use aptos_std::smart_table;
    // locals
    use aave_config::error_config;

    // prefixes
    const ATOKEN_NAME_PREFIX: vector<u8> = b"AAVE_A";
    const ATOKEN_SYMBOL_PREFIX: vector<u8> = b"aaveA";
    const VARTOKEN_NAME_PREFIX: vector<u8> = b"AAVE_VAR";
    const VARTOKEN_SYMBOL_PREFIX: vector<u8> = b"aaveVar";

    struct Data has key {
        price_feeds_testnet: smart_table::SmartTable<string::String, vector<u8>>,
        price_feeds_mainnet: smart_table::SmartTable<string::String, vector<u8>>,
        underlying_assets_testnet: smart_table::SmartTable<string::String, address>,
        underlying_assets_mainnet: smart_table::SmartTable<string::String, address>,
        reserves_config_testnet: smart_table::SmartTable<string::String, aave_data::v1_values::ReserveConfig>,
        reserves_config_mainnet: smart_table::SmartTable<string::String, aave_data::v1_values::ReserveConfig>,
        interest_rate_strategy_testnet: smart_table::SmartTable<string::String, aave_data::v1_values::InterestRateStrategy>,
        interest_rate_strategy_mainnet: smart_table::SmartTable<string::String, aave_data::v1_values::InterestRateStrategy>,
        emodes_testnet: smart_table::SmartTable<u256, aave_data::v1_values::EmodeConfig>,
        emodes_mainnet: smart_table::SmartTable<u256, aave_data::v1_values::EmodeConfig>
    }

    fun init_module(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_data,
            error_config::get_enot_pool_owner()
        );
        move_to(
            account,
            Data {
                price_feeds_testnet: aave_data::v1_values::build_price_feeds_testnet(),
                price_feeds_mainnet: aave_data::v1_values::build_price_feeds_mainnet(),
                underlying_assets_testnet: aave_data::v1_values::build_underlying_assets_testnet(),
                underlying_assets_mainnet: aave_data::v1_values::build_underlying_assets_mainnet(),
                reserves_config_testnet: aave_data::v1_values::build_reserve_config_testnet(),
                reserves_config_mainnet: aave_data::v1_values::build_reserve_config_mainnet(),
                interest_rate_strategy_testnet: aave_data::v1_values::build_interest_rate_strategy_testnet(),
                interest_rate_strategy_mainnet: aave_data::v1_values::build_interest_rate_strategy_mainnet(),
                emodes_testnet: aave_data::v1_values::build_emodes_testnet(),
                emodes_mainnet: aave_data::v1_values::build_emodes_mainnet()
            }
        );
    }

    public inline fun get_atoken_name(underlying_asset_symbol: String): String {
        string_utils::format2(&b"{}_{}", ATOKEN_NAME_PREFIX, underlying_asset_symbol)
    }

    public inline fun get_atoken_symbol(underlying_asset_symbol: String): String {
        string_utils::format2(&b"{}{}", ATOKEN_SYMBOL_PREFIX, underlying_asset_symbol)
    }

    public inline fun get_vartoken_name(underlying_asset_symbol: String): String {
        string_utils::format2(&b"{}_{}", VARTOKEN_NAME_PREFIX, underlying_asset_symbol)
    }

    public inline fun get_vartoken_symbol(underlying_asset_symbol: String): String {
        string_utils::format2(&b"{}{}", VARTOKEN_SYMBOL_PREFIX, underlying_asset_symbol)
    }

    public inline fun get_asset_symbols_testnet(): &vector<string::String> acquires Data {
        &smart_table::keys(&borrow_global<Data>(@aave_pool).price_feeds_testnet)
    }

    public inline fun get_asset_symbols_mainnet(): &vector<string::String> acquires Data {
        &smart_table::keys(&borrow_global<Data>(@aave_pool).price_feeds_mainnet)
    }

    public inline fun get_price_feeds_tesnet():
        &smart_table::SmartTable<string::String, vector<u8>> acquires Data {
        &borrow_global<Data>(@aave_pool).price_feeds_testnet
    }

    public inline fun get_price_feeds_mainnet():
        &smart_table::SmartTable<string::String, vector<u8>> acquires Data {
        &borrow_global<Data>(@aave_pool).price_feeds_mainnet
    }

    public inline fun get_underlying_assets_testnet():
        &smart_table::SmartTable<string::String, address> acquires Data {
        &borrow_global<Data>(@aave_pool).underlying_assets_testnet
    }

    public inline fun get_underlying_assets_mainnet():
        &smart_table::SmartTable<string::String, address> acquires Data {
        &borrow_global<Data>(@aave_pool).underlying_assets_mainnet
    }

    public inline fun get_reserves_config_testnet():
        &smart_table::SmartTable<string::String, aave_data::v1_values::ReserveConfig> acquires Data {
        &borrow_global<Data>(@aave_pool).reserves_config_testnet
    }

    public inline fun get_reserves_config_mainnet():
        &smart_table::SmartTable<string::String, aave_data::v1_values::ReserveConfig> acquires Data {
        &borrow_global<Data>(@aave_pool).reserves_config_mainnet
    }

    public inline fun get_interest_rate_strategy_testnet():
        &smart_table::SmartTable<string::String, aave_data::v1_values::InterestRateStrategy> acquires Data {
        &borrow_global<Data>(@aave_pool).interest_rate_strategy_testnet
    }

    public inline fun get_interest_rate_strategy_mainnet():
        &smart_table::SmartTable<string::String, aave_data::v1_values::InterestRateStrategy> acquires Data {
        &borrow_global<Data>(@aave_pool).interest_rate_strategy_mainnet
    }

    public inline fun get_emodes_mainnet():
        &smart_table::SmartTable<u256, aave_data::v1_values::EmodeConfig> acquires Data {
        &borrow_global<Data>(@aave_pool).emodes_mainnet
    }

    public inline fun get_emodes_testnet():
        &smart_table::SmartTable<u256, aave_data::v1_values::EmodeConfig> acquires Data {
        &borrow_global<Data>(@aave_pool).emodes_testnet
    }
}
