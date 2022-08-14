# Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IFeeManager import FeeConfig



@storage_var
func feeConfig(vault : felt, key : felt) -> (res : felt):
end

@storage_var
func vaultFactory() -> (vaultFactoryAddress : felt):
end


#
# Modifiers
#

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
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
        _vaultFactory: felt,
    ):
    vaultFactory.write(_vaultFactory)
    return ()
end

#
#Getters
#

@view
func getFeeConfig{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, key : felt
) -> (value : felt):
    let (value) = feeConfig.read(vault, key)
    return (value=value)
end


@view
func getEntranceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = feeConfig.read(vault, FeeConfig.ENTRANCE_FEE)
    return (fee=fee)
end

@view
func isEntranceFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = feeConfig.read(vault, FeeConfig.ENTRANCE_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

@view
func getExitFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = feeConfig.read(vault, FeeConfig.EXIT_FEE)
    return (fee=fee)
end

@view
func isExitFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = feeConfig.read(vault, FeeConfig.EXIT_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

@view
func getPerformanceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = feeConfig.read(vault, FeeConfig.PERFORMANCE_FEE)
    return (fee=fee)
end

@view
func isPerformanceFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = feeConfig.read(vault, FeeConfig.PERFORMANCE_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

@view
func getManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (fee : felt):
    let (fee) = feeConfig.read(vault, FeeConfig.MANAGEMENT_FEE)
    return (fee=fee)
end

@view
func isManagementFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt
) -> (is_enabled : felt):
    let (is_enabled) = feeConfig.read(vault, FeeConfig.MANAGEMENT_FEE_ENABLED)
    return (is_enabled=is_enabled)
end

#Setters

@external
func setFeeConfig{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, key : felt, value : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, key, value)
    return ()
end


@external
func setEntranceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.ENTRANCE_FEE, fee)
    return ()
end

@external
func setEntranceFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.ENTRANCE_FEE_ENABLED, is_enabled)
    return ()
end

@external
func setExitFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.EXIT_FEE, fee)
    return ()
end

@external
func setExitFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.EXIT_FEE_ENABLED, is_enabled)
    return ()
end

@external
func setPerformanceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.PERFORMANCE_FEE, fee)
    return ()
end

@external
func setPerformanceFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.PERFORMANCE_FEE_ENABLED, is_enabled)
    return ()
end

@external
func setManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.MANAGEMENT_FEE, fee)
    return ()
end

@external
func setManagementFeeEnabled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    vault : felt, is_enabled : felt
):
    onlyVaultFactory()
    feeConfig.write(vault, FeeConfig.MANAGEMENT_FEE_ENABLED, is_enabled)
    return ()
end

