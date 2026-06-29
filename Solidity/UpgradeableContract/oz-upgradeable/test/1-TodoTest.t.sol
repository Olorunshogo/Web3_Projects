// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {TodoContractV1} from "../src/1-TodoV1.sol";
import {TodoContractV2} from "../src/1-TodoV2.sol";

contract TodoTest is Test {
    address owner;
    address addr1;
    address proxy;
    TodoContractV1 todo;

    function setUp() public {
        owner = address(this);
        addr1 = makeAddr("addr1");

        address impl = address(new TodoContractV1());
        proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(TodoContractV1.initialize, (owner))
        );
        todo = TodoContractV1(proxy);
    }

    // =========================================================
    // 19.1 — V1 Unit Tests
    // =========================================================

    // --- createTodo ---

    function test_CreateTodo_EmitsAndStoresCorrectly() public {
        uint256 deadline = block.timestamp + 1000;

        vm.expectEmit(true, true, false, true);
        emit TodoContractV1.CreatedTodo(1, owner, "My first task", deadline);

        todo.createTodo("My first task", deadline);

        TodoContractV1.Todo memory t = todo.getTodo(1);
        assertEq(t.id, 1);
        assertEq(t.owner, owner);
        assertEq(t.text, "My first task");
        assertEq(uint8(t.status), uint8(TodoContractV1.Status.Pending));
        assertEq(t.deadline, deadline);
    }

    function test_CreateTodo_RevertOnEmptyText() public {
        vm.expectRevert("Empty text");
        todo.createTodo("", block.timestamp + 1000);
    }

    function test_CreateTodo_RevertOnDeadlineTooSoon() public {
        vm.expectRevert("Deadline must be at least 10 mins away");
        todo.createTodo("Test", block.timestamp + 100);
    }

    function test_CreateTodo_RevertOnDeadlineExactlyAtBoundary() public {
        // deadline == block.timestamp + 600 should revert (must be strictly greater)
        vm.expectRevert("Deadline must be at least 10 mins away");
        todo.createTodo("Test", block.timestamp + 600);
    }

    function test_CreateTodo_IncrementsTodoCounter() public {
        uint256 deadline = block.timestamp + 1000;
        todo.createTodo("A", deadline);
        todo.createTodo("B", deadline);
        assertEq(todo.getTotalTodoCount(), 2);
    }

    // --- completeTodo ---

    function test_CompleteTodo_MarksAsDoneBeforeDeadline() public {
        uint256 deadline = block.timestamp + 1000;
        todo.createTodo("Task", deadline);

        todo.completeTodo(1);

        TodoContractV1.Todo memory t = todo.getTodo(1);
        assertEq(uint8(t.status), uint8(TodoContractV1.Status.Done));
    }

    function test_CompleteTodo_MarksAsDefaultedAfterDeadline() public {
        uint256 deadline = block.timestamp + 700;
        todo.createTodo("Task", deadline);

        vm.warp(deadline + 1);
        todo.completeTodo(1);

        TodoContractV1.Todo memory t = todo.getTodo(1);
        assertEq(uint8(t.status), uint8(TodoContractV1.Status.Defaulted));
    }

    function test_CompleteTodo_RevertIfNotOwner() public {
        todo.createTodo("Task", block.timestamp + 1000);

        vm.prank(addr1);
        vm.expectRevert("Not the owner");
        todo.completeTodo(1);
    }

    function test_CompleteTodo_RevertIfAlreadyFinalized() public {
        todo.createTodo("Task", block.timestamp + 1000);
        todo.completeTodo(1);

        vm.expectRevert("Todo is already finalized");
        todo.completeTodo(1);
    }

    function test_CompleteTodo_RevertOnInvalidId() public {
        vm.expectRevert("Todo does not exist");
        todo.completeTodo(0);

        vm.expectRevert("Todo does not exist");
        todo.completeTodo(999);
    }

    // --- getTodo ---

    function test_GetTodo_ReturnsCorrectData() public {
        uint256 deadline = block.timestamp + 1000;
        todo.createTodo("Hello", deadline);

        TodoContractV1.Todo memory t = todo.getTodo(1);
        assertEq(t.id, 1);
        assertEq(t.owner, owner);
        assertEq(t.text, "Hello");
        assertEq(t.deadline, deadline);
        assertEq(uint8(t.status), uint8(TodoContractV1.Status.Pending));
    }

    function test_GetTodo_RevertOnNonExistentId() public {
        vm.expectRevert("Todo does not exist");
        todo.getTodo(42);
    }

    // --- getMyTodoIds ---

    function test_GetMyTodoIds_ReturnsCorrectIds() public {
        uint256 deadline = block.timestamp + 1000;
        todo.createTodo("A", deadline);
        todo.createTodo("B", deadline);

        uint256[] memory ids = todo.getMyTodoIds();
        assertEq(ids.length, 2);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
    }

    // --- access control ---

    function test_Initialize_OwnerSetCorrectly() public view {
        assertEq(todo.owner(), owner);
    }

    function test_DoubleInit_Reverts() public {
        // Calling initialize again on the proxy should revert with InvalidInitialization
        vm.expectRevert();
        todo.initialize(addr1);
    }

    // =========================================================
    // 19.2 — Upgrade Path Tests
    // =========================================================

    function _deployAndPopulate()
        internal
        returns (address _proxy, TodoContractV1.Todo memory savedTodo)
    {
        address impl = address(new TodoContractV1());
        _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(TodoContractV1.initialize, (owner))
        );
        TodoContractV1 v1 = TodoContractV1(_proxy);

        uint256 deadline = block.timestamp + 1000;
        v1.createTodo("Pre-upgrade task", deadline);
        savedTodo = v1.getTodo(1);
    }

    function test_Upgrade_StatePreservedAfterUpgrade() public {
        (address _proxy, TodoContractV1.Todo memory before) = _deployAndPopulate();

        // Upgrade to V2
        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        // All pre-upgrade todo data must be identical
        TodoContractV1.Todo memory after_ = todoV2.getTodo(1);
        assertEq(after_.id, before.id);
        assertEq(after_.owner, before.owner);
        assertEq(after_.text, before.text);
        assertEq(uint8(after_.status), uint8(before.status));
        assertEq(after_.deadline, before.deadline);
    }

    function test_Upgrade_TotalCountPreserved() public {
        (address _proxy,) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        assertEq(todoV2.getTotalTodoCount(), 1);
    }

    function test_Upgrade_OwnerPreserved() public {
        (address _proxy,) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        assertEq(todoV2.owner(), owner);
    }

    // --- deleteTodo happy path ---

    function test_DeleteTodo_HappyPath() public {
        (address _proxy,) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        vm.expectEmit(true, true, false, false);
        emit TodoContractV1.TodoDeleted(1, owner);
        todoV2.deleteTodo(1);

        // After deletion, getTodo should revert with "Todo was deleted"
        vm.expectRevert("Todo was deleted");
        todoV2.getTodo(1);
    }

    function test_DeleteTodo_RemovesFromUserTodoIds() public {
        (address _proxy,) = _deployAndPopulate();

        // Add a second todo
        TodoContractV1 v1 = TodoContractV1(_proxy);
        v1.createTodo("Second task", block.timestamp + 1000);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        todoV2.deleteTodo(1);

        uint256[] memory ids = todoV2.getMyTodoIds();
        assertEq(ids.length, 1);
        assertEq(ids[0], 2);
    }

    // --- deleteTodo reverts ---

    function test_DeleteTodo_RevertIfNotOwner() public {
        (address _proxy,) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        vm.prank(addr1);
        vm.expectRevert("Not the owner");
        todoV2.deleteTodo(1);
    }

    function test_DeleteTodo_RevertIfNotPending() public {
        (address _proxy,) = _deployAndPopulate();

        // Complete the todo first
        TodoContractV1(_proxy).completeTodo(1);

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        vm.expectRevert("Todo is not pending");
        todoV2.deleteTodo(1);
    }

    function test_DeleteTodo_RevertIfNonExistentId() public {
        (address _proxy,) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        vm.expectRevert("Todo does not exist");
        todoV2.deleteTodo(999);
    }

    function test_DeleteTodo_RevertIfAlreadyDeleted() public {
        (address _proxy,) = _deployAndPopulate();

        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        todoV2.deleteTodo(1);

        vm.expectRevert("Todo was deleted");
        todoV2.deleteTodo(1);
    }

    // =========================================================
    // 19.3 — Fuzz Test: State Preservation After Upgrade
    // Feature: oz-upgradeable-v1-v2, Property 1: Todo State Preservation After Upgrade
    // =========================================================

    function test_fuzz_Todo_StatePreservedAfterUpgrade(
        string calldata text,
        uint256 deadline
    ) public {
        // Bound inputs to valid ranges
        vm.assume(bytes(text).length > 0);
        deadline = bound(deadline, block.timestamp + 601, type(uint128).max);

        // Deploy fresh V1 proxy
        address impl = address(new TodoContractV1());
        address _proxy = UnsafeUpgrades.deployUUPSProxy(
            impl,
            abi.encodeCall(TodoContractV1.initialize, (owner))
        );
        TodoContractV1 v1 = TodoContractV1(_proxy);

        // Create todo in V1
        uint256 id = v1.createTodo(text, deadline);
        TodoContractV1.Todo memory before = v1.getTodo(id);

        // Upgrade to V2
        UnsafeUpgrades.upgradeProxy(_proxy, address(new TodoContractV2()), "");
        TodoContractV2 todoV2 = TodoContractV2(_proxy);

        // Read back and assert all fields equal
        TodoContractV1.Todo memory after_ = todoV2.getTodo(id);
        assertEq(after_.id, before.id);
        assertEq(after_.owner, before.owner);
        assertEq(after_.text, before.text);
        assertEq(uint8(after_.status), uint8(before.status));
        assertEq(after_.deadline, before.deadline);
    }
}
