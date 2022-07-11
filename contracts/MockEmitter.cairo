# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

#
# Events
#

# createVault event
@event
func CreateVault():
end

#
# External
#

@external
func createVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # emit event
    CreateVault.emit()

    return ()
end
