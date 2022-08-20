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
func fee_config(vault : felt, key : felt) -> (res : felt):
end

@storage_var
func vault_factory() -> (vaultFactoryAddress : felt):
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
        vault_factory_address: felt,
    ):
    vault_factory.write(vault_factory_address)
    return ()
end

#
#Getters
#

@view
func getFeeConfig{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt, key : felt) -> (fee_config : felt):
    let (fee_config_) = fee_config.read(fund, key)
    return (fee_config_)
end

@view
func getEntranceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt) -> (entrance_fee : felt):
    let (entrance_fee_) = fee_config.read(fund, FeeConfig.ENTRANCE_FEE)
    return (entrance_fee_)
end

@view
func getExitFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt) -> (exit_fee : felt):
    let (exit_fee_) = fee_config.read(fund, FeeConfig.EXIT_FEE)
    return (exit_fee_)
end

@view
func getPerformanceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt) -> (fee : felt):
    let (performance_fee_) = feeConfig.read(fund, FeeConfig.PERFORMANCE_FEE)
    return (performance_fee_)
end

@view
func getManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt) -> (fee : felt):
    let (management_fee_) = feeConfig.read(fund, FeeConfig.MANAGEMENT_FEE)
    return (management_fee_)
end

#Setters

@external
func setFeeConfig{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, key : felt, value : felt
):
    onlyVaultFactory()
    feeConfig.write(fund, key, value)
    return ()
end

@external
func setEntranceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(fund, FeeConfig.ENTRANCE_FEE, fee)
    return ()
end

@external
func setExitFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(fund, FeeConfig.EXIT_FEE, fee)
    return ()
end

@external
func setPerformanceFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(fund, FeeConfig.PERFORMANCE_FEE, fee)
    return ()
end

@external
func setManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, fee : felt
):
    onlyVaultFactory()
    feeConfig.write(fund, FeeConfig.MANAGEMENT_FEE, fee)
    return ()
end


