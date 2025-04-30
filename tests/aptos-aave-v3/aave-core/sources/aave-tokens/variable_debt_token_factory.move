module aave_pool::variable_debt_token_factory {
    use std::option;
    use std::signer;
    use std::string;
    use std::string::String;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_std::string_utils::format2;
    use aptos_framework::event;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::Object;

    use aave_acl::acl_manage;
    use aave_config::error_config;

    use aave_pool::token_base;

    friend aave_pool::pool;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;

    #[test_only]
    friend aave_pool::variable_debt_token_factory_tests;

    #[test_only]
    friend aave_pool::pool_configurator_tests;
    #[test_only]
    friend aave_pool::pool_tests;

    const DEBT_TOKEN_REVISION: u256 = 0x1;

    #[event]
    /// @dev Emitted when a debt token is initialized
    /// @param underlying_asset The address of the underlying asset
    /// @param debt_token_decimals The decimals of the debt token
    /// @param debt_token_name The name of the debt token
    /// @param debt_token_symbol The symbol of the debt token
    struct Initialized has store, drop {
        underlying_asset: address,
        debt_token_decimals: u8,
        debt_token_name: String,
        debt_token_symbol: String
    }

    struct TokenData has store, copy, drop {
        underlying_asset: address
    }

    // variable debt token metadata_address => TokenData
    struct TokenMap has key {
        value: SmartTable<address, TokenData>,
        count: u256
    }

    fun init_module(signer: &signer) {
        token_base::only_token_admin(signer);
        move_to(
            signer,
            TokenMap {
                value: smart_table::new<address, TokenData>(),
                count: 0
            }
        )
    }

    fun assert_token_exists(metadata_address: address) acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        assert!(
            smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_not_exist()
        );
    }

    /// @notice Creates a new variable debt token.
    /// @dev Only callable by the pool module
    /// @param signer The signer of the caller
    /// @param name The name of the variable debt token
    /// @param symbol The symbol of the variable debt token
    /// @param decimals The decimals of the variable debt token
    /// @param icon_uri The icon URI of the variable debt token
    /// @param project_uri The project URI of the variable debt token
    /// @param underlying_asset The address of the underlying asset
    /// @return The address of the variable debt token
    public(friend) fun create_token(
        signer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        underlying_asset: address
    ): address acquires TokenMap {
        only_asset_listing_or_pool_admins(signer);

        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        validate_unique_token(token_map, name, symbol);

        let token_count = token_map.count + 1;
        let seed = *string::bytes(&format2(&b"{}_{}", symbol, token_count));
        let user_signer_addr = signer::address_of(signer);
        let metadata_address = object::create_object_address(&user_signer_addr, seed);

        assert!(
            !smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_already_exists()
        );

        let token_data = TokenData { underlying_asset };
        smart_table::add(&mut token_map.value, metadata_address, token_data);

        let constructor_ref = &object::create_named_object(signer, seed);
        // create token
        token_base::create_token(
            constructor_ref,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        event::emit(
            Initialized {
                underlying_asset,
                debt_token_decimals: decimals,
                debt_token_name: name,
                debt_token_symbol: symbol
            }
        );

        metadata_address
    }

    /// @notice Mints debt token to the `on_behalf_of` address
    /// @dev Only callable by the borrow_logic module
    /// @param caller The address receiving the borrowed underlying, being the delegatee in case
    /// of credit delegate, or same as `on_behalf_of` otherwise
    /// @param on_behalf_of The address receiving the debt tokens
    /// @param amount The amount of debt being minted
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the metadata object
    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);

        token_base::mint_scaled(
            caller,
            on_behalf_of,
            amount,
            index,
            metadata_address
        );
    }

    /// @notice Burns user variable debt
    /// @dev Only callable by the borrow_logic and liquidation_logic module
    /// @dev In some instances, a burn transaction will emit a mint event
    /// if the amount to burn is less than the interest that the user accrued
    /// @param from The address from which the debt will be burned
    /// @param amount The amount getting burned
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the metadata object
    public(friend) fun burn(
        from: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);

        token_base::burn_scaled(from, @0x0, amount, index, metadata_address);
    }

    public fun get_token_data(metadata_address: address): TokenData acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        assert!(
            smart_table::contains(&token_map.value, metadata_address),
            error_config::get_etoken_not_exist()
        );

        *smart_table::borrow(&token_map.value, metadata_address)
    }

    #[view]
    public fun get_revision(): u256 {
        DEBT_TOKEN_REVISION
    }

    #[view]
    /// @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
    /// @param metadata_address The address of the metadata object
    /// @return The address of the underlying asset
    public fun get_underlying_asset_address(metadata_address: address): address acquires TokenMap {
        let token_data = get_token_data(metadata_address);
        token_data.underlying_asset
    }

    #[view]
    /// @notice Returns last index interest was accrued to the user's balance
    /// @param user The address of the user
    /// @param metadata_address The address of the variable debt token
    /// @return The last index interest was accrued to the user's balance, expressed in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 {
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user.
    /// @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
    /// at the moment of the update
    /// @param owner The user whose balance is calculated
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 {
        token_base::scaled_balance_of(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled total supply
    public fun scaled_total_supply(metadata_address: address): u256 {
        token_base::scaled_total_supply(metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user and the scaled total supply.
    /// @param owner The address of the user
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled balance of the user
    /// @return The scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) {
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
    }

    #[view]
    /// Get the name of the fungible asset from the `metadata` object.
    public fun name(metadata_address: address): String {
        token_base::name(metadata_address)
    }

    #[view]
    /// Get the symbol of the fungible asset from the `metadata` object.
    public fun symbol(metadata_address: address): String {
        token_base::symbol(metadata_address)
    }

    #[view]
    /// Get the decimals from the `metadata` object.
    public fun decimals(metadata_address: address): u8 {
        token_base::decimals(metadata_address)
    }

    /// @notice Validates that the variable debt token name and symbol are unique
    /// @param token_map The variable debt token token map
    /// @param name The name of the variable debt token
    /// @param symbol The symbol of the variable debt token
    fun validate_unique_token(
        token_map: &TokenMap, name: String, symbol: String
    ) {
        smart_table::for_each_ref(
            &token_map.value,
            |metadata_address, _token_data| {
                let asset_name = name(*metadata_address);
                let asset_symbol = symbol(*metadata_address);
                assert!(
                    asset_name != name, error_config::get_etoken_name_already_exist()
                );
                assert!(
                    asset_symbol != symbol,
                    error_config::get_etoken_symbol_already_exist()
                );
            }
        );
    }

    /// @notice Drops the variable debt token associated data
    /// @dev Only callable by the pool module
    /// @param metadata_address The address of the metadata object
    public(friend) fun drop_token(metadata_address: address) acquires TokenMap {
        assert_token_exists(metadata_address);

        // Remove metadata_address from variable debt token map
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        smart_table::remove(&mut token_map.value, metadata_address);

        // Remove metadata_address from token_base module's token map
        token_base::drop_token(metadata_address);
    }

    fun only_asset_listing_or_pool_admins(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_asset_listing_admin(account_address)
                || acl_manage::is_pool_admin(account_address),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        )
    }

    #[view]
    public fun token_address(owner: address, symbol: String): address acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);

        let address_found = option::none<address>();
        smart_table::for_each_ref(
            &token_map.value,
            |metadata_address, _token_data| {
                let token_metadata =
                    object::address_to_object<Metadata>(*metadata_address);
                if (object::owner(token_metadata) == owner) {
                    let token_symbol = fungible_asset::symbol(token_metadata);
                    if (token_symbol == symbol) {
                        if (std::option::is_some(&address_found)) {
                            abort(error_config::get_etoken_already_exists())
                        };
                        std::option::fill(&mut address_found, *metadata_address);
                    };
                }
            }
        );

        if (std::option::is_none(&address_found)) {
            abort(error_config::get_etoken_not_exist())
        };
        std::option::destroy_some(address_found)
    }

    #[view]
    public fun asset_metadata(owner: address, symbol: String): Object<Metadata> acquires TokenMap {
        object::address_to_object<Metadata>(token_address(owner, symbol))
    }

    #[test_only]
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }
}
