// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TodoContractV1} from "./1-TodoV1.sol";

/// @custom:oz-upgrades-from TodoContractV1
contract TodoContractV2 is TodoContractV1 {
    /// @notice Permanently delete a pending todo
    /// @param _id The todo ID to delete
    function deleteTodo(uint256 _id) external exists(_id) onlyTodoOwner(_id) {
        Todo storage todo = todos[_id];
        require(todo.status == Status.Pending, "Todo is not pending");

        address todoOwner = todo.owner;

        // Swap-and-pop to remove _id from userTodoIds[owner]
        uint256[] storage ids = userTodoIds[todoOwner];
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == _id) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                break;
            }
        }

        delete todos[_id];

        emit TodoDeleted(_id, todoOwner);
    }
}
