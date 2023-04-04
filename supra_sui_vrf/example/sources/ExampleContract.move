module example::ExampleContract {
    use supra::SupraContract;
    use std::string::{Self, String};
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;
    use supra::SupraContract::{DkgState, Config};
    use sui::vec_map::{Self, VecMap};

    struct RandomNumberList has key {
        id: UID,
        random_numbers: VecMap<u64, vector<u64>>
    }

    fun init(ctx: &mut TxContext) {
        let random_numbers: RandomNumberList = RandomNumberList {
            id: object::new(ctx),
            random_numbers: vec_map::empty(),
        };
        transfer::share_object(random_numbers);
    }

    // sui client call --package {package_id} --module ExampleContract --function rng_request --gas-budget 9000 --args {object_id} {package_id} {supra_config_obj} 1 0
    public entry fun rng_request(random_number_list: &mut RandomNumberList, client_address: address, supra_config: &mut Config, rng_count: u8, client_seed: u64, ctx: &mut TxContext) {
        let callback_fn: String = string::utf8(b"ExampleContract::distribute"); // callback module + function name
        // let rng_count: u8 = 1; // how many random number you want to generate
        // let client_seed: u64 = 0; // client seed using as seed to generate random. if you don't want to use then just assign 0
        let num_confirmations: u64 = 1; // how many confirmation required for random number

        let client_obj_addr: address = object::uid_to_address(&random_number_list.id);
        SupraContract::rng_request(supra_config, client_address, callback_fn, rng_count, client_seed, num_confirmations, client_obj_addr, ctx);
    }

    public entry fun distribute(
        random_number_list: &mut RandomNumberList,
        dkg_state: &mut DkgState,
        nonce: u64,
        message: vector<u8>,
        signature: vector<u8>,
        rng_count: u8,
        client_seed: u64,
        ctx: &mut TxContext
    ) {
        let verified_num: vector<u64> = SupraContract::verify_callback(dkg_state, nonce, message, signature, rng_count, client_seed, ctx);

        if(!vec_map::contains(&random_number_list.random_numbers, &nonce)) {
            vec_map::insert(&mut random_number_list.random_numbers, nonce, verified_num);
        }
    }
}
