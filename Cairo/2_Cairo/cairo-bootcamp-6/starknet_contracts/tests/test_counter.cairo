use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, SyscallResultTrait};
use starknet_contracts::Counter::{CountDecreased, CountIncreased, CountReset, Event};
use starknet_contracts::{
    ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
    ICounterSafeDispatcherTrait,
};

// === Helpers
fn OWNER() -> ContractAddress {
    123_felt252.try_into().unwrap()
}

fn NOT_OWNER() -> ContractAddress {
    456_felt252.try_into().unwrap()
}

fn deploy_counter() -> (ICounterDispatcher, ICounterSafeDispatcher, ContractAddress) {
    let contract = declare("Counter").unwrap_syscall().contract_class();
    let mut calldata = array![OWNER().into()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap_syscall();
    (
        ICounterDispatcher { contract_address },
        ICounterSafeDispatcher { contract_address },
        contract_address,
    )
}

// === Deployment
#[test]
fn test_initial_state() {
    let (dispatcher, _, _) = deploy_counter();
    assert(dispatcher.get_count() == 0, 'Initial count should be 0');
    assert(dispatcher.get_owner() == OWNER(), 'Owner should match constructor');
}

// === Increase count
#[test]
fn test_increase_count() {
    let (dispatcher, _, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(5);
    assert(dispatcher.get_count() == 5, 'Count should be 5');
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_increase_count_accumulates() {
    let (dispatcher, _, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(3);
    dispatcher.increase_count(7);
    assert(dispatcher.get_count() == 10, 'Count should be 10');
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_increase_count_zero_amount_fails() {
    let (_, safe_dispatcher, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    match safe_dispatcher.increase_count(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Amount cannot be 0', 'Wrong error message');
        },
    }
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_increase_count_not_owner_fails() {
    let (_, safe_dispatcher, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, NOT_OWNER());
    match safe_dispatcher.increase_count(5) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is not owner', 'Wrong error message');
        },
    }
    stop_cheat_caller_address(contract_address);
}

// === Decrease count
#[test]
fn test_decrease_count() {
    let (dispatcher, _, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(10);
    dispatcher.decrease_count(4);
    assert(dispatcher.get_count() == 6, 'Count should be 6');
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_decrease_count_zero_amount_fails() {
    let (_, safe_dispatcher, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    match safe_dispatcher.decrease_count(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Amount cannot be 0', 'Wrong error message');
        },
    }
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_decrease_count_exceeds_fails() {
    let (dispatcher, safe_dispatcher, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(3);
    match safe_dispatcher.decrease_count(10) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Amount exceeds count', 'Wrong error message');
        },
    }
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_decrease_count_not_owner_fails() {
    let (_, safe_dispatcher, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, NOT_OWNER());
    match safe_dispatcher.decrease_count(5) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is not owner', 'Wrong error message');
        },
    }
    stop_cheat_caller_address(contract_address);
}

// === Reset count
#[test]
fn test_reset_count() {
    let (dispatcher, _, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(20);
    dispatcher.reset_count();
    assert(dispatcher.get_count() == 0, 'Count should be 0 after reset');
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_reset_count_not_owner_fails() {
    let (_, safe_dispatcher, contract_address) = deploy_counter();
    start_cheat_caller_address(contract_address, NOT_OWNER());
    match safe_dispatcher.reset_count() {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is not owner', 'Wrong error message');
        },
    }
    stop_cheat_caller_address(contract_address);
}

// === Events
#[test]
fn test_increase_count_emits_event() {
    let (dispatcher, _, contract_address) = deploy_counter();
    let mut spy = spy_events();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(5);
    stop_cheat_caller_address(contract_address);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::CountIncreased(CountIncreased { amount: 5, new_count: 5 }),
                ),
            ],
        );
}

#[test]
fn test_decrease_count_emits_event() {
    let (dispatcher, _, contract_address) = deploy_counter();
    let mut spy = spy_events();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(10);
    dispatcher.decrease_count(3);
    stop_cheat_caller_address(contract_address);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::CountDecreased(CountDecreased { amount: 3, new_count: 7 }),
                ),
            ],
        );
}

#[test]
fn test_reset_count_emits_event() {
    let (dispatcher, _, contract_address) = deploy_counter();
    let mut spy = spy_events();
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.increase_count(8);
    dispatcher.reset_count();
    stop_cheat_caller_address(contract_address);

    spy
        .assert_emitted(
            @array![(contract_address, Event::CountReset(CountReset { previous_count: 8 }))],
        );
}
 