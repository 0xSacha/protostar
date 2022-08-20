%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import (
    alloc,
)
struct MaxMin:
    member max: Uint256
    member min: Uint256
end

struct integration:
    member contract : felt
    member selector : felt
end


## STORAGE

@storage_var
func vault_factory() -> (vault_factory : felt):
end

@storage_var
func is_public(vault: felt) -> (is_public : felt):
end

@storage_var
func id_to_allowed_depositor(vault : felt, id : felt) -> (id_to_allowed_depositor : felt):
end

@storage_var
func allowed_depositor_to_id(vault: felt, depositor:felt) -> (allowed_depositor_to_id : felt):
end

@storage_var
func allowed_depositors_length(vault: felt) -> (allowed_depositors_length : felt):
end

@storage_var
func is_allowed_depositor(vault: felt, depositor:felt) -> (is_allowed_depositor : felt):
end

@storage_var
func id_to_allowed_asset_to_reedem(vault: felt, id:felt) -> (allowed_asset_to_reedem : felt):
end

@storage_var
func allowed_asset_to_reedem_to_id(vault: felt, id:felt) -> (id : felt):
end

@storage_var
func allowed_assets_to_reedem_length(vault: felt) -> (allowed_asset_to_reedem_length : felt):
end

@storage_var
func is_allowed_asset_to_reedem(vault: felt, depositor:felt) -> (is_allowed_asset_to_reedem : felt):
end




#
# Modifiers
#

func only_vault_factory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vault_factory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("only_vault_factory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        vault_factory: felt,
    ):
    vault_factory.write(vault_factory)
    return ()
end


@view
func isPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt) -> (is_public : felt):
    let (is_public_) = is_public.read(_fund)
    return (is_public_)
end

@view
func isAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt, depositor : felt) -> (is_allowed_depositor : felt): 
    let (is_allowed_depositor_) = is_allowed_depositor.read(fund, depositor)
    return (is_allowed_depositor_)
end

@view
func allowedDepositors{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund:felt) -> (allowedDepositor_len: felt, allowedDepositor:felt*): 
    alloc_locals
    let (allowed_depositors_len:felt) = allowed_depositors_length.read(fund)
    let (local allowed_depositors : felt*) = alloc()
    complete_allowed_depositor_tab(fund, allowedDepositor_len, allowed_depositor, 0)
    return(allowedDepositor_len, allowedDepositor)
end


@view
func isAllowedAssetToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt, asset : felt) -> (is_allowed_asset_to_reedem : felt): 
    let (is_allowed_asset_to_reedem_) = is_allowed_asset_to_reedem.read(fund, asset)
    return (is_allowed_asset_to_reedem_)
end

@view
func allowedAssetsToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund:felt) -> (allowed_assets_to_reedem_len: felt, allowed_assets_to_reedem:felt*): 
    alloc_locals
    let (allowed_assets_to_reedem_len:felt) = allowed_assets_to_reedem_length.read(fund)
    let (local allowed_asset_to_reedem : felt*) = alloc()
    complete_allowed_assets_to_reedem_tab(fund, allowed_assets_to_reedem_len, allowed_assets_to_reedem, 0)
    return(allowed_asset_to_reedem_len, allowed_assets_to_reedem)
end


# Setters 

@external
func setAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund: felt, depositor: felt):
    only_vault_factory()
    let (is_allowed_depositor_:felt) = is_allowed_depositor.read(fund, depositor)
    if is_allowed_depositor_ == 1:
    return()
    else:
    is_allowed_depositor.write(fund, depositor, 1)
    let (allowed_depositors_len:felt) = allowed_depositors_length.read(_fund)
    id_to_allowed_depositor.write(fund, allowed_depositors_len, depositor)
    allowed_depositor_to_id.write(fund, depositor, allowed_depositors_len)
    allowed_depositors_len.write(_fund, allowed_depositors_len + 1)
    return ()
    end
end

@external
func setAllowedAssetToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund: felt, asset: felt):
    only_vault_factory()
    let (is_allowed_asset_to_reedem_:felt) = is_allowed_asset_to_reedem.read(fund, asset)
    if is_allowed_asset_to_reedem_ == 1:
    return()
    else:
    is_allowed_asset_to_reedem.write(fund, asset, 1)
    let (allowed_assets_to_reedem_len:felt) = allowed_assets_to_reedem_length.read(fund)
    id_to_allowed_asset_to_reedem.write(fund, allowed_assets_to_reedem_len, asset)
    allowed_asset_to_reedem_to_id.write(fund, asset, allowed_assets_to_reedem_len)
    allowed_asset_to_reedem_length.write(fund, allowed_assets_to_reedem_len + 1)
    return ()
    end
end


@external
func setIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund: felt, is_public: felt):
    only_vault_factory()
    is_public.write(fund, is_public)
    return ()
end

## INTERALS - HELPERS

func complete_allowed_depositors_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(fund:felt, allowed_depositors_len:felt, allowed_depositors:felt*, index:felt) -> ():
    if allowed_depositors_len == 0:
        return ()
    end
    let (depositor_:felt) = idToAllowedDepositor.read(fund, index)
    assert allowed_depositors[index] = depositor_
    return complete_allowed_depositors_tab(
        fund = fund,
        allowed_depositors_len=allowed_depositors_len - 1,
        allowed_depositors= allowed_depositors,
        index= index + 1,
    )
end

func complete_allowed_assets_to_reedem_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(fund:felt, allowed_assets_to_reedem_len:felt, allowed_assets_to_reedem:felt*, index:felt) -> ():
    if allowed_asset_to_reedem_len == 0:
        return ()
    end
    let (asset_:felt) = id_to_allowed_asset_to_reedem.read(_fund, index)
    assert allowed_assets_to_reedem[index] = asset_
    return complete_allowed_assets_to_reedem_tab(
        _fund = _fund,
        allowed_assets_to_reedem_len=allowed_assets_to_reedem_len - 1,
        allowed_assets_to_reedem= allowed_assets_to_reedem,
        index=index + 1,
    )
end


