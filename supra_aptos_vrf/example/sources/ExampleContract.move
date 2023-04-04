module example::ExampleContract {
    use supra::SupraContract;
    use std::string::{Self, String};
    use aptos_std::simple_map::{Self, SimpleMap};

    struct RandomNumberList has key, drop {
        random_numbers: SimpleMap<u64, vector<u64>>
    }

    fun init_module(sender: &signer) {
        create_empty_struct(sender);
    }

    fun create_empty_struct(sender: &signer) {
        if(exists<RandomNumberList>(@example)) {
            return
        };
        let random_num_map = RandomNumberList {
            random_numbers: simple_map::create<u64, vector<u64>>()
        };
        move_to(sender, random_num_map );
    }

    public entry fun rng_request(sender: &signer, rng_count: u8, client_seed: u64) {
        let callback_fn: String = string::utf8(b"ExampleContract::distribute");
        let num_confirmations: u64 = 1;
        SupraContract::rng_request(sender, callback_fn, rng_count, client_seed, num_confirmations);
    }

    public entry fun distribute(
        _sender: &signer,
        sequence_number: u64,
        message: vector<u8>,
        signature: vector<u8>,
        rng_count: u8,
        client_seed: u64,
    ) acquires RandomNumberList {
        if(!exists<RandomNumberList>(@example)) {
            return
        };
        let verified_num: vector<u64> = SupraContract::verify_callback(sequence_number, message, signature, rng_count, client_seed);
        let random_num_list = &mut borrow_global_mut<RandomNumberList>(@example).random_numbers;
        simple_map::add(random_num_list, sequence_number, verified_num);
    }
}
