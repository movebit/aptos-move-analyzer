// test_link_call
//# publish
module 0x42::ReceiverStyleCall3 {
    use Symbols::M1;
    use Symbols::M2::{Self, SomeOtherStruct, some_other_struct, multi_arg};

    struct S has drop { x: u64 }

    fun plus_one<T>(self: &mut S): S {
        self.x = self.x + 1;
        S { x: self.x }
    }

    fun plus_two<T>(self: &mut S): S {
        self.x = self.x + 2;
        S { x: self.x }
    }

    fun plus_three<T>(self: &mut S): S {
        self.x = self.x + 3;
        S { x: self.x }
    }

    fun test_link_call(s: S) {
        let p1m = &mut s;
        let p2m = p1m.plus_one().plus_two().plus_three().plus_one().plus_two().plus_three().plus_one().plus_two().plus_three().plus_one().plus_two().plus_three();
        let p3m = p1m.plus_one<u32>().plus_three<u64>();
    }
}

//# run 0x42::ReceiverStyleCall3::test
