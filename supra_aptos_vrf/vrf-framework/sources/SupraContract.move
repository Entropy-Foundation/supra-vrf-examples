module supra::SupraContract {
    use std::string::String;

    native public entry fun rng_request(
        _sender: &signer, // caller signer
        _callback_fn: String, // your callback "module::function" name
        _rng_count: u8, // how many random number you wants to generate
        _client_seed: u64, // using as seed to generate random. defualt pass "0", if you don't want to use
        _num_confirmations: u64, // how many confirmations you require for random number. default pass 1, if you don't want to use
    );

    native public fun verify_callback(
        _sequence_number: u64,
        _message: vector<u8>,
        _signature: vector<u8>,
        _rng_count: u8,
        _client_seed: u64,
    ): vector<u64>;

}
