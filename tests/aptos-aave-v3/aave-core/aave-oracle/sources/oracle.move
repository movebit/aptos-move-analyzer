module aave_oracle::oracle {
    use std::vector;
    use aave_oracle::oracle_base::Self;
    use data_feeds::router::{Self as chainlink_router};
    use data_feeds::registry::{Self as chainlink};

    // friends
    friend aave_oracle::price_cap_stable_adapter;

    fun init_module(account: &signer) {
        oracle_base::init_oracle(account);
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        init_module(account);
    }

    #[view]
    public fun get_asset_price(asset: address): u256 {
        let feed_id = oracle_base::assert_asset_feed_id_exists(asset);
        let benchmarks =
            chainlink_router::get_benchmarks(
                &oracle_base::get_resource_account_signer(),
                vector[feed_id],
                vector[]
            );
        oracle_base::assert_benchmarks_match_assets(vector::length(&benchmarks), 1);
        let benchmark = vector::borrow(&benchmarks, 0);
        chainlink::get_benchmark_value(benchmark)
    }

    #[view]
    public fun get_assets_prices(assets: vector<address>): vector<u256> {
        let feed_ids: vector<vector<u8>> = vector[];
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let feed_id = oracle_base::assert_asset_feed_id_exists(asset);
            vector::push_back(&mut feed_ids, feed_id);
        };
        let benchmarks =
            chainlink_router::get_benchmarks(
                &oracle_base::get_resource_account_signer(), feed_ids, vector[]
            );
        oracle_base::assert_benchmarks_match_assets(
            vector::length(&benchmarks), vector::length(&assets)
        );
        let prices = vector::map_ref<chainlink::Benchmark, u256>(
            &benchmarks,
            |benchmark| { chainlink::get_benchmark_value(benchmark) }
        );
        prices
    }

    public entry fun set_asset_feed_id(
        account: &signer, asset: address, feed_id: vector<u8>
    ) {
        oracle_base::only_risk_or_pool_admin(account);
        oracle_base::set_asset_feed_id(asset, feed_id);
        oracle_base::emit_asset_price_feed_updated(asset, feed_id);
    }

    public entry fun batch_set_asset_feed_ids(
        account: &signer, assets: vector<address>, feed_ids: vector<vector<u8>>
    ) {
        oracle_base::only_risk_or_pool_admin(account);
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let feed_id = *vector::borrow(&feed_ids, i);
            oracle_base::set_asset_feed_id(asset, feed_id);
            oracle_base::emit_asset_price_feed_updated(asset, feed_id);
        };
    }

    public entry fun remove_asset_feed_id(account: &signer, asset: address) {
        oracle_base::only_risk_or_pool_admin(account);
        let feed_id = oracle_base::assert_asset_feed_id_exists(asset);
        oracle_base::remove_feed_id(asset);
        oracle_base::emit_asset_price_feed_removed(asset, feed_id);
    }

    public entry fun batch_remove_asset_feed_ids(
        account: &signer, assets: vector<address>
    ) {
        oracle_base::only_risk_or_pool_admin(account);
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let feed_id = oracle_base::assert_asset_feed_id_exists(asset);
            oracle_base::remove_feed_id(asset);
            oracle_base::emit_asset_price_feed_removed(asset, feed_id);
        };
    }
}
