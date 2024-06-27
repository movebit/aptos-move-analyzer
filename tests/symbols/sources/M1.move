module Symbols::M1 {
    use Symbols::M2::{Self, SomeOtherStruct, some_other_struct, multi_arg};

    struct SomeStruct has key, drop, store {
        some_field: u64,
        some_field2: u64,
    }

    const SOME_CONST: u64 = 42;


    fun unpack(s: SomeStruct): u64 {
        let SomeStruct { some_field: value, some_field2: value2 } = s;
        value
    }

    fun cp(value: u64): u64 {
        let ret = value;
        ret
    }

    fun pack(): SomeStruct {
        let ret = SomeStruct { some_field: SOME_CONST, some_field2: 1 };
        ret
    }

    fun other_mod_struct(): SomeOtherStruct {
        some_other_struct(SOME_CONST)
    }

    

    fun other_mod_struct_import(): SomeOtherStruct {
        some_other_struct(6);
        some_other_struct(7)
    }

    fun acq(addr: address): u64 acquires SomeStruct {
        let val = borrow_global<SomeStruct>(addr);
        val.some_field
    }

    fun multi_arg_call(): u64 {
        multi_arg(SOME_CONST, SOME_CONST)
    }

    fun vec(a:vector<SomeStruct>, b:vector<SomeOtherStruct>): vector<SomeStruct> {
        let s = SomeStruct{ some_field: 7, some_field2: 1  };
        let x = s.some_field2;
        a
    }

    fun unpack_no_assign(s: SomeStruct): u64 {
        let value: u64;
        let value2: u64;
        SomeStruct { some_field: value, some_field2: value2 } = s;
        value
    }

    fun mut(): u64 {
        let tmp = 7;
        let r = &mut tmp;
        *r = SOME_CONST;
        tmp
    }
}
