## Supra SUI VRF Developer Guide

This guide describes the process to access the Supra Verifiable Random Function (VRF). All VRF requester smart contracts will be interacting with the SupraContract to request and receive randomness. Please refer to the Network Addresses page for the address details of the SupraContract.

Following are the steps which a requester contract will have to follow in order to use the VRF service.

### Step 1: Create the SupraContract framework

Add the following code to the Sui Move Smart Contract that requester contract wish to retrieve an random number

Directory tree vrf-framework

```
vrf-framework/
├── sources
    ├── SupraConract.move
├── Move.toml
```

`vrf-framework/sources/SupraContract.move`
```rs
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
```

`vrf-framework/Move.toml`
```toml
[package]
name = 'supraContract'
version = '1.0.0'

[addresses]
supra = "0xd1ac6f2a5945e0b4234a85b3471c8ad59eaef3b8" // get updated address from the above link

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework", rev = "devnet-0.19.0" }
```

This framework will help the requester contract interact with the SupraContract and through which the requester contract can use the VRF service.

Contracts that need random numbers should utilize the SupraContract. In order to do that, they Configure the supra address from the on-chain [address](https://supraoracles.com/docs/vrf1/network-addreses) of the SupraContract.


### Step 2: Configure the Supra Contract Address​

Import Below supra vrf-framework dependency in requester contract Move.toml file

```toml
[dependencies]
supraContract = { local = './../vrf-framework' }
```


### Step 3: Use the VRF service and request a Random Number​

In this step, we will use the “rng_request” function of the SupraContract to create a request for random numbers.

- **_config** - as object of supra::SupraContract::Config , We will see an example later. Pass Config Object as `0x4c902d87c40a2f15c32227bbb63673b484c5fc8e`

- **_caller_contract** - as a string parameter, here the requester contract will have to pass the callback contract address.

- **_callback_fn** - a string parameter, here the requester contract will have to pass the function name which will receive the callback i.e., a random number from the SupraContract. The function signature should be in the form of the module_name::function_name following the parameters it accepts. We will see an example later in the document.

- **_rng_count** - an integer parameter, it is for the number of random numbers a particular requester wants to generate. Currently, we can generate a maximum of 255 random numbers per request.

- **_num_confirmations** - an integer parameter that specifies the number of block confirmations needed before supra VRF can generate the random number.

- **_client_seed** - an optional integer parameter that could be provided by the client (defaults to 0). This is for additional unpredictability. The source of the seed can be a UUID of 64 bits. This can also be from a centralized source.

- **_client_obj_addr** - as object of requester contract contract struct, make sure this object is share_object. So when supra VRF callback it also gives the requester contract this object based on that requester contract can update its own data.

- **_ctx** - as &mut TxContext. rng_request generator information.

```rs
public entry fun rng_request(random_number_list: &mut RandomNumberList, client_address: address, supra_config: &mut Config, rng_count: u8, client_seed: u64, ctx: &mut TxContext) {

    let callback_fn: String = string::utf8(b"ExampleContract::distribute");
    let num_confirmations: u64 = 1;
    let client_obj_addr: address = object::uid_to_address(&random_number_list.id);
    SupraContract::rng_request(supra_config, client_address, callback_fn, rng_count, client_seed, num_confirmations, client_obj_addr, ctx);

}
```

### Step 4 - Define requester contract callback function
Requester contract callback functions should be defined as public entry functions and will mainly take 8 parameters. Below are the list of parameters.
In the request contract callback function they need to call SupraContract::verify_callback function to make sure that the callback signature which they received is valid and then the requester contract gets the random number list.

```rs
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
```

## Example Implementation​
Please find below an example implementation of Supra SUI VRF. More examples can be found in thi Github repo.

In the example below,

The function **rng_request** is using the VRF service by calling the rng_request function of the SupraContract.

Then the callback function returns the signature and all other required parameters.

Then call **verify_callback** function of the SupraContract and get the random number list.

```rs
module example::ExampleContract {
    use supra::SupraContract::{Self, DkgState, Config};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::object::{Self, UID};

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

    public entry fun rng_request(random_number_list: &mut RandomNumberList, client_address: address, supra_config: &mut Config, rng_count: u8, client_seed: u64, ctx: &mut TxContext) {

        let callback_fn: String = string::utf8(b"ExampleContract::distribute");
        let num_confirmations: u64 = 1;
        let client_obj_addr: address = object::uid_to_address(&random_number_list.id);
        SupraContract::rng_request(supra_config, client_address, callback_fn, rng_count, client_seed, num_confirmations, client_obj_addr, ctx);

    }
}
```

To call rng_request function as below formate :
```cmd
sui client call --package {package_id} --module ExampleContract --function rng_request --gas-budget 9000 --args {object_id} {package_id} {supra_config_obj} {u8:rng_count} {u64:client_seed}
```

```cmd
sui client call --package 0x1 --module ExampleContract --function rng_request --gas-budget 9000 --args 0x2 0x1 0x4c902d87c40a2f15c32227bbb63673b484c5fc8e 1 0
```

`supra_config_obj = 0x4c902d87c40a2f15c32227bbb63673b484c5fc8e`
