module example::example {

    use std::error;
    use std::signer;
    use std::string;

    use aptos_std::table;
    use supra_framework::account;
    use supra_framework::account::SignerCapability;
    use supra_framework::supra_account;
    use supra_addr::supra_vrf;
    use supra_addr::deposit;

    const REOSOURCE_ADDRESS_SEED: vector<u8> = b"example::ResourceSignerCap";

    /// Store Resource signer cap which is used as owner account which we ask supra admin to whitelist
    struct ResourceSignerCap has key {
        signer_cap : SignerCapability
    }

    /// Generated new random number will be store here
    struct RandomNumberList has key {
        random_numbers: table::Table<u64, vector<u256>>
    }

    /// Init function which is auto run at the time of contract deployment at once
    fun init_module(sender: &signer) {
        let (_resource_signer, signer_cap) = account::create_resource_account(sender, REOSOURCE_ADDRESS_SEED);
        move_to(sender, ResourceSignerCap { signer_cap });
        move_to(sender, RandomNumberList { random_numbers: table::new() });
    }

    #[view]
    public fun get_resource_address(): address {
        account::create_resource_address(&@example, REOSOURCE_ADDRESS_SEED)
    }

    /// Whitelist example contract address to supra
    public entry fun add_contract_to_whitelist(sender: &signer) acquires ResourceSignerCap {
        assert!(@example == signer::address_of(sender), error::permission_denied(1));

        let resource_signer_cap = borrow_global<ResourceSignerCap>(@example);
        let resource_signer = account::create_signer_with_capability(&resource_signer_cap.signer_cap);
        deposit::add_contract_to_whitelist(&resource_signer, @example)
    }

    /// Deposit fund to supra deposit module
    public entry fun deposit_fund(sender: &signer, amount: u64) acquires ResourceSignerCap {
        let resource_signer_cap = borrow_global<ResourceSignerCap>(@example);
        let resource_signer = account::create_signer_with_capability(&resource_signer_cap.signer_cap);
        let resource_address = get_resource_address();
        // First I need to transfer amount to resource account, and the then from this wallet I will transfer it to supra deposit fund
        supra_account::transfer(sender, resource_address, amount);
        deposit::deposit_fund(&resource_signer, amount);
    }

    /// Make request
    public entry fun rng_request(
        _sender: &signer,
        rng_count: u8,
        client_seed: u64,
        num_confirmations: u64
    ) acquires RandomNumberList, ResourceSignerCap {

        let resource_signer_cap = borrow_global<ResourceSignerCap>(@example);
        let resource_signer = account::create_signer_with_capability(&resource_signer_cap.signer_cap);

        let callback_address = @example;
        let callback_module = string::utf8(b"example");
        let callback_function = string::utf8(b"distribute");
        let nonce = supra_vrf::rng_request(
            &resource_signer,
            callback_address,
            callback_module,
            callback_function,
            rng_count,
            client_seed,
            num_confirmations
        );

        let random_num_list = &mut borrow_global_mut<RandomNumberList>(@example).random_numbers;
        table::add(random_num_list, nonce, vector[]);
    }

    /// Handle callback
    public entry fun distribute(
        nonce: u64,
        message: vector<u8>,
        signature: vector<u8>,
        caller_address: address,
        rng_count: u8,
        client_seed: u64,
    ) acquires RandomNumberList {
        let verified_num: vector<u256> = supra_vrf::verify_callback(
            nonce,
            message,
            signature,
            caller_address,
            rng_count,
            client_seed
        );
        let random_num_list = &mut borrow_global_mut<RandomNumberList>(@example).random_numbers;
        let random_num = table::borrow_mut(random_num_list, nonce);
        *random_num = verified_num;
    }

    /// Get generated random number
    #[view]
    public fun get_rng_number_from_nonce(nonce: u64): vector<u256> acquires RandomNumberList {
        let random_num_list = borrow_global<RandomNumberList>(@example);
        *table::borrow(&random_num_list.random_numbers, nonce)
    }
}
