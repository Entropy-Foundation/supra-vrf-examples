module supra::SupraContract {
    use std::string::String;
    use sui::object::UID;
    use sui::tx_context::TxContext;

    struct DkgState has key, store {
        id: UID,
        public_key: vector<u8>,
        owner: address,
    }

    struct Config has key {
        id: UID,
        nonce: u64,
        instance_id: u64,
    }

    native public entry fun rng_request(
        _config: &mut Config,
        _caller_contract: address,
        _callback_fn: String,
        _rng_count: u8,
        _client_seed: u64,
        _num_confirmations: u64,
        _client_obj_addr: address,
        _ctx: &mut TxContext
    );

    native public fun verify_callback(
        _dkg_state: &mut DkgState,
        _nonce: u64,
        _message: vector<u8>,
        _signature: vector<u8>,
        _rng_count: u8,
        _client_seed: u64,
        _ctx: &mut TxContext,
    ): vector<u64>;

}
