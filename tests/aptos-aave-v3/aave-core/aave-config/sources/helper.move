module aave_config::helper {

    /// Get the result of bitwise negation
    public fun bitwise_negation(m: u256): u256 {
        let all_ones: u256 =
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        let negated_mask: u256 = m ^ all_ones;
        return negated_mask
    }

    #[test]
    fun test_bitwise_negation() {
        let ret =
            bitwise_negation(
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000
            );
        assert!(ret == 65535, 1);
    }
}
