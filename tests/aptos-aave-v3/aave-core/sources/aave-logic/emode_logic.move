/// @title emode_logic module
/// @author Aave
/// @notice Implements the base logic for all the actions related to the eMode
module aave_pool::emode_logic {
    use std::signer;
    use std::string;
    use std::string::String;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;

    use aave_config::error_config;
    use aave_oracle::oracle;
    use aave_pool::pool;
    use aave_pool::validation_logic;

    friend aave_pool::pool_configurator;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;

    #[test_only]
    friend aave_pool::emode_logic_tests;
    #[test_only]
    friend aave_pool::supply_logic_tests;
    #[test_only]
    friend aave_pool::borrow_logic_tests;
    #[test_only]
    friend aave_pool::ui_pool_data_provider_v3;

    const EMPTY_STRING: vector<u8> = b"";

    #[event]
    /// @dev Emitted when the user selects a certain asset category for eMode
    /// @param user The address of the user
    /// @param category_id The category id
    struct UserEModeSet has store, drop {
        user: address,
        category_id: u8
    }

    struct EModeCategory has store, copy, drop {
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        /// each eMode category may or may not have a custom oracle to override the individual assets price oracles
        price_source: address,
        label: String
    }

    /// List of eMode categories as a map (emode_category_id => EModeCategory).
    struct EModeCategoryList has key {
        value: SmartTable<u8, EModeCategory>
    }

    /// Map of users address and their eMode category (user_address => emode_category_id)
    struct UsersEmodeCategory has key, store {
        value: SmartTable<address, u8>
    }

    /// @notice Initializes the eMode
    /// @dev Only callable by the pool_configurator module
    /// @param account The account signer of the caller
    public(friend) fun init_emode(account: &signer) {
        assert!(
            (signer::address_of(account) == @aave_pool),
            error_config::get_enot_pool_owner()
        );
        move_to(
            account,
            EModeCategoryList {
                value: smart_table::new<u8, EModeCategory>()
            }
        );
        move_to(
            account,
            UsersEmodeCategory {
                value: smart_table::new<address, u8>()
            }
        )
    }

    /// @notice Updates the user efficiency mode category
    /// @dev Will revert if user is borrowing non-compatible asset or change will drop HF < HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    /// @dev Emits the `UserEModeSet` event
    /// @param account The account signer of the caller
    /// @param category_id The state of all users efficiency mode category
    public entry fun set_user_emode(
        account: &signer, category_id: u8
    ) acquires UsersEmodeCategory, EModeCategoryList {
        //  validate set user emode
        let account_address = signer::address_of(account);
        let user_config_map = pool::get_user_configuration(account_address);
        let reserves_count = pool::get_reserves_count();
        let emode_configuration = get_emode_category_data(category_id);
        validation_logic::validate_set_user_emode(
            &user_config_map,
            reserves_count,
            category_id,
            emode_configuration.liquidation_threshold
        );

        let prev_category_id = get_user_emode(account_address);
        let user_emode_category = borrow_global_mut<UsersEmodeCategory>(@aave_pool);
        smart_table::upsert(&mut user_emode_category.value, account_address, category_id);
        let (emode_ltv, emode_liq_threshold, emode_asset_price) =
            get_emode_configuration(category_id);

        if (prev_category_id != 0) {
            validation_logic::validate_health_factor(
                &user_config_map,
                account_address,
                category_id,
                reserves_count,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price
            );
        };
        event::emit(UserEModeSet { user: account_address, category_id });
    }

    #[view]
    /// @notice Returns the eMode the user is using
    /// @param user The address of the user
    /// @return The eMode id
    public fun get_user_emode(user: address): u256 acquires UsersEmodeCategory {
        let user_emode_category = borrow_global<UsersEmodeCategory>(@aave_pool);
        if (!smart_table::contains(&user_emode_category.value, user)) {
            return 0
        };
        let user_emode = smart_table::borrow(&user_emode_category.value, user);
        (*user_emode as u256)
    }

    /// @notice Get the price source of the eMode category
    /// @param user_emode_category The user eMode category
    /// @return The price source of the eMode category
    public fun get_emode_e_mode_price_source(
        user_emode_category: u8
    ): address acquires EModeCategoryList {
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return @0x0
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        emode_category.price_source
    }

    /// @notice Gets the eMode configuration and calculates the eMode asset price if a custom oracle is configured
    /// @dev The eMode asset price returned is 0 if no oracle is specified
    /// @param user_emode_category The user eMode category
    /// @return The eMode ltv
    /// @return The eMode liquidation threshold
    /// @return The eMode asset price
    public fun get_emode_configuration(
        user_emode_category: u8
    ): (u256, u256, u256) acquires EModeCategoryList {
        let emode_asset_price = 0;
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return (0, 0, emode_asset_price)
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        let emode_price_source = emode_category.price_source;
        if (emode_price_source != @0x0) {
            // TODO Waiting for Chainlink oracle functionality
            emode_asset_price = oracle::get_asset_price(emode_price_source);
        };
        return ((emode_category.ltv as u256),
        (emode_category.liquidation_threshold as u256),
        emode_asset_price)
    }

    /// @notice Gets the eMode category label
    /// @param user_emode_category The user eMode category
    /// @return The label of the eMode category
    public fun get_emode_e_mode_label(user_emode_category: u8): String acquires EModeCategoryList {
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return string::utf8(EMPTY_STRING)
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        emode_category.label
    }

    /// @notice Gets the eMode category liquidation_bonus
    /// @param user_emode_category The user eMode category
    /// @return The liquidation bonus of the eMode category
    public fun get_emode_e_mode_liquidation_bonus(
        user_emode_category: u8
    ): u16 acquires EModeCategoryList {
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return 0
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        emode_category.liquidation_bonus
    }

    /// @notice Configures a new category for the eMode.
    /// @dev Only callable by the pool_configurator module
    /// @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
    /// The category 0 is reserved as it's the default for volatile assets
    /// @param id The id of the category
    /// @param ltv The loan to value ratio
    /// @param liquidation_threshold The liquidation threshold
    /// @param liquidation_bonus The liquidation bonus
    /// @param price_source The address of the oracle to override the individual assets price oracles
    /// @param label The label of the category
    public(friend) fun configure_emode_category(
        id: u8,
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        price_source: address,
        label: String
    ) acquires EModeCategoryList {
        assert!(id != 0, error_config::get_eemode_category_reserved());
        // Currently, custom oracle is not supported. Only a unified oracle is used. Therefore, the price_source is equal to @0x0
        price_source = @0x0;

        let emode_category_list = borrow_global_mut<EModeCategoryList>(@aave_pool);
        smart_table::upsert(
            &mut emode_category_list.value,
            id,
            EModeCategory {
                ltv,
                liquidation_threshold,
                liquidation_bonus,
                price_source,
                label
            }
        );
    }

    /// @notice Checks if eMode is active for a user and if yes, if the asset belongs to the eMode category chosen
    /// @param emode_user_category The user eMode category
    /// @param emode_asset_category The asset eMode category
    /// @return True if eMode is active and the asset belongs to the eMode category chosen by the user, false otherwise
    public fun is_in_emode_category(
        emode_user_category: u256, emode_asset_category: u256
    ): bool {
        emode_user_category != 0 && emode_asset_category == emode_user_category
    }

    #[view]
    /// @notice Returns the data of an eMode category
    /// @param id The id of the category
    /// @return The configuration data of the category
    public fun get_emode_category_data(id: u8): EModeCategory acquires EModeCategoryList {
        let emode_category_data = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_data.value, id)) {
            return EModeCategory {
                ltv: 0,
                liquidation_threshold: 0,
                liquidation_bonus: 0,
                // each eMode category may or may not have a custom oracle to override the individual assets price oracles
                price_source: @0x0,
                label: string::utf8(EMPTY_STRING)
            }
        };

        *smart_table::borrow<u8, EModeCategory>(&emode_category_data.value, id)
    }

    /// @notice Get the ltv of the eMode category
    /// @param emode_category The eMode category
    /// @return The ltv of the eMode category
    public fun get_emode_category_ltv(emode_category: &EModeCategory): u16 {
        emode_category.ltv
    }

    /// @notice Get the liquidation threshold of the eMode category
    /// @param emode_category The eMode category
    /// @return The liquidation threshold of the eMode category
    public fun get_emode_category_liquidation_threshold(
        emode_category: &EModeCategory
    ): u16 {
        emode_category.liquidation_threshold
    }

    /// @notice Get the liquidation bonus of the eMode category
    /// @param emode_category The eMode category
    /// @return The liquidation bonus of the eMode category
    public fun get_emode_category_liquidation_bonus(
        emode_category: &EModeCategory
    ): u16 {
        emode_category.liquidation_bonus
    }

    /// @notice Get the price source of the eMode category
    /// @param emode_category The eMode category
    /// @return The price source of the eMode category
    public fun get_emode_category_price_source(
        emode_category: &EModeCategory
    ): address {
        emode_category.price_source
    }

    /// @notice Get the label of the eMode category
    /// @param emode_category The eMode category
    /// @return The label of the eMode category
    public fun get_emode_category_label(emode_category: &EModeCategory): String {
        emode_category.label
    }
}
