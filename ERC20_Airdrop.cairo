%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_check,
    uint256_add,
)
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.memcpy import memcpy

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.access.ownable.library import Ownable

from contracts.utils.merkle import merkle_verify

@storage_var
func whitelist_has_claimed(leaf: felt) -> (whitelist_claimed: felt) {
}

@storage_var
func max_supply() -> (supply: Uint256) {
}

@storage_var
func eth_token_address() -> (eth_address: felt) {
}

@storage_var
func airdrop_token_address() -> (token_address: felt) {
}

@storage_var
func recipient_address() -> (sale_recipient: felt) {
}

@storage_var
func whitelist_max_supply() -> (whitelist_supply: Uint256) {
}

@storage_var
func whitelist_price() -> (whitelist_price_amount: Uint256) {
}

@storage_var
func airdrop_price() -> (airdrop_price_amount: Uint256) {
}

@storage_var
func whitelist_merkle_root() -> (whitelist_root: felt) {
}

@storage_var
func owner_address() -> (owner_contract_address: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner_contract: felt,
    whitelist_number_limit: Uint256,
    whitelist_root: felt,
    // whitelist_mint_price: Uint256,
    // eth_contract_address: felt,
    // sale_recipient_address: felt,
    airdrop_contract_address: felt,
    airdrop_amount: Uint256,
) {
    Ownable.initializer(owner_contract);
    max_supply.write(whitelist_number_limit);

    whitelist_max_supply.write(whitelist_number_limit);
    // whitelist_price.write(whitelist_mint_price);
    whitelist_merkle_root.write(value=whitelist_root);

    // eth_token_address.write(eth_contract_address);
    airdrop_token_address.write(airdrop_contract_address);
    airdrop_price.write(airdrop_amount);
    // recipient_address.write(sale_recipient_address);
    owner_address.write(owner_contract);

    return ();
}

@view
func maxSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    maxSupply: Uint256
) {
    let (maxSupply: Uint256) = max_supply.read();
    return (maxSupply,);
}

@view
func whitelistMaxSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    whitelist_supply: Uint256
) {
    let (whitelist_supply: Uint256) = whitelist_max_supply.read();
    return (whitelist_supply,);
}

@external
func whitelist_claim{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    proof_len: felt, proof: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();
    let (caller_address) = get_caller_address();
    let (whitelist_max_supply: Uint256) = whitelistMaxSupply();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(1, 0);
    let (leaf) = hash2{hash_ptr=pedersen_ptr}(caller_address, amount_hash);
    let (whitelist_claimed) = whitelist_has_claimed.read(leaf);
    with_attr error_message("Already Claimed") {
        assert whitelist_claimed = 0;
    }
    let (whitelist_root) = whitelist_merkle_root.read();
    local root_loc = whitelist_root;
    let (proof_valid) = merkle_verify(leaf, whitelist_root, proof_len, proof);
    with_attr error_message("Proof not valid") {
        assert proof_valid = 1;
    }

        // // ETH Payment
    // let (eth_address: felt) = eth_token_address.read();
    // let (sale_recipient: felt) = recipient_address.read();
    // let (whitelist_price_amount: Uint256) = whitelist_price.read();
    // let (res) = IERC20.transferFrom(
    //     contract_address=eth_address,
    //     sender=caller_address,
    //     recipient=sale_recipient,
    //     amount=whitelist_price_amount,
    // );
    // with_attr error_message("ETH transfer failed!") {
    //     assert res = 1;
    // }

    // Transfer Token
    let (token_airdrop_address: felt) = airdrop_token_address.read();
    let (airdrop_amount: Uint256) = airdrop_price.read();
    let (ress) = IERC20.transfer(
        contract_address=token_airdrop_address, recipient=caller_address, amount=airdrop_amount
    );
    with_attr error_message("Airdrop token transfer failed!") {
        assert ress = 1;
    }

    // Write mint record to has_claimed
    whitelist_has_claimed.write(leaf, 1);

    ReentrancyGuard._end();
    return ();
}

// TODO
// mint the rest back to me

@external
func claim_back{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(claimBackAmount: Uint256) {
    alloc_locals;
    ReentrancyGuard._start();
    Ownable.assert_only_owner();

    let (caller_address) = get_caller_address();

    // Transfer airdrop
    let (token_airdrop_address: felt) = airdrop_token_address.read();
    let (ress) = IERC20.transfer(
        contract_address=token_airdrop_address, recipient=caller_address, amount=claimBackAmount
    );
    with_attr error_message("Airdrop token transfer failed!") {
        assert ress = 1;
    }
    ReentrancyGuard._end();
    return ();
}
