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
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy

from contracts.ERC721_Metadata_base import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

@storage_var
func Contract_URI(index: felt) -> (uri: felt) {
}

@storage_var
func Contract_uri_len_() -> (uri_len: felt) {
}

@storage_var
func next_token() -> (token_id: Uint256) {
}

@storage_var
func payment_token() -> (payment_token_address: felt) {
}

@storage_var
func recipient_address() -> (sale_recipient: felt) {
}

@storage_var
func nft_mint_price() -> (mint_price: Uint256) {
}

@storage_var
func owner_address() -> (owner_contract_address: felt) {
}

@storage_var
func max_supply() -> (supply: Uint256) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt,
    symbol: felt,
    owner_contract: felt,
    payment_token_address: felt,
    mint_price: Uint256,
    collection_number: Uint256,
    proxy_admin: felt,
) {
    ERC721.initializer(name, symbol);
    Proxy.initializer(proxy_admin);
    ERC721Enumerable.initializer();
    ERC721_Metadata_initializer();
    Ownable.initializer(owner_contract);
    owner_address.write(owner_contract);
    recipient_address.write(owner_contract);

    nft_mint_price.write(value=mint_price);
    next_token.write(Uint256(1, 0));
    call_once.write(1);
    payment_token.write(value=payment_token_address);
    max_supply.write(collection_number);

    return ();
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    // let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
    // return (token_uri_len=token_uri_len, token_uri=token_uri);
    let (uri_len: felt, uri: felt*) = getContractURI();
    return (token_uri_len=uri_len, token_uri=uri);
}

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply,);
}

@view
func maxSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    maxSupply: Uint256
) {
    let (maxSupply: Uint256) = max_supply.read();
    return (maxSupply,);
}

@view
func owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    owner_contract_address: felt
) {
    let (owner_contract_address: felt) = owner_address.read();
    return (owner_contract_address,);
}

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId,);
}

@view
func tokenOfOwnerByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func contractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    uri_len: felt, uri: felt*
) {
    let (uri_len: felt, uri: felt*) = getContractURI();
    return (uri_len=uri_len, uri=uri);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ReentrancyGuard._start();
    ERC721.approve(to, tokenId);
    ReentrancyGuard._end();
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ReentrancyGuard._start();
    ERC721.set_approval_for_all(operator, approved);
    ReentrancyGuard._end();
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ReentrancyGuard._start();
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    ReentrancyGuard._end();
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ReentrancyGuard._start();
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    ReentrancyGuard._end();
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    ReentrancyGuard._start();
    let (caller_address) = get_caller_address();
    let (supply: Uint256) = totalSupply();
    let (max_supply: Uint256) = maxSupply();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(1, 0);
    let (is_lt) = uint256_lt(supply, max_supply);
    with_attr error_message("Max Supply Reached") {
        assert is_lt = 1;
    }

    // Token Payment
    let (token_address: felt) = payment_token.read();
    let (sale_recipient: felt) = recipient_address.read();
    let (mint_price: Uint256) = nft_mint_price.read();
    let (res) = IERC20.transferFrom(
        contract_address=token_address,
        sender=caller_address,
        recipient=sale_recipient,
        amount=mint_price,
    );
    with_attr error_message("Token transfer failed!") {
        assert res = 1;
    }

    // Mint
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(caller_address, tokenId);
    let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    next_token.write(next_tokenId);

    ReentrancyGuard._end();
    return ();
}

@external
func permissionedMint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    recipient: felt
) {
    alloc_locals;
    ReentrancyGuard._start();
    Ownable.assert_only_owner();

    // Mint
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(recipient, tokenId);
    let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    next_token.write(next_tokenId);

    ReentrancyGuard._end();
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ReentrancyGuard._start();
    ERC721.assert_only_token_owner(tokenId);
    ERC721Enumerable._burn(tokenId);
    ReentrancyGuard._end();
    return ();
}

// @external
// func setBaseURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
//     base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt
// ) {
//     alloc_locals;
//     ReentrancyGuard._start();
//     Ownable.assert_only_owner();
//     ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);
//     ReentrancyGuard._end();
//     return ();
//     alloc_locals;
//     ReentrancyGuard._start();
//     Ownable.assert_only_owner();
//     Contract_uri_len_.write(contractURI_len);
//     local uri_index = 0;
//     _storeContractRecursiveURI(contractURI_len, contractURI, uri_index);
//     ReentrancyGuard._end();
//     return ();
// }

@external
func setContractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    contractURI_len: felt, contractURI: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();
    Ownable.assert_only_owner();
    Contract_uri_len_.write(contractURI_len);
    local uri_index = 0;
    _storeContractRecursiveURI(contractURI_len, contractURI, uri_index);
    ReentrancyGuard._end();
    return ();
}

func _storeContractRecursiveURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    len: felt, _uri: felt*, index: felt
) {
    if (index == len) {
        return ();
    }
    with_attr error_message("URI Empty") {
        assert_not_zero(_uri[index]);
    }
    Contract_URI.write(index, _uri[index]);
    _storeContractRecursiveURI(len=len, _uri=_uri, index=index + 1);
    return ();
}

func getContractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    uri_len: felt, uri: felt*
) {
    alloc_locals;
    let (contractURI: felt*) = alloc();
    let (contractURI_len: felt) = Contract_uri_len_.read();
    local index = 0;
    _getContractURI(contractURI_len, contractURI, index);
    return (uri_len=contractURI_len, uri=contractURI);
}

func _getContractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    uri_len: felt, uri: felt*, index: felt
) {
    if (index == uri_len) {
        return ();
    }
    let (base) = Contract_URI.read(index);
    assert [uri] = base;
    _getContractURI(uri_len=uri_len, uri=uri + 1, index=index + 1);
    return ();
}

@external
func changeOwner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(owner: felt) {
    alloc_locals;
    ReentrancyGuard._start();
    Proxy.assert_only_admin();

    owner_address.write(owner);

    ReentrancyGuard._end();
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) -> () {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}
