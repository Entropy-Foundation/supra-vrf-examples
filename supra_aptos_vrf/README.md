## Supra Aptos VRF Developer Guide

This guide describes the process to access the Supra Verifiable Random Function (VRF). All VRF requester smart contracts will be interacting with the SupraContract to request and receive randomness. Please refer to the Network Addresses page for the address details of the SupraContract.

Following are the steps which a requester contract will have to follow in order to use the VRF service.

### Step 1: Create the SupraContract framework

Add the following code to the Aptos Move Smart Contract that requester contract wish to retrieve an random number

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

```

`vrf-framework/Move.toml`
```toml
[package]
name = 'supraContract'
version = '1.0.0'

[addresses]
supra = "36b67d62112127f2125f2f2820ccaed685242ea3f7f50bc12ab66c980da69288"

[dependencies]
AptosFramework = { git = "https://github.com/aptos-labs/aptos-core.git", subdir = "aptos-move/framework/aptos-framework/", rev = "6996b6ddf9b8ab96cb9843e420ea6a791ea6bd9e" }
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

- **_sender** - as an signer parameter, here the requester contract will have to pass his own signature.

- **_callback_fn** - a string parameter, here the requester contract will have to pass the function name which will receive the callback i.e., a random number from the SupraContract. The function signature should be in the form of the module_name::function_name following the parameters it accepts. We will see an example later in the document.

- **_rng_count** - an integer parameter, it is for the number of random numbers a particular requester wants to generate. Currently, we can generate a maximum of 255 random numbers per request.

- **_num_confirmations** - an integer parameter that specifies the number of block confirmations needed before supra VRF can generate the random number.

- **_client_seed** - an optional integer parameter that could be provided by the client (defaults to 0). This is for additional unpredictability. The source of the seed can be a UUID of 64 bits. This can also be from a centralized source.


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
```

## Example Implementation​
Please find below an example implementation of Supra Aptos VRF. More examples can be found in thi Github repo.

In the example below,

The function **rng_request** is using the VRF service by calling the rng_request function of the SupraContract.

Then the callback function returns the signature and all other required parameters.

Then call **verify_callback** function of the SupraContract and get the random number list.

```rs
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

```

To call rng_request function as below formate :
```cmd
aptos move run --function-id default::ExampleContract::rng_request --args u8:{rng_count} u64:{client_seed}
```

```cmd
aptos move run --function-id default::ExampleContract::rng_request --args u8:1 u64:10
```